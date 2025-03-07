-- إنشاء قاعدة بيانات للتجربة
USE master;
GO

-- التحقق من وجود قاعدة البيانات وإنشائها إذا لم تكن موجودة
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'testDb')
BEGIN
    CREATE DATABASE testDb;
END
GO

USE testDb;
GO

-- إنشاء جدول العملاء (tblCustomers)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'tblCustomers')
BEGIN
    CREATE TABLE tblCustomers (
        fID INT PRIMARY KEY IDENTITY(1,1),
        fName NVARCHAR(100),
        fNameA NVARCHAR(100),
        fAddress NVARCHAR(200),
        fTelephone NVARCHAR(20),
        fBirthDate DATETIME,
        fBagNo NVARCHAR(50),
        fEmpCode NVARCHAR(50),
        fMemberNo NVARCHAR(50),
        UIG_ID INT,
        CustomerType INT,
        LastVisitDate DATETIME,
        Gifts INT
    );
END
GO

-- إنشاء جدول الطلبات (tblOrders)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'tblOrders')
BEGIN
    CREATE TABLE tblOrders (
        fID INT PRIMARY KEY IDENTITY(1,1),
        fStoreIN INT,
        fSubStoreIN INT,
        fCustID INT,
        fStoreOut INT,
        fSubStoreOut INT,
        fDate DATETIME,
        fDesc NVARCHAR(500),
        fPosted BIT,
        fType INT,
        fSupID INT,
        fUserID INT,
        CostCenterID INT,
        ValidUntil DATETIME,
        StatusID INT,
        SubType INT,
        PostedDate DATETIME,
        PostedUser INT,
        RequestedDeliveryDate DATETIME,
        ManualSalesOrderNo NVARCHAR(50)
    );
END
GO

-- إضافة بيانات تجريبية لجدول العملاء
-- حذف البيانات الموجودة أولاً لتجنب التكرار
DELETE FROM tblCustomers;
GO

-- إدخال بيانات تجريبية للعملاء
INSERT INTO tblCustomers (fName, fNameA, fAddress, fTelephone, fBirthDate, fBagNo, fEmpCode, fMemberNo, UIG_ID, CustomerType, LastVisitDate, Gifts)
VALUES 
    (N'Ahmed Mohamed', N'أحمد محمد', N'القاهرة، شارع التحرير', N'01012345678', '1980-05-15', N'B001', N'E100', N'M001', 1, 1, '2023-01-15 10:30:00', 2),
    (N'Fatima Ali', N'فاطمة علي', N'الإسكندرية، شارع الحرية', N'01023456789', '1985-08-20', N'B002', N'E101', N'M002', 1, 2, '2023-02-20 14:45:00', 1),
    (N'Mahmoud Hassan', N'محمود حسن', N'الجيزة، المهندسين', N'01034567890', '1975-03-10', N'B003', N'E102', N'M003', 2, 1, '2023-03-10 09:15:00', 0),
    (N'Nour Khaled', N'نور خالد', N'القاهرة، مدينة نصر', N'01045678901', '1990-11-25', N'B004', N'E103', N'M004', 2, 3, '2023-04-05 16:20:00', 3),
    (N'Omar Samir', N'عمر سمير', N'الإسكندرية، سموحة', N'01056789012', '1982-07-30', N'B005', N'E104', N'M005', 3, 2, '2023-05-12 11:10:00', 1),
    (N'Layla Ibrahim', N'ليلى إبراهيم', N'القاهرة، المعادي', N'01067890123', '1988-09-18', N'B006', N'E105', N'M006', 3, 1, '2023-06-18 13:25:00', 2),
    (N'Kareem Ahmed', N'كريم أحمد', N'الجيزة، الدقي', N'01078901234', '1979-12-05', N'B007', N'E106', N'M007', 1, 3, '2023-07-22 15:40:00', 0),
    (N'Hoda Mostafa', N'هدى مصطفى', N'القاهرة، الزمالك', N'01089012345', '1992-04-12', N'B008', N'E107', N'M008', 2, 2, '2023-08-30 10:05:00', 1),
    (N'Tarek Youssef', N'طارق يوسف', N'الإسكندرية، العجمي', N'01090123456', '1977-06-28', N'B009', N'E108', N'M009', 3, 1, '2023-09-14 12:15:00', 2),
    (N'Amira Sayed', N'أميرة سيد', N'القاهرة، حلوان', N'01001234567', '1995-02-03', N'B010', N'E109', N'M010', 1, 2, '2023-10-25 09:30:00', 1);
GO

-- إضافة بيانات تجريبية لجدول الطلبات
-- حذف البيانات الموجودة أولاً لتجنب التكرار
DELETE FROM tblOrders;
GO

-- إدخال بيانات تجريبية للطلبات
INSERT INTO tblOrders (fStoreIN, fSubStoreIN, fCustID, fStoreOut, fSubStoreOut, fDate, fDesc, fPosted, fType, fSupID, fUserID, CostCenterID, ValidUntil, StatusID, SubType, PostedDate, PostedUser, RequestedDeliveryDate, ManualSalesOrderNo)
VALUES 
    (1, 1, 1, 2, 1, '2023-01-20 09:00:00', N'طلب منتجات إلكترونية', 1, 1, NULL, 5, 10, '2023-02-20 00:00:00', 1, 1, '2023-01-20 09:30:00', 5, '2023-01-25 00:00:00', N'SO-001'),
    (1, 2, 2, 2, 2, '2023-02-25 10:15:00', N'طلب أجهزة منزلية', 1, 1, NULL, 6, 11, '2023-03-25 00:00:00', 1, 1, '2023-02-25 10:45:00', 6, '2023-03-01 00:00:00', N'SO-002'),
    (2, 1, 3, 3, 1, '2023-03-15 11:30:00', N'طلب مستلزمات مكتبية', 1, 2, 1, 7, 12, '2023-04-15 00:00:00', 2, 2, '2023-03-15 12:00:00', 7, '2023-03-20 00:00:00', N'SO-003'),
    (2, 2, 4, 3, 2, '2023-04-10 12:45:00', N'طلب أثاث مكتبي', 0, 2, 2, 8, 13, '2023-05-10 00:00:00', 3, 2, NULL, NULL, '2023-04-15 00:00:00', N'SO-004'),
    (3, 1, 5, 4, 1, '2023-05-18 14:00:00', N'طلب مواد غذائية', 1, 1, NULL, 9, 14, '2023-06-18 00:00:00', 1, 1, '2023-05-18 14:30:00', 9, '2023-05-23 00:00:00', N'SO-005'),
    (3, 2, 6, 4, 2, '2023-06-22 15:15:00', N'طلب مستلزمات طبية', 1, 1, NULL, 10, 15, '2023-07-22 00:00:00', 1, 1, '2023-06-22 15:45:00', 10, '2023-06-27 00:00:00', N'SO-006'),
    (4, 1, 7, 5, 1, '2023-07-30 16:30:00', N'طلب أدوات رياضية', 1, 2, 3, 11, 16, '2023-08-30 00:00:00', 2, 2, '2023-07-30 17:00:00', 11, '2023-08-04 00:00:00', N'SO-007'),
    (4, 2, 8, 5, 2, '2023-08-12 09:45:00', N'طلب ملابس', 0, 2, 4, 12, 17, '2023-09-12 00:00:00', 3, 2, NULL, NULL, '2023-08-17 00:00:00', N'SO-008'),
    (5, 1, 9, 6, 1, '2023-09-05 11:00:00', N'طلب أجهزة كمبيوتر', 1, 1, NULL, 13, 18, '2023-10-05 00:00:00', 1, 1, '2023-09-05 11:30:00', 13, '2023-09-10 00:00:00', N'SO-009'),
    (5, 2, 10, 6, 2, '2023-10-28 13:15:00', N'طلب مستلزمات تجميل', 1, 1, NULL, 14, 19, '2023-11-28 00:00:00', 1, 1, '2023-10-28 13:45:00', 14, '2023-11-02 00:00:00', N'SO-010');
GO

-- إنشاء جملة استعلام لاختبار البيانات الجديدة (للعملاء)
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
WHERE LastVisitDate > '2023-05-01 00:00:00';

-- إنشاء جملة استعلام لاختبار البيانات الجديدة (للطلبات)
SELECT [fID]
,[fStoreIN]
,[fSubStoreIN]
,[fCustID]
,[fStoreOut]
,[fSubStoreOut]
,[fDate]
,[fDesc]
,[fPosted]
,[fType]
,[fSupID]
,[fUserID]
,[CostCenterID]
,[ValidUntil]
,[StatusID]
,[SubType]
,[PostedDate]
,[PostedUser]
,[RequestedDeliveryDate]
,[ManualSalesOrderNo]
FROM [dbo].[tblOrders]
WHERE fDate > '2023-06-01 00:00:00';

-- إنشاء جملة استعلام مطابقة للاستعلام المستخدم في ملف المهام (للعملاء)
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
WHERE LastVisitDate > @LastRunTime;

-- إنشاء جملة استعلام مطابقة للاستعلام المستخدم في ملف المهام (للطلبات)
SELECT [fID]
,[fStoreIN]
,[fSubStoreIN]
,[fCustID]
,[fStoreOut]
,[fSubStoreOut]
,[fDate]
,[fDesc]
,[fPosted]
,[fType]
,[fSupID]
,[fUserID]
,[CostCenterID]
,[ValidUntil]
,[StatusID]
,[SubType]
,[PostedDate]
,[PostedUser]
,[RequestedDeliveryDate]
,[ManualSalesOrderNo]
FROM [dbo].[tblOrders]
WHERE fDate > @LastRunTime;
