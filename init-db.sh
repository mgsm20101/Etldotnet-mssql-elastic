#!/bin/bash

# سكريبت لتهيئة قاعدة البيانات SQL Server بعد تشغيل الحاويات

# إنشاء هيكل المجلدات
echo "جاري إنشاء هيكل المجلدات..."
mkdir -p logs/customers logs/orders state data/sqlserver data/elasticsearch

echo "جاري الانتظار حتى تكون قاعدة البيانات جاهزة..."
sleep 15

echo "جاري تنفيذ سكريبت قاعدة البيانات..."

# تنفيذ سكريبت SQL داخل حاوية SQL Server
docker exec -i sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P Passw0rd -i /scripts/database-setup.sql

echo "تم تهيئة قاعدة البيانات بنجاح!"

# إنشاء مؤشرات Elasticsearch
echo "جاري إنشاء مؤشرات Elasticsearch..."

# إنشاء مؤشر العملاء
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

# إنشاء مؤشر الطلبات
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

echo "تم إنشاء مؤشرات Elasticsearch بنجاح!"
echo "النظام جاهز للاستخدام!"
