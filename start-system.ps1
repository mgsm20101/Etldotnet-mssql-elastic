# سكريبت PowerShell لتشغيل النظام على Windows

Write-Host "جاري إنشاء هيكل المجلدات..." -ForegroundColor Cyan

# إنشاء مجلدات السجلات
New-Item -ItemType Directory -Force -Path logs\customers | Out-Null
New-Item -ItemType Directory -Force -Path logs\orders | Out-Null

# إنشاء مجلد الحالة
New-Item -ItemType Directory -Force -Path state | Out-Null

# إنشاء مجلدات البيانات
New-Item -ItemType Directory -Force -Path data\sqlserver | Out-Null
New-Item -ItemType Directory -Force -Path data\elasticsearch | Out-Null

Write-Host "جاري تشغيل الحاويات..." -ForegroundColor Cyan

# تشغيل الحاويات
docker-compose up -d

Write-Host "جاري الانتظار حتى تكون قاعدة البيانات جاهزة..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

Write-Host "جاري تنفيذ سكريبت قاعدة البيانات..." -ForegroundColor Yellow

# تنفيذ سكريبت SQL داخل حاوية SQL Server
docker exec -i sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P Passw0rd -i /scripts/database-setup.sql

Write-Host "تم تهيئة قاعدة البيانات بنجاح!" -ForegroundColor Green

# إنشاء مؤشرات Elasticsearch
Write-Host "جاري إنشاء مؤشرات Elasticsearch..." -ForegroundColor Yellow

# إنشاء مؤشر العملاء
Invoke-RestMethod -Method PUT -Uri "http://localhost:9200/customers" -ContentType "application/json" -Body @"
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
}
"@

# إنشاء مؤشر الطلبات
Invoke-RestMethod -Method PUT -Uri "http://localhost:9200/orders" -ContentType "application/json" -Body @"
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
}
"@

Write-Host "تم إنشاء مؤشرات Elasticsearch بنجاح!" -ForegroundColor Green

# عرض روابط الوصول للخدمات
Write-Host "
النظام جاهز للاستخدام!" -ForegroundColor Green
Write-Host "
يمكنك الوصول إلى الخدمات على الروابط التالية:" -ForegroundColor Cyan
Write-Host "- SQL Server: localhost:1433" -ForegroundColor White
Write-Host "- Elasticsearch: http://localhost:9200" -ForegroundColor White
Write-Host "- Kibana: http://localhost:5601" -ForegroundColor White
Write-Host "- Adminer (إدارة SQL Server): http://localhost:8080" -ForegroundColor White
Write-Host "- ETL Service: يعمل في الخلفية" -ForegroundColor White
