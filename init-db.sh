#!/bin/bash

# u0633u0643u0631u064au0628u062a u0644u062au0647u064au0626u0629 u0642u0627u0639u062fu0629 u0627u0644u0628u064au0627u0646u0627u062a SQL Server u0628u0639u062f u062au0634u063au064au0644 u0627u0644u062du0627u0648u064au0627u062a

echo "u062cu0627u0631u064a u0627u0644u0627u0646u062au0638u0627u0631 u062du062au0649 u062au0643u0648u0646 u0642u0627u0639u062fu0629 u0627u0644u0628u064au0627u0646u0627u062a u062cu0627u0647u0632u0629..."
sleep 15

echo "u062cu0627u0631u064a u062au0646u0641u064au0630 u0633u0643u0631u064au0628u062a u0642u0627u0639u062fu0629 u0627u0644u0628u064au0627u0646u0627u062a..."

# u062au0646u0641u064au0630 u0633u0643u0631u064au0628u062a SQL u062fu0627u062eu0644 u062du0627u0648u064au0629 SQL Server
docker exec -i sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P Passw0rd -i /docker-entrypoint-initdb.d/database-setup.sql

echo "u062au0645 u062au0647u064au0626u0629 u0642u0627u0639u062fu0629 u0627u0644u0628u064au0627u0646u0627u062a u0628u0646u062cu0627u062d!"

# u0625u0646u0634u0627u0621 u0645u0624u0634u0631u0627u062a Elasticsearch
echo "u062cu0627u0631u064a u0625u0646u0634u0627u0621 u0645u0624u0634u0631u0627u062a Elasticsearch..."

# u0625u0646u0634u0627u0621 u0645u0624u0634u0631 u0627u0644u0639u0645u0644u0627u0621
curl -X PUT "http://localhost:9200/customers" -H "Content-Type: application/json" -d'
{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0
  },
  "mappings": {
    "properties": {
      "fID": { "type": "integer" },
      "fName": { "type": "text" },
      "fNameA": { "type": "text" },
      "fAddress": { "type": "text" },
      "fTelephone": { "type": "keyword" },
      "fBirthDate": { "type": "date" },
      "fBagNo": { "type": "keyword" },
      "fEmpCode": { "type": "keyword" },
      "fMemberNo": { "type": "keyword" },
      "UIG_ID": { "type": "integer" },
      "CustomerType": { "type": "integer" },
      "LastVisitDate": { "type": "date" },
      "Gifts": { "type": "integer" }
    }
  }
}'

# u0625u0646u0634u0627u0621 u0645u0624u0634u0631 u0627u0644u0637u0644u0628u0627u062a
curl -X PUT "http://localhost:9200/orders" -H "Content-Type: application/json" -d'
{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0
  },
  "mappings": {
    "properties": {
      "fID": { "type": "integer" },
      "fStoreIN": { "type": "integer" },
      "fSubStoreIN": { "type": "integer" },
      "fCustID": { "type": "integer" },
      "fStoreOut": { "type": "integer" },
      "fSubStoreOut": { "type": "integer" },
      "fDate": { "type": "date" },
      "fDesc": { "type": "text" },
      "fPosted": { "type": "boolean" },
      "fType": { "type": "integer" },
      "fSupID": { "type": "integer" },
      "fUserID": { "type": "integer" },
      "CostCenterID": { "type": "integer" },
      "ValidUntil": { "type": "date" },
      "StatusID": { "type": "integer" },
      "SubType": { "type": "integer" },
      "PostedDate": { "type": "date" },
      "PostedUser": { "type": "integer" },
      "RequestedDeliveryDate": { "type": "date" },
      "ManualSalesOrderNo": { "type": "keyword" }
    }
  }
}'

echo "u062au0645 u0625u0646u0634u0627u0621 u0645u0624u0634u0631u0627u062a Elasticsearch u0628u0646u062cu0627u062d!"
echo "u0627u0644u0646u0638u0627u0645 u062cu0627u0647u0632 u0644u0644u0627u0633u062au062eu062fu0627u0645!"
