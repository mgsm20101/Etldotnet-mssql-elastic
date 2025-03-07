using Serilog;
using EtlDotnet;
using System.Globalization;
using Microsoft.Extensions.Options;
using System.IO;

// Set culture to invariant
CultureInfo.DefaultThreadCurrentCulture = CultureInfo.InvariantCulture;
CultureInfo.DefaultThreadCurrentUICulture = CultureInfo.InvariantCulture;

Log.Logger = new LoggerConfiguration()
    .WriteTo.Console()
    .WriteTo.File("logs/service-.log",
        rollingInterval: RollingInterval.Day,
        shared: true,
        outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff} [{Level:u3}] {SourceContext} {Message:lj}{NewLine}{Exception}")
    .WriteTo.File("logs/error-.log",
        rollingInterval: RollingInterval.Day,
        shared: true,
        restrictedToMinimumLevel: Serilog.Events.LogEventLevel.Error,
        outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff} [{Level:u3}] {SourceContext} {Message:lj}{NewLine}{Exception}")
    .CreateLogger();

try
{
    var builder = Host.CreateDefaultBuilder(args)
        .ConfigureAppConfiguration((hostingContext, config) =>
        {
            config.SetBasePath(Directory.GetCurrentDirectory())
                  .AddYamlFile("appsettings.yml", optional: false, reloadOnChange: true)
                  .AddYamlFile($"appsettings.{hostingContext.HostingEnvironment.EnvironmentName}.yml", optional: true, reloadOnChange: true)
                  .AddEnvironmentVariables();
        })
        .UseSerilog()
        .ConfigureServices((hostContext, services) =>
        {
            // Configure base ETL settings
            services.Configure<EtlConfig>(hostContext.Configuration.GetSection("EtlConfig"));

            // Add post-configure to load tasks from directory
            services.PostConfigure<EtlConfig>(config =>
            {
                var tasksDirectory = Path.Combine(Directory.GetCurrentDirectory(), "tasks");
                if (Directory.Exists(tasksDirectory))
                {
                    config.LoadTasksFromDirectory(tasksDirectory);
                    Log.Information("Loaded {TaskCount} tasks from directory: {Directory}", 
                        config.Tasks.Count, tasksDirectory);
                }
            });

            services.AddHostedService<Worker>();
        });

    Log.Information("Starting ETL Service");
    var host = builder.Build();
    await host.RunAsync();
}
catch (Exception ex)
{
    Log.Fatal(ex, "ETL Service terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}
