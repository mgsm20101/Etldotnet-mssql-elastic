# ETL .NET Service

A comprehensive ETL (Extract, Transform, Load) service built with .NET that synchronizes data from SQL Server to Elasticsearch. This project provides a configurable, task-based approach to data synchronization with support for incremental updates.

## Project Overview

This ETL service is designed to extract data from SQL Server databases and load it into Elasticsearch indices. It supports:

- Multiple configurable ETL tasks
- Incremental data synchronization
- Scheduled execution using cron expressions
- Detailed logging
- State tracking for reliable data processing

## Prerequisites

- [Docker](https://www.docker.com/products/docker-desktop/) and Docker Compose
- [.NET 6.0 SDK](https://dotnet.microsoft.com/download/dotnet/6.0) or later (for development only)
- PowerShell or Bash shell

## Project Structure

```
├── tasks/                      # ETL task configuration files
│   ├── customers-sync.yml      # Customer synchronization task
│   └── orders-sync.yml         # Orders synchronization task
├── logs/                       # Log files directory
├── state/                      # State tracking files
├── appsettings.json            # Application settings
├── appsettings.yml             # YAML application settings
├── database-setup.sql          # SQL script for database setup
├── docker-compose.yml          # Main Docker Compose file
├── docker-compose.db.yml       # Database services Docker Compose file
├── docker-compose.override.yml # Docker Compose override file
├── Dockerfile                  # Dockerfile for the ETL service
├── EtlConfig.cs                # ETL configuration class
├── Program.cs                  # Application entry point
├── Worker.cs                   # Main worker service
├── init-db.sh                  # Database initialization script
└── start-system.ps1            # PowerShell script to start the system
```

## Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd EtlDotnet
```

### 2. Start the System

On Windows, use PowerShell:

```powershell
.\start-system.ps1
```

On Linux/macOS, use Bash:

```bash
# Start the containers
docker-compose up -d

# Initialize the database and Elasticsearch indices
bash ./init-db.sh
```

### 3. Access the Services

- **SQL Server**: localhost:1433
  - Username: sa
  - Password: Passw0rd
- **Elasticsearch**: http://localhost:9200
- **Kibana**: http://localhost:5601
- **Adminer** (SQL Server Management): http://localhost:8080

## Configuring ETL Tasks

ETL tasks are configured using YAML files in the `tasks` directory. Each task file defines:

- SQL connection string
- SQL query for data extraction
- Elasticsearch connection details
- Tracking column for incremental updates
- Scheduling via cron expressions

### Example Task Configuration

```yaml
taskName: CustomersSync
sqlConnectionString: "Server=.;Database=testDb;User Id=sa;Password=Passw0rd;TrustServerCertificate=True"
query: |
  SELECT [fID]
  ,[fName]
  ,[fNameA]
  ,[fAddress]
  ,[fTelephone]
  ,[fBirthDate]
  ,[fBagNo]
  ,[fEmpCode]
  ,[fMemberNo]
  ,[UIG_ID]
  ,[CustomerType]
  ,[LastVisitDate]
  ,[Gifts]
  FROM [dbo].[tblCustomers]
  where LastVisitDate >@LastRunTime

elasticsearchUrl: "http://localhost:9200"
indexName: customers
trackingColumnName: LastVisitDate
defaultTrackingValue: "2000-01-01 00:00:00"
trackingValueType: DateTime
idColumnName: fID
cronExpression: "* * * * *"
batchSize: 1000
isEnabled: true
logFile: "logs/customers/customers-sync-.log"
stateFile: "state/customers-sync.json"
```

## Database Setup

The project includes a SQL script (`database-setup.sql`) that creates the necessary database schema and populates it with sample data. This script is automatically executed when you start the system using the provided scripts.

## Adding New ETL Tasks

To add a new ETL task:

1. Create a new YAML file in the `tasks` directory
2. Configure the task parameters (connection strings, query, etc.)
3. Set `isEnabled: true` to activate the task
4. Restart the ETL service

## Monitoring and Logs

- **ETL Service Logs**: Available in the `logs` directory
- **Elasticsearch Data**: View using Kibana at http://localhost:5601
- **SQL Server Data**: View using Adminer at http://localhost:8080

## Development

### Building the Service

```bash
dotnet build
```

### Running the Service Locally

```bash
dotnet run
```

### Building the Docker Image

```bash
docker build -t etl-service .
```

## Architecture

The ETL service follows a worker service pattern:

1. **Task Configuration**: YAML files define ETL tasks
2. **Worker Service**: Executes tasks according to their schedule
3. **State Tracking**: Maintains the last successful run time for incremental updates
4. **Logging**: Detailed logs for monitoring and troubleshooting

## Troubleshooting

### Common Issues

1. **Connection Issues**:
   - Verify SQL Server and Elasticsearch are running
   - Check connection strings in task configuration files

2. **No Data Synchronized**:
   - Check if data matches the incremental update condition
   - Verify the tracking column and value

3. **Service Not Starting**:
   - Check logs for error messages
   - Verify Docker containers are running

## License

[MIT License](LICENSE)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
