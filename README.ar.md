# خدمة ETL .NET

خدمة شاملة للاستخراج والتحويل والتحميل (ETL) مبنية بـ .NET تقوم بمزامنة البيانات من SQL Server إلى Elasticsearch. يوفر هذا المشروع نهجًا قابلًا للتكوين قائمًا على المهام لمزامنة البيانات مع دعم التحديثات التدريجية.

## نظرة عامة على المشروع

تم تصميم خدمة ETL هذه لاستخراج البيانات من قواعد بيانات SQL Server وتحميلها في فهارس Elasticsearch. وهي تدعم:

- مهام ETL متعددة قابلة للتكوين
- مزامنة البيانات التدريجية
- التنفيذ المجدول باستخدام تعبيرات cron
- تسجيل مفصل
- تتبع الحالة لمعالجة البيانات الموثوقة

## المتطلبات الأساسية

- [Docker](https://www.docker.com/products/docker-desktop/) و Docker Compose
- [.NET 6.0 SDK](https://dotnet.microsoft.com/download/dotnet/6.0) أو أحدث (للتطوير فقط)
- PowerShell أو Bash shell

## هيكل المشروع

```
├── tasks/                      # ملفات تكوين مهام ETL
│   ├── customers-sync.yml      # مهمة مزامنة العملاء
│   └── orders-sync.yml         # مهمة مزامنة الطلبات
├── logs/                       # دليل ملفات السجل
├── state/                      # ملفات تتبع الحالة
├── appsettings.json            # إعدادات التطبيق
├── appsettings.yml             # إعدادات التطبيق بصيغة YAML
├── database-setup.sql          # نص SQL لإعداد قاعدة البيانات
├── docker-compose.yml          # ملف Docker Compose الرئيسي
├── docker-compose.db.yml       # ملف Docker Compose لخدمات قاعدة البيانات
├── docker-compose.override.yml # ملف تجاوز Docker Compose
├── Dockerfile                  # Dockerfile لخدمة ETL
├── EtlConfig.cs                # فئة تكوين ETL
├── Program.cs                  # نقطة دخول التطبيق
├── Worker.cs                   # خدمة العامل الرئيسية
├── init-db.sh                  # نص تهيئة قاعدة البيانات
└── start-system.ps1            # نص PowerShell لبدء النظام
```

## إعداد البيئة

### 1. إعداد بيئة قاعدة البيانات

يستخدم هذا المشروع Docker لإنشاء بيئة تطوير كاملة بما في ذلك SQL Server و Elasticsearch وأدوات الإدارة.

#### مكونات قاعدة البيانات

1. **SQL Server**: قاعدة البيانات المصدر لعمليات ETL
   - اسم الحاوية: `sqlserver`
   - الإصدار: SQL Server 2022 Express
   - بيانات الاعتماد: اسم المستخدم `sa`، كلمة المرور `Passw0rd`
   - المنفذ: 1433
   - اسم قاعدة البيانات: `testDb`

2. **Elasticsearch**: الهدف للبيانات المفهرسة
   - اسم الحاوية: `elasticsearch`
   - الإصدار: 7.17.10
   - المنفذ: 9200
   - تم تكوينه كعنقود أحادي العقدة

3. **Kibana**: واجهة ويب لـ Elasticsearch
   - اسم الحاوية: `kibana`
   - الإصدار: 7.17.10
   - المنفذ: 5601
   - عنوان URL للوصول: http://localhost:5601

4. **Adminer**: أداة إدارة SQL Server المستندة إلى الويب
   - اسم الحاوية: `adminer`
   - المنفذ: 8080
   - عنوان URL للوصول: http://localhost:8080
   - الخادم الافتراضي: `sqlserver`

#### تهيئة قاعدة البيانات

يتضمن المشروع نصًا SQL (`database-setup.sql`) يقوم تلقائيًا بما يلي:

1. إنشاء قاعدة البيانات `testDb`
2. إنشاء الجداول الضرورية:
   - `tblCustomers`: جدول معلومات العملاء
   - `tblOrders`: جدول معلومات الطلبات
3. ملء هذه الجداول ببيانات نموذجية

تتعامل نصوص التهيئة (`init-db.sh` لـ Linux/macOS و `start-system.ps1` لـ Windows) مع:

1. بدء تشغيل جميع حاويات Docker
2. تنفيذ نص تهيئة SQL
3. إنشاء فهارس Elasticsearch مع التعيينات المناسبة

### 2. إعداد هيكل الدليل

قبل البدء، تأكد من وجود هذه الدلائل:

```bash
# على Linux/macOS
mkdir -p logs/customers logs/orders state data/sqlserver data/elasticsearch

# على Windows (PowerShell)
New-Item -ItemType Directory -Force -Path logs\customers, logs\orders, state, data\sqlserver, data\elasticsearch
```

أو استخدم النص المتوفر:

```bash
# على Linux/macOS
./init-db.sh

# على Windows
.\setup-directories.ps1
```

### 3. بدء النظام

```bash
# على Linux/macOS
./init-db.sh

# على Windows
.\start-system.ps1
```

هذا سيقوم بما يلي:

1. إنشاء الدلائل المطلوبة
2. بدء تشغيل جميع الحاويات
3. تهيئة قاعدة بيانات SQL Server
4. إنشاء فهارس Elasticsearch

## تكوين مهام ETL

يتم تكوين مهام ETL باستخدام ملفات YAML في دليل `tasks`. يحدد كل ملف مهمة ما يلي:

- سلسلة اتصال SQL
- استعلام SQL لاستخراج البيانات
- تفاصيل اتصال Elasticsearch
- عمود التتبع للتحديثات التدريجية
- الجدولة عبر تعبيرات cron

### مثال على تكوين المهمة

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

## إدارة قاعدة البيانات

### استخدام Adminer

يوفر Adminer واجهة ويب لإدارة قاعدة بيانات SQL Server:

1. **عرض الجداول**: انقر على اسم جدول لرؤية بنيته وبياناته
2. **تشغيل الاستعلامات**: استخدم واجهة أوامر SQL لتنفيذ استعلامات مخصصة
3. **تصدير البيانات**: تصدير البيانات بتنسيقات مختلفة (CSV، SQL، إلخ)
4. **تعديل المخطط**: إضافة أو تعديل الجداول والأعمدة والفهارس

### استخدام Kibana

يتيح لك Kibana التفاعل مع بيانات Elasticsearch:

1. **اكتشاف**: تصفح البيانات المفهرسة والبحث فيها
2. **تصور**: إنشاء رسوم بيانية ورسوم بيانية بناءً على بياناتك
3. **أدوات المطور**: تنفيذ استعلامات Elasticsearch مباشرة
4. **إدارة الفهرس**: مراقبة صحة الفهرس وإحصائياته

### تعديل البيانات النموذجية

لتعديل البيانات النموذجية:

1. قم بتحرير ملف `database-setup.sql`
2. أعد تشغيل الحاويات أو قم بتشغيل نص التهيئة مرة أخرى

## إضافة مهام ETL جديدة

لإضافة مهمة ETL جديدة:

1. قم بإنشاء ملف YAML جديد في دليل `tasks`
2. قم بتكوين معلمات المهمة (سلاسل الاتصال، الاستعلام، إلخ)
3. قم بتعيين `isEnabled: true` لتنشيط المهمة
4. أعد تشغيل خدمة ETL

## المراقبة والسجلات

- **سجلات خدمة ETL**: متاحة في دليل `logs`
- **بيانات Elasticsearch**: عرض باستخدام Kibana على http://localhost:5601
- **بيانات SQL Server**: عرض باستخدام Adminer على http://localhost:8080

## التطوير

### بناء الخدمة

```bash
dotnet build
```

### تشغيل الخدمة محليًا

```bash
dotnet run
```

### بناء صورة Docker

```bash
docker build -t etl-service .
```

## البنية

تتبع خدمة ETL نمط خدمة العامل:

1. **تكوين المهمة**: تحدد ملفات YAML مهام ETL
2. **خدمة العامل**: تنفذ المهام وفقًا لجدولها
3. **تتبع الحالة**: تحافظ على وقت التشغيل الناجح الأخير للتحديثات التدريجية
4. **التسجيل**: سجلات مفصلة للمراقبة واستكشاف الأخطاء وإصلاحها

## استكشاف الأخطاء وإصلاحها

### المشكلات الشائعة

1. **مشكلات الاتصال**:
   - تحقق من تشغيل SQL Server و Elasticsearch
   - تحقق من سلاسل الاتصال في ملفات تكوين المهمة
   - تأكد من أن المنافذ غير محظورة بواسطة جدار الحماية

2. **لا توجد بيانات متزامنة**:
   - تحقق مما إذا كانت البيانات تتطابق مع شرط التحديث التدريجي
   - تحقق من عمود التتبع والقيمة
   - تحقق من استعلام SQL للأخطاء النحوية

3. **الخدمة لا تبدأ**:
   - تحقق من السجلات لرسائل الخطأ
   - تحقق من تشغيل حاويات Docker
   - تأكد من وجود الدلائل المطلوبة

4. **فشل تهيئة قاعدة البيانات**:
   - تحقق من سجلات حاوية SQL Server: `docker logs sqlserver`
   - تحقق من بناء جملة النص SQL في `database-setup.sql`
   - تأكد من بدء تشغيل SQL Server قبل تشغيل التهيئة

## الترخيص

[رخصة MIT](LICENSE)

## المساهمة

المساهمات مرحب بها! لا تتردد في تقديم طلب سحب.
