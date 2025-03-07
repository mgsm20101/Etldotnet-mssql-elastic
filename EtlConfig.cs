using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using YamlDotNet.Serialization;
using YamlDotNet.Serialization.NamingConventions;

namespace EtlDotnet
{
    public class TaskStatus
    {
        public string TaskName { get; set; }
        public bool IsRunning { get; set; }
        public DateTime LastRunTime { get; set; }
        public DateTime LastSuccessTime { get; set; }
        public int SuccessCount { get; set; }
        public int ErrorCount { get; set; }
        public string LastError { get; set; }
        public int ProcessedRecords { get; set; }
        public string LastProcessedValue { get; set; }
    }

    public class ServiceStatus
    {
        public bool IsHealthy { get; set; }
        public DateTime LastUpdateTime { get; set; }
        public List<TaskStatus> Tasks { get; set; } = new();
    }

    public class TaskConfig
    {
        public string TaskName { get; set; }
        public string SqlConnectionString { get; set; }
        public string Query { get; set; }
        public string ElasticsearchUrl { get; set; }
        public string IndexName { get; set; }
        public string TrackingColumnName { get; set; }
        public string DefaultTrackingValue { get; set; }
        public string TrackingValueType { get; set; } = "DateTime"; // Can be: DateTime, Int, Long, String
        public string IdColumnName { get; set; }
        public string CronExpression { get; set; }
        public int BatchSize { get; set; } = 1000;
        public bool IsEnabled { get; set; } = true;
        public string LogFile { get; set; }
        public string StateFile { get; set; }
    }

    public class EtlConfig
    {
        public List<TaskConfig> Tasks { get; set; } = new();
        public int RetryAttempts { get; set; } = 3;
        public TimeSpan RetryDelay { get; set; } = TimeSpan.FromSeconds(30);
        public TimeSpan HealthCheckInterval { get; set; } = TimeSpan.FromMinutes(1);
        public string ServiceStatusFile { get; set; }

        public void LoadTasksFromDirectory(string tasksDirectory)
        {
            if (!Directory.Exists(tasksDirectory))
            {
                throw new DirectoryNotFoundException($"Tasks directory not found: {tasksDirectory}");
            }

            var deserializer = new DeserializerBuilder()
                .WithNamingConvention(CamelCaseNamingConvention.Instance)
                .Build();

            var taskFiles = Directory.GetFiles(tasksDirectory, "*.yml", SearchOption.AllDirectories);
            
            Tasks.Clear();
            foreach (var file in taskFiles)
            {
                try
                {
                    var yaml = File.ReadAllText(file);
                    var task = deserializer.Deserialize<TaskConfig>(yaml);
                    
                    // Use filename as TaskName if not specified
                    if (string.IsNullOrEmpty(task.TaskName))
                    {
                        task.TaskName = Path.GetFileNameWithoutExtension(file);
                    }
                    
                    Tasks.Add(task);
                }
                catch (Exception ex)
                {
                    throw new Exception($"Error loading task from file {file}: {ex.Message}", ex);
                }
            }
        }
    }
}
