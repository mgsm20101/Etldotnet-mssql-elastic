# سكريبت PowerShell لإنشاء هيكل المجلدات اللازم للمشروع

Write-Host "جاري إنشاء هيكل المجلدات..." -ForegroundColor Cyan

# إنشاء مجلدات السجلات
New-Item -ItemType Directory -Force -Path logs\customers | Out-Null
New-Item -ItemType Directory -Force -Path logs\orders | Out-Null

# إنشاء مجلد الحالة
New-Item -ItemType Directory -Force -Path state | Out-Null

# إنشاء مجلدات البيانات
New-Item -ItemType Directory -Force -Path data\sqlserver | Out-Null
New-Item -ItemType Directory -Force -Path data\elasticsearch | Out-Null

Write-Host "تم إنشاء هيكل المجلدات بنجاح!" -ForegroundColor Green
Write-Host "الآن يمكنك تشغيل النظام باستخدام: .\start-system.ps1" -ForegroundColor Yellow
