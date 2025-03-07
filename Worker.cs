using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Options;
using System.Collections.Concurrent;
using System.Globalization;
using System.Text.Json;
using Serilog;
using Serilog.Core;
using Nest;
using CronScheduler = Cronos;

namespace EtlDotnet
{
    public class Worker : BackgroundService
    {
        private readonly ILogger<Worker> _logger;
        private readonly EtlConfig _config;
        private readonly ConcurrentDictionary<string, ElasticClient> _elasticClients = new();
        private readonly ConcurrentDictionary<string, CronScheduler.CronExpression> _cronExpressions = new();
        private readonly ConcurrentDictionary<string, string> _lastTrackingValues = new();
        private readonly ConcurrentDictionary<string, Logger> _taskLoggers = new();
        private readonly ServiceStatus _serviceStatus = new();
        private readonly ConcurrentDictionary<string, TaskStatus> _taskStatuses = new();
        private Timer _healthCheckTimer;

        public Worker(ILogger<Worker> logger, IOptions<EtlConfig> config)
        {
            _logger = logger;
            _config = config.Value;
            
            foreach (var task in _config.Tasks)
            {
                if (!task.IsEnabled) continue;
                
                var settings = new ConnectionSettings(new Uri(task.ElasticsearchUrl))
                    .DefaultIndex(task.IndexName);
                _elasticClients[task.TaskName] = new ElasticClient(settings);
                _cronExpressions[task.TaskName] = CronScheduler.CronExpression.Parse(task.CronExpression);

                // Load last tracking value from state file or use default
                _lastTrackingValues[task.TaskName] = LoadTaskState(task);

                // Create task-specific logger
                var taskLogger = new LoggerConfiguration()
                    .WriteTo.File(task.LogFile,
                        rollingInterval: RollingInterval.Day,
                        shared: true,
                        outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff} [{Level:u3}] {TaskName} {Message:lj}{NewLine}{Exception}")
                    .Enrich.WithProperty("TaskName", task.TaskName)
                    .CreateLogger();
                
                _taskLoggers[task.TaskName] = taskLogger;

                // Initialize task status
                _taskStatuses[task.TaskName] = new TaskStatus
                {
                    TaskName = task.TaskName,
                    IsRunning = false,
                    LastRunTime = DateTime.MinValue,
                    LastSuccessTime = DateTime.MinValue,
                    SuccessCount = 0,
                    ErrorCount = 0,
                    ProcessedRecords = 0,
                    LastProcessedValue = _lastTrackingValues[task.TaskName]
                };
            }

            // Initialize service status
            _serviceStatus.IsHealthy = true;
            _serviceStatus.LastUpdateTime = DateTime.UtcNow;
            _serviceStatus.Tasks = _taskStatuses.Values.ToList();
        }

        private string LoadTaskState(TaskConfig task)
        {
            var stateDir = Path.Combine(Directory.GetCurrentDirectory(), "state");
            Directory.CreateDirectory(stateDir); // Ensure directory exists
            
            var stateFile = Path.Combine(stateDir, $"{task.TaskName.ToLower()}.json");
            if (!File.Exists(stateFile))
            {
                return task.DefaultTrackingValue;
            }

            try
            {
                var state = JsonSerializer.Deserialize<JsonElement>(File.ReadAllText(stateFile));
                return state.GetProperty("LastValue").GetString() ?? task.DefaultTrackingValue;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to load state for task {TaskName}, using default value", task.TaskName);
                return task.DefaultTrackingValue;
            }
        }

        private void SaveTaskState(TaskConfig task, string lastValue)
        {
            var stateDir = Path.Combine(Directory.GetCurrentDirectory(), "state");
            Directory.CreateDirectory(stateDir); // Ensure directory exists
            
            var stateFile = Path.Combine(stateDir, $"{task.TaskName.ToLower()}.json");
            var state = new { LastValue = lastValue };
            File.WriteAllText(stateFile, JsonSerializer.Serialize(state));
        }

        private object ConvertTrackingValue(string value, string type)
        {
            return type switch
            {
                "DateTime" => DateTime.Parse(value, CultureInfo.InvariantCulture),
                "Int" => int.Parse(value, CultureInfo.InvariantCulture),
                "Long" => long.Parse(value, CultureInfo.InvariantCulture),
                _ => value
            };
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            var tasks = _config.Tasks.Where(t => t.IsEnabled).ToList();
            if (!tasks.Any())
            {
                _logger.LogWarning("No enabled tasks found in configuration");
                return;
            }

            _healthCheckTimer = new Timer(UpdateServiceStatus, null, TimeSpan.Zero, _config.HealthCheckInterval);

            await Task.WhenAll(tasks.Select(task => 
                RunTaskAsync(task, stoppingToken)));
        }

        private async Task RunTaskAsync(TaskConfig taskConfig, CancellationToken stoppingToken)
        {
            var taskStatus = _taskStatuses[taskConfig.TaskName];
            var taskLogger = _taskLoggers[taskConfig.TaskName];

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    taskStatus.IsRunning = true;
                    taskStatus.LastRunTime = DateTime.UtcNow;

                    taskLogger.Information("Starting task execution. Last tracking value: {LastValue}", 
                        _lastTrackingValues[taskConfig.TaskName]);
                    
                    await ProcessTaskDataAsync(taskConfig, _lastTrackingValues[taskConfig.TaskName], stoppingToken);
                    
                    taskStatus.LastSuccessTime = DateTime.UtcNow;
                    taskStatus.SuccessCount++;
                    taskLogger.Information("Task completed successfully");

                    if (_cronExpressions.TryGetValue(taskConfig.TaskName, out var cronExpression))
                    {
                        var nextRun = cronExpression.GetNextOccurrence(DateTime.UtcNow);
                        if (nextRun.HasValue)
                        {
                            var delay = nextRun.Value - DateTime.UtcNow;
                            if (delay > TimeSpan.Zero)
                            {
                                taskLogger.Information("Next run scheduled for: {NextRun}", nextRun.Value);
                                await Task.Delay(delay, stoppingToken);
                            }
                        }
                    }
                }
                catch (Exception ex)
                {
                    taskStatus.ErrorCount++;
                    taskStatus.LastError = ex.Message;
                    taskLogger.Error(ex, "Error occurred while processing task");
                    await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
                }
                finally
                {
                    taskStatus.IsRunning = false;
                }
            }
        }

        private async Task ProcessTaskDataAsync(TaskConfig taskConfig, string lastValue, CancellationToken stoppingToken)
        {
            var taskLogger = _taskLoggers[taskConfig.TaskName];
            var taskStatus = _taskStatuses[taskConfig.TaskName];
            var client = _elasticClients[taskConfig.TaskName];
            lastValue = LoadTaskState(taskConfig);

            using var connection = new SqlConnection(taskConfig.SqlConnectionString);
            await connection.OpenAsync(stoppingToken);

            var paramValue = ConvertTrackingValue(lastValue, taskConfig.TrackingValueType);
            var command = new SqlCommand(taskConfig.Query, connection);
            command.Parameters.AddWithValue("@LastRunTime", paramValue);

            using var reader = await command.ExecuteReaderAsync(stoppingToken);
            var documents = new List<(string Id, Dictionary<string, object> Document, string TrackingValue)>();
            string lastProcessedValue = lastValue;

            // First, collect all records
            while (await reader.ReadAsync(stoppingToken))
            {
                try
                {
                    var document = new Dictionary<string, object>();
                    for (int i = 0; i < reader.FieldCount; i++)
                    {
                        var value = reader.GetValue(i);
                        document[reader.GetName(i)] = value == DBNull.Value ? null : value;
                    }

                    var currentTrackingValue = reader[taskConfig.TrackingColumnName] != DBNull.Value 
                        ? reader[taskConfig.TrackingColumnName].ToString() 
                        : lastProcessedValue;

                    var id = reader[taskConfig.IdColumnName].ToString();
                    documents.Add((id, document, currentTrackingValue));
                    lastProcessedValue = currentTrackingValue;
                }
                catch (Exception ex)
                {
                    taskLogger.Error(ex, "Error processing record");
                    taskStatus.ErrorCount++;
                }
            }

            // Then process in batches
            for (int i = 0; i < documents.Count; i += taskConfig.BatchSize)
            {
                var batch = documents.Skip(i).Take(taskConfig.BatchSize).ToList();
                var bulkDescriptor = new BulkDescriptor();

                foreach (var (id, document, _) in batch)
                {
                    bulkDescriptor.Index<object>(op => op
                        .Document(document)
                        .Id(id)
                        .Index(taskConfig.IndexName));
                }

                try
                {
                    var bulkResponse = await client.BulkAsync(bulkDescriptor, stoppingToken);
                    if (bulkResponse.ApiCall.Success)
                    {
                        taskStatus.ProcessedRecords += batch.Count;
                        taskLogger.Information("Processed batch of {RecordCount} records. Total processed: {TotalProcessed}", 
                            batch.Count, taskStatus.ProcessedRecords);
                        
                        // Update state with the last tracking value from this batch
                        var batchLastValue = batch.Last().TrackingValue;
                        SaveTaskState(taskConfig, batchLastValue);
                    }
                    else
                    {
                        taskLogger.Error("Bulk insert failed for batch: {ErrorReason}", 
                            bulkResponse.ServerError?.Error?.Reason);
                        taskStatus.ErrorCount++;
                    }
                }
                catch (Exception ex)
                {
                    taskLogger.Error(ex, "Error processing bulk insert for batch");
                    taskStatus.ErrorCount++;
                }
            }

            // Final update of state with the last processed value
            if (documents.Any())
            {
                SaveTaskState(taskConfig, lastProcessedValue);
                taskLogger.Information("Completed processing {TotalRecords} records. Final tracking value: {TrackingValue}", 
                    documents.Count, lastProcessedValue);
            }
            else
            {
                taskLogger.Information("No new records to process. Current tracking value: {TrackingValue}", 
                    lastValue);
            }
        }

        private void UpdateServiceStatus(object state)
        {
            try
            {
                _serviceStatus.LastUpdateTime = DateTime.UtcNow;
                _serviceStatus.Tasks = _taskStatuses.Values.ToList();

                var unhealthyTasks = _taskStatuses.Values
                    .Where(t => (DateTime.UtcNow - t.LastRunTime) > TimeSpan.FromHours(1))
                    .ToList();

                _serviceStatus.IsHealthy = !unhealthyTasks.Any();

                var json = JsonSerializer.Serialize(_serviceStatus, new JsonSerializerOptions 
                { 
                    WriteIndented = true 
                });
                File.WriteAllText(_config.ServiceStatusFile, json);

                if (unhealthyTasks.Any())
                {
                    _logger.LogWarning("Unhealthy tasks detected: {Tasks}", 
                        string.Join(", ", unhealthyTasks.Select(t => t.TaskName)));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating service status");
            }
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _healthCheckTimer?.Dispose();
            await base.StopAsync(cancellationToken);
        }
    }
}
