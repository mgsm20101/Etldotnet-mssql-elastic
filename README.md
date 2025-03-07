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

## Environment Setup

### 1. Setting Up the Database Environment

This project uses Docker to create a complete development environment including SQL Server, Elasticsearch, and management tools.

#### Database Components

1. **SQL Server**: Source database for ETL operations
   - Container name: `sqlserver`
   - Version: SQL Server 2022 Express
   - Credentials: Username `sa`, Password `Passw0rd`
   - Port: 1433
   - Database name: `testDb`

2. **Elasticsearch**: Target for indexed data
   - Container name: `elasticsearch`
   - Version: 7.17.10
   - Port: 9200
   - Configured as a single-node cluster

3. **Kibana**: Web interface for Elasticsearch
   - Container name: `kibana`
   - Version: 7.17.10
   - Port: 5601
   - Access URL: http://localhost:5601

4. **Adminer**: Web-based SQL Server management tool
   - Container name: `adminer`
   - Port: 8080
   - Access URL: http://localhost:8080
   - Default server: `sqlserver`

#### Database Initialization

The project includes a SQL script (`database-setup.sql`) that automatically:

1. Creates the `testDb` database
2. Creates the necessary tables:
   - `tblCustomers`: Customer information table
   - `tblOrders`: Order information table
3. Populates these tables with sample data

The initialization scripts (`init-db.sh` for Linux/macOS and `start-system.ps1` for Windows) handle:

1. Starting all Docker containers
2. Executing the SQL initialization script
3. Creating Elasticsearch indices with proper mappings

### 2. Directory Structure Setup

Before starting, ensure these directories exist:

```bash
# On Linux/macOS
mkdir -p logs/customers logs/orders state

# On Windows (PowerShell)
New-Item -ItemType Directory -Force -Path logs\customers, logs\orders, state
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

### 4. Verify Database Setup

1. Open Adminer at http://localhost:8080
2. Login with:
   - System: MS SQL
   - Server: sqlserver
   - Username: sa
   - Password: Passw0rd
   - Database: testDb
3. Verify that tables `tblCustomers` and `tblOrders` exist and contain sample data

### 5. Verify Elasticsearch Setup

1. Open Kibana at http://localhost:5601
2. Navigate to Dev Tools
3. Run this query to verify indices:
   ```
   GET _cat/indices?v
   ```
4. Check index mappings:
   ```
   GET customers/_mapping
   GET orders/_mapping
   ```

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

## Database Management

### Using Adminer

Adminer provides a web interface for managing the SQL Server database:

1. **Viewing Tables**: Click on a table name to see its structure and data
2. **Running Queries**: Use the SQL command interface to execute custom queries
3. **Exporting Data**: Export data in various formats (CSV, SQL, etc.)
4. **Modifying Schema**: Add or modify tables, columns, and indexes

### Using Kibana

Kibana allows you to interact with Elasticsearch data:

1. **Discover**: Browse and search through indexed data
2. **Visualize**: Create charts and graphs based on your data
3. **Dev Tools**: Execute Elasticsearch queries directly
4. **Index Management**: Monitor index health and statistics

### Modifying Sample Data

To modify the sample data:

1. Edit the `database-setup.sql` file
2. Restart the containers or run the initialization script again

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
   - Ensure ports are not blocked by firewall

2. **No Data Synchronized**:
   - Check if data matches the incremental update condition
   - Verify the tracking column and value
   - Check SQL query for syntax errors

3. **Service Not Starting**:
   - Check logs for error messages
   - Verify Docker containers are running
   - Ensure required directories exist

4. **Database Initialization Fails**:
   - Check SQL Server container logs: `docker logs sqlserver`
   - Verify SQL script syntax in `database-setup.sql`
   - Ensure SQL Server has started before running initialization

## License

[MIT License](LICENSE)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
