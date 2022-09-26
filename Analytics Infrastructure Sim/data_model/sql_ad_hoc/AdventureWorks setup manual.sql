-- AdventureWorks setup condensed 
-- originally for MS SQL Server 

\c development_db ;

-- Create Data Types in Postgres
CREATE DOMAIN "AccountNumber" AS varchar(15) NULL;
CREATE DOMAIN "Flag" AS bit NOT NULL;
CREATE DOMAIN "NameStyle" AS bit NOT NULL;
CREATE DOMAIN "Name" AS TEXT NULL;
CREATE DOMAIN "OrderNumber" AS varchar(25) NULL;
CREATE DOMAIN "Phone" AS varchar(25) NULL;

-- Add pre-table database functions.
CREATE FUNCTION "dev"."ufnLeadingZeros"(
    @Value int
) 
RETURNS varchar(8) 
WITH SCHEMABINDING 
AS 
BEGIN
    DECLARE @ReturnValue varchar(8);

    SET @ReturnValue = CONVERT(varchar(8), @Value);
    SET @ReturnValue = REPLICATE('0', 8 - DATALENGTH(@ReturnValue)) + @ReturnValue;

    RETURN (@ReturnValue);
END;

-- Create database schemas
CREATE SCHEMA "aw_humanResources";
CREATE SCHEMA "aw_person";
CREATE SCHEMA "aw_production";
CREATE SCHEMA "aw_purchasing";
CREATE SCHEMA "aw_sales";
CREATE SCHEMA "dev";

-- Create tables
CREATE TABLE aw_person."Address"(
    "AddressID" INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    "AddressLine1" VARCHAR(60) NOT NULL, 
    "AddressLine2" VARCHAR(60) NULL, 
    "City" VARCHAR(30) NOT NULL, 
    "StateProvinceID" INT NOT NULL,
    "PostalCode" VARCHAR(15) NOT NULL, 
	"SpatialLocation" "geography" NULL,
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_Address_rowguid" DEFAULT (NEWID()),
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_Address_ModifiedDate" DEFAULT (GETDATE())
);
CREATE TABLE aw_person."AddressType"(
    "AddressTypeID" INT IDENTITY (1, 1) NOT NULL,
    "Name" "Name" NOT NULL,
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_AddressType_rowguid" DEFAULT (NEWID()),
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_AddressType_ModifiedDate" DEFAULT (GETDATE())
);
CREATE TABLE dev."AWBuildVersion"(
    "SystemInformationID" INT IDENTITY (1, 1) NOT NULL,
    "Database Version" VARCHAR(25) NOT NULL, 
    "VersionDate" TIMESTAMP NOT NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_AWBuildVersion_ModifiedDate" DEFAULT (GETDATE())
);
CREATE TABLE aw_production."BillOfMaterials"(
    "BillOfMaterialsID" INT IDENTITY (1, 1) NOT NULL,
    "ProductAssemblyID" INT NULL,
    "ComponentID" INT NOT NULL,
    "StartDate" TIMESTAMP NOT NULL CONSTRAINT "DF_BillOfMaterials_StartDate" DEFAULT (GETDATE()),
    "EndDate" TIMESTAMP NULL,
    "UnitMeasureCode" "nchar"(3) NOT NULL, 
    "BOMLevel" "smallint" NOT NULL,
    "PerAssemblyQty" "decimal"(8, 2) NOT NULL CONSTRAINT "DF_BillOfMaterials_PerAssemblyQty" DEFAULT (1.00),
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_BillOfMaterials_ModifiedDate" DEFAULT (GETDATE()),
    CONSTRAINT "CK_BillOfMaterials_EndDate" CHECK (("EndDate" > "StartDate") OR ("EndDate" IS NULL)),
    CONSTRAINT "CK_BillOfMaterials_ProductAssemblyID" CHECK ("ProductAssemblyID" <> "ComponentID"),
    CONSTRAINT "CK_BillOfMaterials_BOMLevel" CHECK ((("ProductAssemblyID" IS NULL) 
        AND ("BOMLevel" = 0) AND ("PerAssemblyQty" = 1.00)) 
        OR (("ProductAssemblyID" IS NOT NULL) AND ("BOMLevel" >= 1))), 
    CONSTRAINT "CK_BillOfMaterials_PerAssemblyQty" CHECK ("PerAssemblyQty" >= 1.00) 
);
CREATE TABLE aw_person."BusinessEntity"(
	"BusinessEntityID" INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_BusinessEntity_rowguid" DEFAULT (NEWID()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_BusinessEntity_ModifiedDate" DEFAULT (GETDATE())	
);
CREATE TABLE aw_person."BusinessEntityAddress"(
	"BusinessEntityID" INT NOT NULL,
    "AddressID" INT NOT NULL,
    "AddressTypeID" INT NOT NULL,
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_BusinessEntityAddress_rowguid" DEFAULT (NEWID()),
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_BusinessEntityAddress_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_person."BusinessEntityContact"(
	"BusinessEntityID" INT NOT NULL,
    "PersonID" INT NOT NULL,
    "ContactTypeID" INT NOT NULL,
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_BusinessEntityContact_rowguid" DEFAULT (NEWID()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_BusinessEntityContact_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_person."ContactType"(
    "ContactTypeID" INT IDENTITY (1, 1) NOT NULL,
    "Name" "Name" NOT NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_ContactType_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_sales."CountryRegionCurrency"(
    "CountryRegionCode" VARCHAR(3) NOT NULL, 
    "CurrencyCode" "nchar"(3) NOT NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_CountryRegionCurrency_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_person."CountryRegion"(
    "CountryRegionCode" VARCHAR(3) NOT NULL, 
    "Name" "Name" NOT NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_CountryRegion_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_sales."CreditCard"(
    "CreditCardID" INT IDENTITY (1, 1) NOT NULL,
    "CardType" VARCHAR(50) NOT NULL,
    "CardNumber" VARCHAR(25) NOT NULL,
    "ExpMonth" INT NOT NULL,
    "ExpYear" "smallint" NOT NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_CreditCard_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_production."Culture"(
    "CultureID" "nchar"(6) NOT NULL,
    "Name" "Name" NOT NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_Culture_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_sales."Currency"(
    "CurrencyCode" "nchar"(3) NOT NULL, 
    "Name" "Name" NOT NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_Currency_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_sales."CurrencyRate"(
    "CurrencyRateID" INT IDENTITY (1, 1) NOT NULL,
    "CurrencyRateDate" TIMESTAMP NOT NULL,    
    "FromCurrencyCode" "nchar"(3) NOT NULL, 
    "ToCurrencyCode" "nchar"(3) NOT NULL, 
    "AverageRate" "money" NOT NULL,
    "EndOfDayRate" "money" NOT NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_CurrencyRate_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_sales."Customer"(
	"CustomerID" INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
	-- A customer may either be a person, a store, or a person who works for a store
	"PersonID" INT NULL, -- If this customer represents a person, this is non-null
    "StoreID" INT NULL,  -- If the customer is a store, or is associated with a store then this is non-null.
    "TerritoryID" INT NULL,
    "AccountNumber" AS ISNULL('AW' + dev."ufnLeadingZeros"(CustomerID), ''),
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_Customer_rowguid" DEFAULT (NEWID()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_Customer_ModifiedDate" DEFAULT (GETDATE())
);
CREATE TABLE aw_humanresources."Department"(
    "DepartmentID" "smallint" IDENTITY (1, 1) NOT NULL,
    "Name" "Name" NOT NULL,
    "GroupName" "Name" NOT NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_Department_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_production."Document"(
    "DocumentNode" "hierarchyid" NOT NULL,
	"DocumentLevel" AS DocumentNode.GetLevel(),
    "Title" VARCHAR(50) NOT NULL, 
	"Owner" INT NOT NULL,
	"FolderFlag" "bit" NOT NULL CONSTRAINT "DF_Document_FolderFlag" DEFAULT (0),
    "FileName" VARCHAR(400) NOT NULL, 
    "FileExtension" nvarchar(8) NOT NULL,
    "Revision" "nchar"(5) NOT NULL, 
    "ChangeNumber" INT NOT NULL CONSTRAINT "DF_Document_ChangeNumber" DEFAULT (0),
    "Status" INT NOT NULL,
    "DocumentSummary" VARCHAR(max) NULL,
    "Document" "varbinary"(max)  NULL,  
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL UNIQUE CONSTRAINT "DF_Document_rowguid" DEFAULT (NEWID()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_Document_ModifiedDate" DEFAULT (GETDATE()),
    CONSTRAINT "CK_Document_Status" CHECK ("Status" BETWEEN 1 AND 3)
);
CREATE TABLE aw_person."EmailAddress"(
	"BusinessEntityID" INT NOT NULL,
	"EmailAddressID" INT IDENTITY (1, 1) NOT NULL,
    "EmailAddress" VARCHAR(50) NULL, 
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_EmailAddress_rowguid" DEFAULT (NEWID()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_EmailAddress_ModifiedDate" DEFAULT (GETDATE())
);
CREATE TABLE aw_humanresources."Employee"(
    "BusinessEntityID" INT NOT NULL,
    "NationalIDNumber" VARCHAR(15) NOT NULL, 
    "LoginID" VARCHAR(256) NOT NULL,     
    "OrganizationNode" "hierarchyid" NULL,
	"OrganizationLevel" AS OrganizationNode.GetLevel(),
    "JobTitle" VARCHAR(50) NOT NULL, 
    "BirthDate" "date" NOT NULL,
    "MaritalStatus" "nchar"(1) NOT NULL, 
    "Gender" "nchar"(1) NOT NULL, 
    "HireDate" "date" NOT NULL,
    "SalariedFlag" "Flag" NOT NULL CONSTRAINT "DF_Employee_SalariedFlag" DEFAULT (1),
    "VacationHours" "smallint" NOT NULL CONSTRAINT "DF_Employee_VacationHours" DEFAULT (0),
    "SickLeaveHours" "smallint" NOT NULL CONSTRAINT "DF_Employee_SickLeaveHours" DEFAULT (0),
    "CurrentFlag" "Flag" NOT NULL CONSTRAINT "DF_Employee_CurrentFlag" DEFAULT (1),
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_Employee_rowguid" DEFAULT (NEWID()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_Employee_ModifiedDate" DEFAULT (GETDATE()),
    CONSTRAINT "CK_Employee_BirthDate" CHECK ("BirthDate" BETWEEN '1930-01-01' AND DATEADD(YEAR, -18, GETDATE())),
    CONSTRAINT "CK_Employee_MaritalStatus" CHECK (UPPER("MaritalStatus") IN ('M', 'S')), -- Married or Single
    CONSTRAINT "CK_Employee_HireDate" CHECK ("HireDate" BETWEEN '1996-07-01' AND DATEADD(DAY, 1, GETDATE())),
    CONSTRAINT "CK_Employee_Gender" CHECK (UPPER("Gender") IN ('M', 'F')), -- Male or Female
    CONSTRAINT "CK_Employee_VacationHours" CHECK ("VacationHours" BETWEEN -40 AND 240), 
    CONSTRAINT "CK_Employee_SickLeaveHours" CHECK ("SickLeaveHours" BETWEEN 0 AND 120) 
);
CREATE TABLE aw_humanresources."EmployeeDepartmentHistory"(
    "BusinessEntityID" INT NOT NULL,
    "DepartmentID" "smallint" NOT NULL,
    "ShiftID" INT NOT NULL,
    "StartDate" "date" NOT NULL,
    "EndDate" "date" NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_EmployeeDepartmentHistory_ModifiedDate" DEFAULT (GETDATE()), 
    CONSTRAINT "CK_EmployeeDepartmentHistory_EndDate" CHECK (("EndDate" >= "StartDate") OR ("EndDate" IS NULL)),
);
CREATE TABLE aw_humanresources."EmployeePayHistory"(
    "BusinessEntityID" INT NOT NULL,
    "RateChangeDate" TIMESTAMP NOT NULL,
    "Rate" "money" NOT NULL,
    "PayFrequency" INT NOT NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_EmployeePayHistory_ModifiedDate" DEFAULT (GETDATE()),
    CONSTRAINT "CK_EmployeePayHistory_PayFrequency" CHECK ("PayFrequency" IN (1, 2)), -- 1 = monthly salary, 2 = biweekly salary
    CONSTRAINT "CK_EmployeePayHistory_Rate" CHECK ("Rate" BETWEEN 6.50 AND 200.00) 
);
CREATE TABLE aw_production."Illustration"(
    "IllustrationID" INT IDENTITY (1, 1) NOT NULL,
    "Diagram" "XML" NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_Illustration_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_humanresources."JobCandidate"(
    "JobCandidateID" INT IDENTITY (1, 1) NOT NULL,
    "BusinessEntityID" INT NULL,
    "Resume" "XML"(aw_humanresources."HRResumeSchemaCollection") NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_JobCandidate_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_production."Location"(
    "LocationID" "smallint" IDENTITY (1, 1) NOT NULL,
    "Name" "Name" NOT NULL,
    "CostRate" "smallmoney" NOT NULL CONSTRAINT "DF_Location_CostRate" DEFAULT (0.00),
    "Availability" "decimal"(8, 2) NOT NULL CONSTRAINT "DF_Location_Availability" DEFAULT (0.00), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_Location_ModifiedDate" DEFAULT (GETDATE()), 
    CONSTRAINT "CK_Location_CostRate" CHECK ("CostRate" >= 0.00), 
    CONSTRAINT "CK_Location_Availability" CHECK ("Availability" >= 0.00) 
);
CREATE TABLE aw_person."Password"(
	"BusinessEntityID" INT NOT NULL,
    "PasswordHash" "varchar"(128) NOT NULL, 
    "PasswordSalt" "varchar"(10) NOT NULL,
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_Password_rowguid" DEFAULT (NEWID()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_Password_ModifiedDate" DEFAULT (GETDATE())

);
CREATE TABLE aw_person."Person"(
    "BusinessEntityID" INT NOT NULL,
	"PersonType" "nchar"(2) NOT NULL,
    "NameStyle" "NameStyle" NOT NULL CONSTRAINT "DF_Person_NameStyle" DEFAULT (0),
    "Title" VARCHAR(8) NULL, 
    "FirstName" "Name" NOT NULL,
    "MiddleName" "Name" NULL,
    "LastName" "Name" NOT NULL,
    "Suffix" VARCHAR(10) NULL, 
    "EmailPromotion" INT NOT NULL CONSTRAINT "DF_Person_EmailPromotion" DEFAULT (0), 
    "AdditionalContactInfo" "XML"(aw_person."AdditionalContactInfoSchemaCollection") NULL,
    "Demographics" "XML"(aw_person."IndividualSurveySchemaCollection") NULL, 
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_Person_rowguid" DEFAULT (NEWID()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_Person_ModifiedDate" DEFAULT (GETDATE()), 
    CONSTRAINT "CK_Person_EmailPromotion" CHECK ("EmailPromotion" BETWEEN 0 AND 2),
    CONSTRAINT "CK_Person_PersonType" CHECK ("PersonType" IS NULL OR UPPER("PersonType") IN ('SC', 'VC', 'IN', 'EM', 'SP', 'GC'))
);
CREATE TABLE aw_sales."PersonCreditCard"(
    "BusinessEntityID" INT NOT NULL,
    "CreditCardID" INT NOT NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_PersonCreditCard_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_person."PersonPhone"(
    "BusinessEntityID" INT NOT NULL,
	"PhoneNumber" "Phone" NOT NULL,
	"PhoneNumberTypeID" INT NOT NULL,
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_PersonPhone_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_person."PhoneNumberType"(
	"PhoneNumberTypeID" INT IDENTITY (1, 1) NOT NULL,
	"Name" "Name" NOT NULL,
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_PhoneNumberType_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_production."Product"(
    "ProductID" INT IDENTITY (1, 1) NOT NULL,
    "Name" "Name" NOT NULL,
    "ProductNumber" VARCHAR(25) NOT NULL, 
    "MakeFlag" "Flag" NOT NULL CONSTRAINT "DF_Product_MakeFlag" DEFAULT (1),
    "FinishedGoodsFlag" "Flag" NOT NULL CONSTRAINT "DF_Product_FinishedGoodsFlag" DEFAULT (1),
    "Color" VARCHAR(15) NULL, 
    "SafetyStockLevel" "smallint" NOT NULL,
    "ReorderPoint" "smallint" NOT NULL,
    "StandardCost" "money" NOT NULL,
    "ListPrice" "money" NOT NULL,
    "Size" VARCHAR(5) NULL, 
    "SizeUnitMeasureCode" "nchar"(3) NULL, 
    "WeightUnitMeasureCode" "nchar"(3) NULL, 
    "Weight" "decimal"(8, 2) NULL,
    "DaysToManufacture" INT NOT NULL,
    "ProductLine" "nchar"(2) NULL, 
    "Class" "nchar"(2) NULL, 
    "Style" "nchar"(2) NULL, 
    "ProductSubcategoryID" INT NULL,
    "ProductModelID" INT NULL,
    "SellStartDate" TIMESTAMP NOT NULL,
    "SellEndDate" TIMESTAMP NULL,
    "DiscontinuedDate" TIMESTAMP NULL,
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_Product_rowguid" DEFAULT (NEWID()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_Product_ModifiedDate" DEFAULT (GETDATE()),
    CONSTRAINT "CK_Product_SafetyStockLevel" CHECK ("SafetyStockLevel" > 0),
    CONSTRAINT "CK_Product_ReorderPoint" CHECK ("ReorderPoint" > 0),
    CONSTRAINT "CK_Product_StandardCost" CHECK ("StandardCost" >= 0.00),
    CONSTRAINT "CK_Product_ListPrice" CHECK ("ListPrice" >= 0.00),
    CONSTRAINT "CK_Product_Weight" CHECK ("Weight" > 0.00),
    CONSTRAINT "CK_Product_DaysToManufacture" CHECK ("DaysToManufacture" >= 0),
    CONSTRAINT "CK_Product_ProductLine" CHECK (UPPER("ProductLine") IN ('S', 'T', 'M', 'R') OR "ProductLine" IS NULL),
    CONSTRAINT "CK_Product_Class" CHECK (UPPER("Class") IN ('L', 'M', 'H') OR "Class" IS NULL),
    CONSTRAINT "CK_Product_Style" CHECK (UPPER("Style") IN ('W', 'M', 'U') OR "Style" IS NULL), 
    CONSTRAINT "CK_Product_SellEndDate" CHECK (("SellEndDate" >= "SellStartDate") OR ("SellEndDate" IS NULL)),
);
CREATE TABLE aw_production."ProductCategory"(
    "ProductCategoryID" INT IDENTITY (1, 1) NOT NULL,
    "Name" "Name" NOT NULL,
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_ProductCategory_rowguid" DEFAULT (NEWID()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_ProductCategory_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_production."ProductCostHistory"(
    "ProductID" INT NOT NULL,
    "StartDate" TIMESTAMP NOT NULL,
    "EndDate" TIMESTAMP NULL,
    "StandardCost" "money" NOT NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_ProductCostHistory_ModifiedDate" DEFAULT (GETDATE()),
    CONSTRAINT "CK_ProductCostHistory_EndDate" CHECK (("EndDate" >= "StartDate") OR ("EndDate" IS NULL)),
    CONSTRAINT "CK_ProductCostHistory_StandardCost" CHECK ("StandardCost" >= 0.00)
);
CREATE TABLE aw_production."ProductDescription"(
    "ProductDescriptionID" INT IDENTITY (1, 1) NOT NULL,
    "Description" VARCHAR(400) NOT NULL,
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_ProductDescription_rowguid" DEFAULT (NEWID()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_ProductDescription_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_production."ProductDocument"(
    "ProductID" INT NOT NULL,
    "DocumentNode" "hierarchyid" NOT NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_ProductDocument_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_production."ProductInventory"(
    "ProductID" INT NOT NULL,
    "LocationID" "smallint" NOT NULL,
    "Shelf" VARCHAR(10) NOT NULL, 
    "Bin" INT NOT NULL,
    "Quantity" "smallint" NOT NULL CONSTRAINT "DF_ProductInventory_Quantity" DEFAULT (0),
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_ProductInventory_rowguid" DEFAULT (NEWID()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_ProductInventory_ModifiedDate" DEFAULT (GETDATE()),
    CONSTRAINT "CK_ProductInventory_Shelf" CHECK (("Shelf" LIKE '"A-Za-z"') OR ("Shelf" = 'N/A')),
    CONSTRAINT "CK_ProductInventory_Bin" CHECK ("Bin" BETWEEN 0 AND 100)
);
CREATE TABLE aw_production."ProductListPriceHistory"(
    "ProductID" INT NOT NULL,
    "StartDate" TIMESTAMP NOT NULL,
    "EndDate" TIMESTAMP NULL,
    "ListPrice" "money" NOT NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_ProductListPriceHistory_ModifiedDate" DEFAULT (GETDATE()), 
    CONSTRAINT "CK_ProductListPriceHistory_EndDate" CHECK (("EndDate" >= "StartDate") OR ("EndDate" IS NULL)),
    CONSTRAINT "CK_ProductListPriceHistory_ListPrice" CHECK ("ListPrice" > 0.00)
);
CREATE TABLE aw_production."ProductModel"(
    "ProductModelID" INT IDENTITY (1, 1) NOT NULL,
    "Name" "Name" NOT NULL,
    "CatalogDescription" "XML"(aw_production."ProductDescriptionSchemaCollection") NULL,
    "Instructions" "XML"(aw_production."ManuInstructionsSchemaCollection") NULL,
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_ProductModel_rowguid" DEFAULT (NEWID()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_ProductModel_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_production."ProductModelIllustration"(
    "ProductModelID" INT NOT NULL,
    "IllustrationID" INT NOT NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_ProductModelIllustration_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_production."ProductModelProductDescriptionCulture"(
    "ProductModelID" INT NOT NULL,
    "ProductDescriptionID" INT NOT NULL,
    "CultureID" "nchar"(6) NOT NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_ProductModelProductDescriptionCulture_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_production."ProductPhoto"(
    "ProductPhotoID" INT IDENTITY (1, 1) NOT NULL,
    "ThumbNailPhoto" "varbinary"(max) NULL,
    "ThumbnailPhotoFileName" VARCHAR(50) NULL,
    "LargePhoto" "varbinary"(max) NULL,
    "LargePhotoFileName" VARCHAR(50) NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_ProductPhoto_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_production."ProductProductPhoto"(
    "ProductID" INT NOT NULL,
    "ProductPhotoID" INT NOT NULL,
    "Primary" "Flag" NOT NULL CONSTRAINT "DF_ProductProductPhoto_Primary" DEFAULT (0),
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_ProductProductPhoto_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_production."ProductReview"(
    "ProductReviewID" INT IDENTITY (1, 1) NOT NULL,
    "ProductID" INT NOT NULL,
    "ReviewerName" "Name" NOT NULL,
    "ReviewDate" TIMESTAMP NOT NULL CONSTRAINT "DF_ProductReview_ReviewDate" DEFAULT (GETDATE()),
    "EmailAddress" VARCHAR(50) NOT NULL,
    "Rating" INT NOT NULL,
    "Comments" VARCHAR(3850), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_ProductReview_ModifiedDate" DEFAULT (GETDATE()), 
    CONSTRAINT "CK_ProductReview_Rating" CHECK ("Rating" BETWEEN 1 AND 5), 
);
CREATE TABLE aw_production."ProductSubcategory"(
    "ProductSubcategoryID" INT IDENTITY (1, 1) NOT NULL,
    "ProductCategoryID" INT NOT NULL,
    "Name" "Name" NOT NULL,
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_ProductSubcategory_rowguid" DEFAULT (NEWID()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_ProductSubcategory_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_purchasing."ProductVendor"(
    "ProductID" INT NOT NULL,
    "BusinessEntityID" INT NOT NULL,
    "AverageLeadTime" INT NOT NULL,
    "StandardPrice" "money" NOT NULL,
    "LastReceiptCost" "money" NULL,
    "LastReceiptDate" TIMESTAMP NULL,
    "MinOrderQty" INT NOT NULL,
    "MaxOrderQty" INT NOT NULL,
    "OnOrderQty" INT NULL,
    "UnitMeasureCode" "nchar"(3) NOT NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_ProductVendor_ModifiedDate" DEFAULT (GETDATE()), 
    CONSTRAINT "CK_ProductVendor_AverageLeadTime" CHECK ("AverageLeadTime" >= 1),
    CONSTRAINT "CK_ProductVendor_StandardPrice" CHECK ("StandardPrice" > 0.00),
    CONSTRAINT "CK_ProductVendor_LastReceiptCost" CHECK ("LastReceiptCost" > 0.00),
    CONSTRAINT "CK_ProductVendor_MinOrderQty" CHECK ("MinOrderQty" >= 1),
    CONSTRAINT "CK_ProductVendor_MaxOrderQty" CHECK ("MaxOrderQty" >= 1),
    CONSTRAINT "CK_ProductVendor_OnOrderQty" CHECK ("OnOrderQty" >= 0)
);
CREATE TABLE aw_purchasing."PurchaseOrderDetail"(
    "PurchaseOrderID" INT NOT NULL,
    "PurchaseOrderDetailID" INT IDENTITY (1, 1) NOT NULL,
    "DueDate" TIMESTAMP NOT NULL,
    "OrderQty" "smallint" NOT NULL,
    "ProductID" INT NOT NULL,
    "UnitPrice" "money" NOT NULL,
    "LineTotal" AS ISNULL("OrderQty" * "UnitPrice", 0.00), 
    "ReceivedQty" "decimal"(8, 2) NOT NULL,
    "RejectedQty" "decimal"(8, 2) NOT NULL,
    "StockedQty" AS ISNULL("ReceivedQty" - "RejectedQty", 0.00),
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_PurchaseOrderDetail_ModifiedDate" DEFAULT (GETDATE()), 
    CONSTRAINT "CK_PurchaseOrderDetail_OrderQty" CHECK ("OrderQty" > 0), 
    CONSTRAINT "CK_PurchaseOrderDetail_UnitPrice" CHECK ("UnitPrice" >= 0.00), 
    CONSTRAINT "CK_PurchaseOrderDetail_ReceivedQty" CHECK ("ReceivedQty" >= 0.00), 
    CONSTRAINT "CK_PurchaseOrderDetail_RejectedQty" CHECK ("RejectedQty" >= 0.00) 
);
CREATE TABLE aw_purchasing."PurchaseOrderHeader"(
    "PurchaseOrderID" INT IDENTITY (1, 1) NOT NULL, 
    "RevisionNumber" INT NOT NULL CONSTRAINT "DF_PurchaseOrderHeader_RevisionNumber" DEFAULT (0), 
    "Status" INT NOT NULL CONSTRAINT "DF_PurchaseOrderHeader_Status" DEFAULT (1), 
    "EmployeeID" INT NOT NULL, 
    "VendorID" INT NOT NULL, 
    "ShipMethodID" INT NOT NULL, 
    "OrderDate" TIMESTAMP NOT NULL CONSTRAINT "DF_PurchaseOrderHeader_OrderDate" DEFAULT (GETDATE()), 
    "ShipDate" TIMESTAMP NULL, 
    "SubTotal" "money" NOT NULL CONSTRAINT "DF_PurchaseOrderHeader_SubTotal" DEFAULT (0.00), 
    "TaxAmt" "money" NOT NULL CONSTRAINT "DF_PurchaseOrderHeader_TaxAmt" DEFAULT (0.00), 
    "Freight" "money" NOT NULL CONSTRAINT "DF_PurchaseOrderHeader_Freight" DEFAULT (0.00), 
    "TotalDue" AS ISNULL("SubTotal" + "TaxAmt" + "Freight", 0) PERSISTED NOT NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_PurchaseOrderHeader_ModifiedDate" DEFAULT (GETDATE()), 
    CONSTRAINT "CK_PurchaseOrderHeader_Status" CHECK ("Status" BETWEEN 1 AND 4), -- 1 = Pending; 2 = Approved; 3 = Rejected; 4 = Complete 
    CONSTRAINT "CK_PurchaseOrderHeader_ShipDate" CHECK (("ShipDate" >= "OrderDate") OR ("ShipDate" IS NULL)), 
    CONSTRAINT "CK_PurchaseOrderHeader_SubTotal" CHECK ("SubTotal" >= 0.00), 
    CONSTRAINT "CK_PurchaseOrderHeader_TaxAmt" CHECK ("TaxAmt" >= 0.00), 
    CONSTRAINT "CK_PurchaseOrderHeader_Freight" CHECK ("Freight" >= 0.00) 
);
CREATE TABLE aw_sales."SalesOrderDetail"(
    "SalesOrderID" INT NOT NULL,
    "SalesOrderDetailID" INT IDENTITY (1, 1) NOT NULL,
    "CarrierTrackingNumber" VARCHAR(25) NULL, 
    "OrderQty" "smallint" NOT NULL,
    "ProductID" INT NOT NULL,
    "SpecialOfferID" INT NOT NULL,
    "UnitPrice" "money" NOT NULL,
    "UnitPriceDiscount" "money" NOT NULL CONSTRAINT "DF_SalesOrderDetail_UnitPriceDiscount" DEFAULT (0.0),
    "LineTotal" AS ISNULL("UnitPrice" * (1.0 - "UnitPriceDiscount") * "OrderQty", 0.0),
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_SalesOrderDetail_rowguid" DEFAULT (NEWID()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_SalesOrderDetail_ModifiedDate" DEFAULT (GETDATE()), 
    CONSTRAINT "CK_SalesOrderDetail_OrderQty" CHECK ("OrderQty" > 0), 
    CONSTRAINT "CK_SalesOrderDetail_UnitPrice" CHECK ("UnitPrice" >= 0.00), 
    CONSTRAINT "CK_SalesOrderDetail_UnitPriceDiscount" CHECK ("UnitPriceDiscount" >= 0.00) 
);
CREATE TABLE aw_sales."SalesOrderHeader"(
    "SalesOrderID" INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    "RevisionNumber" INT NOT NULL CONSTRAINT "DF_SalesOrderHeader_RevisionNumber" DEFAULT (0),
    "OrderDate" TIMESTAMP NOT NULL CONSTRAINT "DF_SalesOrderHeader_OrderDate" DEFAULT (GETDATE()),
    "DueDate" TIMESTAMP NOT NULL,
    "ShipDate" TIMESTAMP NULL,
    "Status" INT NOT NULL CONSTRAINT "DF_SalesOrderHeader_Status" DEFAULT (1),
    "OnlineOrderFlag" "Flag" NOT NULL CONSTRAINT "DF_SalesOrderHeader_OnlineOrderFlag" DEFAULT (1),
    "SalesOrderNumber" AS ISNULL(N'SO' + CONVERT(nvarchar(23), "SalesOrderID"), N'*** ERROR ***'), 
    "PurchaseOrderNumber" "OrderNumber" NULL,
    "AccountNumber" "AccountNumber" NULL,
    "CustomerID" INT NOT NULL,
    "SalesPersonID" INT NULL,
    "TerritoryID" INT NULL,
    "BillToAddressID" INT NOT NULL,
    "ShipToAddressID" INT NOT NULL,
    "ShipMethodID" INT NOT NULL,
    "CreditCardID" INT NULL,
    "CreditCardApprovalCode" "varchar"(15) NULL,    
    "CurrencyRateID" INT NULL,
    "SubTotal" "money" NOT NULL CONSTRAINT "DF_SalesOrderHeader_SubTotal" DEFAULT (0.00),
    "TaxAmt" "money" NOT NULL CONSTRAINT "DF_SalesOrderHeader_TaxAmt" DEFAULT (0.00),
    "Freight" "money" NOT NULL CONSTRAINT "DF_SalesOrderHeader_Freight" DEFAULT (0.00),
    "TotalDue" AS ISNULL("SubTotal" + "TaxAmt" + "Freight", 0),
    "Comment" VARCHAR(128) NULL,
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_SalesOrderHeader_rowguid" DEFAULT (NEWID()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_SalesOrderHeader_ModifiedDate" DEFAULT (GETDATE()),
    CONSTRAINT "CK_SalesOrderHeader_Status" CHECK ("Status" BETWEEN 0 AND 8), 
    CONSTRAINT "CK_SalesOrderHeader_DueDate" CHECK ("DueDate" >= "OrderDate"), 
    CONSTRAINT "CK_SalesOrderHeader_ShipDate" CHECK (("ShipDate" >= "OrderDate") OR ("ShipDate" IS NULL)), 
    CONSTRAINT "CK_SalesOrderHeader_SubTotal" CHECK ("SubTotal" >= 0.00), 
    CONSTRAINT "CK_SalesOrderHeader_TaxAmt" CHECK ("TaxAmt" >= 0.00), 
    CONSTRAINT "CK_SalesOrderHeader_Freight" CHECK ("Freight" >= 0.00) 
);
CREATE TABLE aw_sales."SalesOrderHeaderSalesReason"(
    "SalesOrderID" INT NOT NULL,
    "SalesReasonID" INT NOT NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_SalesOrderHeaderSalesReason_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_sales."SalesPerson"(
    "BusinessEntityID" INT NOT NULL,
    "TerritoryID" INT NULL,
    "SalesQuota" "money" NULL,
    "Bonus" "money" NOT NULL CONSTRAINT "DF_SalesPerson_Bonus" DEFAULT (0.00),
    "CommissionPct" "smallmoney" NOT NULL CONSTRAINT "DF_SalesPerson_CommissionPct" DEFAULT (0.00),
    "SalesYTD" "money" NOT NULL CONSTRAINT "DF_SalesPerson_SalesYTD" DEFAULT (0.00),
    "SalesLastYear" "money" NOT NULL CONSTRAINT "DF_SalesPerson_SalesLastYear" DEFAULT (0.00),
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_SalesPerson_rowguid" DEFAULT (NEWID()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_SalesPerson_ModifiedDate" DEFAULT (GETDATE()), 
    CONSTRAINT "CK_SalesPerson_SalesQuota" CHECK ("SalesQuota" > 0.00), 
    CONSTRAINT "CK_SalesPerson_Bonus" CHECK ("Bonus" >= 0.00), 
    CONSTRAINT "CK_SalesPerson_CommissionPct" CHECK ("CommissionPct" >= 0.00), 
    CONSTRAINT "CK_SalesPerson_SalesYTD" CHECK ("SalesYTD" >= 0.00), 
    CONSTRAINT "CK_SalesPerson_SalesLastYear" CHECK ("SalesLastYear" >= 0.00) 
);
CREATE TABLE aw_sales."SalesPersonQuotaHistory"(
    "BusinessEntityID" INT NOT NULL,
    "QuotaDate" TIMESTAMP NOT NULL,
    "SalesQuota" "money" NOT NULL,
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_SalesPersonQuotaHistory_rowguid" DEFAULT (NEWID()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_SalesPersonQuotaHistory_ModifiedDate" DEFAULT (GETDATE()), 
    CONSTRAINT "CK_SalesPersonQuotaHistory_SalesQuota" CHECK ("SalesQuota" > 0.00) 
);
CREATE TABLE aw_sales."SalesReason"(
    "SalesReasonID" INT IDENTITY (1, 1) NOT NULL,
    "Name" "Name" NOT NULL,
    "ReasonType" "Name" NOT NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_SalesReason_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_sales."SalesTaxRate"(
    "SalesTaxRateID" INT IDENTITY (1, 1) NOT NULL,
    "StateProvinceID" INT NOT NULL,
    "TaxType" INT NOT NULL,
    "TaxRate" "smallmoney" NOT NULL CONSTRAINT "DF_SalesTaxRate_TaxRate" DEFAULT (0.00),
    "Name" "Name" NOT NULL,
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_SalesTaxRate_rowguid" DEFAULT (NEWID()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_SalesTaxRate_ModifiedDate" DEFAULT (GETDATE()),
    CONSTRAINT "CK_SalesTaxRate_TaxType" CHECK ("TaxType" BETWEEN 1 AND 3)
);
CREATE TABLE aw_sales."SalesTerritory"(
    "TerritoryID" INT IDENTITY (1, 1) NOT NULL,
    "Name" "Name" NOT NULL,
    "CountryRegionCode" VARCHAR(3) NOT NULL, 
    "Group" VARCHAR(50) NOT NULL,
    "SalesYTD" "money" NOT NULL CONSTRAINT "DF_SalesTerritory_SalesYTD" DEFAULT (0.00),
    "SalesLastYear" "money" NOT NULL CONSTRAINT "DF_SalesTerritory_SalesLastYear" DEFAULT (0.00),
    "CostYTD" "money" NOT NULL CONSTRAINT "DF_SalesTerritory_CostYTD" DEFAULT (0.00),
    "CostLastYear" "money" NOT NULL CONSTRAINT "DF_SalesTerritory_CostLastYear" DEFAULT (0.00),
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_SalesTerritory_rowguid" DEFAULT (NEWID()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_SalesTerritory_ModifiedDate" DEFAULT (GETDATE()), 
    CONSTRAINT "CK_SalesTerritory_SalesYTD" CHECK ("SalesYTD" >= 0.00), 
    CONSTRAINT "CK_SalesTerritory_SalesLastYear" CHECK ("SalesLastYear" >= 0.00), 
    CONSTRAINT "CK_SalesTerritory_CostYTD" CHECK ("CostYTD" >= 0.00), 
    CONSTRAINT "CK_SalesTerritory_CostLastYear" CHECK ("CostLastYear" >= 0.00) 
);
CREATE TABLE aw_sales."SalesTerritoryHistory"(
    "BusinessEntityID" INT NOT NULL,  -- A sales person
    "TerritoryID" INT NOT NULL,
    "StartDate" TIMESTAMP NOT NULL,
    "EndDate" TIMESTAMP NULL,
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_SalesTerritoryHistory_rowguid" DEFAULT (NEWID()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_SalesTerritoryHistory_ModifiedDate" DEFAULT (GETDATE()), 
    CONSTRAINT "CK_SalesTerritoryHistory_EndDate" CHECK (("EndDate" >= "StartDate") OR ("EndDate" IS NULL))
);
CREATE TABLE aw_production."ScrapReason"(
    "ScrapReasonID" "smallint" IDENTITY (1, 1) NOT NULL,
    "Name" "Name" NOT NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_ScrapReason_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_humanresources."Shift"(
    "ShiftID" INT IDENTITY (1, 1) NOT NULL,
    "Name" "Name" NOT NULL,
    "StartTime" "time" NOT NULL,
    "EndTime" "time" NOT NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_Shift_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_purchasing."ShipMethod"(
    "ShipMethodID" INT IDENTITY (1, 1) NOT NULL,
    "Name" "Name" NOT NULL,
    "ShipBase" "money" NOT NULL CONSTRAINT "DF_ShipMethod_ShipBase" DEFAULT (0.00),
    "ShipRate" "money" NOT NULL CONSTRAINT "DF_ShipMethod_ShipRate" DEFAULT (0.00),
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_ShipMethod_rowguid" DEFAULT (NEWID()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_ShipMethod_ModifiedDate" DEFAULT (GETDATE()), 
    CONSTRAINT "CK_ShipMethod_ShipBase" CHECK ("ShipBase" > 0.00), 
    CONSTRAINT "CK_ShipMethod_ShipRate" CHECK ("ShipRate" > 0.00), 
);
CREATE TABLE aw_sales."ShoppingCartItem"(
    "ShoppingCartItemID" INT IDENTITY (1, 1) NOT NULL,
    "ShoppingCartID" VARCHAR(50) NOT NULL,
    "Quantity" INT NOT NULL CONSTRAINT "DF_ShoppingCartItem_Quantity" DEFAULT (1),
    "ProductID" INT NOT NULL,
    "DateCreated" TIMESTAMP NOT NULL CONSTRAINT "DF_ShoppingCartItem_DateCreated" DEFAULT (GETDATE()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_ShoppingCartItem_ModifiedDate" DEFAULT (GETDATE()), 
    CONSTRAINT "CK_ShoppingCartItem_Quantity" CHECK ("Quantity" >= 1) 
);
CREATE TABLE aw_sales."SpecialOffer"(
    "SpecialOfferID" INT IDENTITY (1, 1) NOT NULL,
    "Description" VARCHAR(255) NOT NULL,
    "DiscountPct" "smallmoney" NOT NULL CONSTRAINT "DF_SpecialOffer_DiscountPct" DEFAULT (0.00),
    "Type" VARCHAR(50) NOT NULL,
    "Category" VARCHAR(50) NOT NULL,
    "StartDate" TIMESTAMP NOT NULL,
    "EndDate" TIMESTAMP NOT NULL,
    "MinQty" INT NOT NULL CONSTRAINT "DF_SpecialOffer_MinQty" DEFAULT (0), 
    "MaxQty" INT NULL,
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_SpecialOffer_rowguid" DEFAULT (NEWID()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_SpecialOffer_ModifiedDate" DEFAULT (GETDATE()), 
    CONSTRAINT "CK_SpecialOffer_EndDate" CHECK ("EndDate" >= "StartDate"), 
    CONSTRAINT "CK_SpecialOffer_DiscountPct" CHECK ("DiscountPct" >= 0.00), 
    CONSTRAINT "CK_SpecialOffer_MinQty" CHECK ("MinQty" >= 0), 
    CONSTRAINT "CK_SpecialOffer_MaxQty"  CHECK ("MaxQty" >= 0)
);
CREATE TABLE aw_sales."SpecialOfferProduct"(
    "SpecialOfferID" INT NOT NULL,
    "ProductID" INT NOT NULL,
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_SpecialOfferProduct_rowguid" DEFAULT (NEWID()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_SpecialOfferProduct_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_person."StateProvince"(
    "StateProvinceID" INT IDENTITY (1, 1) NOT NULL,
    "StateProvinceCode" "nchar"(3) NOT NULL, 
    "CountryRegionCode" VARCHAR(3) NOT NULL, 
    "IsOnlyStateProvinceFlag" "Flag" NOT NULL CONSTRAINT "DF_StateProvince_IsOnlyStateProvinceFlag" DEFAULT (1),
    "Name" "Name" NOT NULL,
    "TerritoryID" INT NOT NULL,
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_StateProvince_rowguid" DEFAULT (NEWID()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_StateProvince_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_sales."Store"(
    "BusinessEntityID" INT NOT NULL,
    "Name" "Name" NOT NULL,
    "SalesPersonID" INT NULL,
    "Demographics" "XML"(aw_sales."StoreSurveySchemaCollection") NULL,
    "rowguid" uniqueidentifier ROWGUIDCOL NOT NULL CONSTRAINT "DF_Store_rowguid" DEFAULT (NEWID()), 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_Store_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_production."TransactionHistory"(
    "TransactionID" INT IDENTITY (100000, 1) NOT NULL,
    "ProductID" INT NOT NULL,
    "ReferenceOrderID" INT NOT NULL,
    "ReferenceOrderLineID" INT NOT NULL CONSTRAINT "DF_TransactionHistory_ReferenceOrderLineID" DEFAULT (0),
    "TransactionDate" TIMESTAMP NOT NULL CONSTRAINT "DF_TransactionHistory_TransactionDate" DEFAULT (GETDATE()),
    "TransactionType" "nchar"(1) NOT NULL, 
    "Quantity" INT NOT NULL,
    "ActualCost" "money" NOT NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_TransactionHistory_ModifiedDate" DEFAULT (GETDATE()),
    CONSTRAINT "CK_TransactionHistory_TransactionType" CHECK (UPPER("TransactionType") IN ('W', 'S', 'P'))
);
CREATE TABLE aw_production."TransactionHistoryArchive"(
    "TransactionID" INT NOT NULL,
    "ProductID" INT NOT NULL,
    "ReferenceOrderID" INT NOT NULL,
    "ReferenceOrderLineID" INT NOT NULL CONSTRAINT "DF_TransactionHistoryArchive_ReferenceOrderLineID" DEFAULT (0),
    "TransactionDate" TIMESTAMP NOT NULL CONSTRAINT "DF_TransactionHistoryArchive_TransactionDate" DEFAULT (GETDATE()),
    "TransactionType" "nchar"(1) NOT NULL, 
    "Quantity" INT NOT NULL,
    "ActualCost" "money" NOT NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_TransactionHistoryArchive_ModifiedDate" DEFAULT (GETDATE()),
    CONSTRAINT "CK_TransactionHistoryArchive_TransactionType" CHECK (UPPER("TransactionType") IN ('W', 'S', 'P'))
);
CREATE TABLE aw_production."UnitMeasure"(
    "UnitMeasureCode" "nchar"(3) NOT NULL, 
    "Name" "Name" NOT NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_UnitMeasure_ModifiedDate" DEFAULT (GETDATE()) 
);
CREATE TABLE aw_purchasing."Vendor"(
    "BusinessEntityID" INT NOT NULL,
    "AccountNumber" "AccountNumber" NOT NULL,
    "Name" "Name" NOT NULL,
    "CreditRating" INT NOT NULL,
    "PreferredVendorStatus" "Flag" NOT NULL CONSTRAINT "DF_Vendor_PreferredVendorStatus" DEFAULT (1), 
    "ActiveFlag" "Flag" NOT NULL CONSTRAINT "DF_Vendor_ActiveFlag" DEFAULT (1),
    "PurchasingWebServiceURL" VARCHAR(1024) NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_Vendor_ModifiedDate" DEFAULT (GETDATE()),
    CONSTRAINT "CK_Vendor_CreditRating" CHECK ("CreditRating" BETWEEN 1 AND 5)
);
CREATE TABLE aw_production."WorkOrder"(
    "WorkOrderID" INT IDENTITY (1, 1) NOT NULL,
    "ProductID" INT NOT NULL,
    "OrderQty" INT NOT NULL,
    "StockedQty" AS ISNULL("OrderQty" - "ScrappedQty", 0),
    "ScrappedQty" "smallint" NOT NULL,
    "StartDate" TIMESTAMP NOT NULL,
    "EndDate" TIMESTAMP NULL,
    "DueDate" TIMESTAMP NOT NULL,
    "ScrapReasonID" "smallint" NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_WorkOrder_ModifiedDate" DEFAULT (GETDATE()), 
    CONSTRAINT "CK_WorkOrder_OrderQty" CHECK ("OrderQty" > 0), 
    CONSTRAINT "CK_WorkOrder_ScrappedQty" CHECK ("ScrappedQty" >= 0), 
    CONSTRAINT "CK_WorkOrder_EndDate" CHECK (("EndDate" >= "StartDate") OR ("EndDate" IS NULL))
);
CREATE TABLE aw_production."WorkOrderRouting"(
    "WorkOrderID" INT NOT NULL,
    "ProductID" INT NOT NULL,
    "OperationSequence" "smallint" NOT NULL,
    "LocationID" "smallint" NOT NULL,
    "ScheduledStartDate" TIMESTAMP NOT NULL,
    "ScheduledEndDate" TIMESTAMP NOT NULL,
    "ActualStartDate" TIMESTAMP NULL,
    "ActualEndDate" TIMESTAMP NULL,
    "ActualResourceHrs" "decimal"(9, 4) NULL,
    "PlannedCost" "money" NOT NULL,
    "ActualCost" "money" NULL, 
    "ModifiedDate" TIMESTAMP NOT NULL CONSTRAINT "DF_WorkOrderRouting_ModifiedDate" DEFAULT (GETDATE()), 
    CONSTRAINT "CK_WorkOrderRouting_ScheduledEndDate" CHECK ("ScheduledEndDate" >= "ScheduledStartDate"), 
    CONSTRAINT "CK_WorkOrderRouting_ActualEndDate" CHECK (("ActualEndDate" >= "ActualStartDate") 
        OR ("ActualEndDate" IS NULL) OR ("ActualStartDate" IS NULL)), 
    CONSTRAINT "CK_WorkOrderRouting_ActualResourceHrs" CHECK ("ActualResourceHrs" >= 0.0000), 
    CONSTRAINT "CK_WorkOrderRouting_PlannedCost" CHECK ("PlannedCost" > 0.00), 
    CONSTRAINT "CK_WorkOrderRouting_ActualCost" CHECK ("ActualCost" > 0.00) 
);


-- Add Indexes (MS SQL Server) 
CREATE UNIQUE INDEX "AK_Address_rowguid" ON aw_person."Address"("rowguid") ON "PRIMARY";
CREATE UNIQUE INDEX "IX_Address_AddressLine1_AddressLine2_City_StateProvinceID_PostalCode" ON aw_person."Address" ("AddressLine1", "AddressLine2", "City", "StateProvinceID", "PostalCode") ON "PRIMARY";
CREATE INDEX "IX_Address_StateProvinceID" ON aw_person."Address"("StateProvinceID") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_AddressType_rowguid" ON aw_person."AddressType"("rowguid") ON "PRIMARY";
CREATE UNIQUE INDEX "AK_AddressType_Name" ON aw_person."AddressType"("Name") ON "PRIMARY";
GO

CREATE INDEX "IX_BillOfMaterials_UnitMeasureCode" ON aw_production."BillOfMaterials"("UnitMeasureCode") ON "PRIMARY";
CREATE UNIQUE CLUSTERED INDEX "AK_BillOfMaterials_ProductAssemblyID_ComponentID_StartDate" ON aw_production."BillOfMaterials"("ProductAssemblyID", "ComponentID", "StartDate") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_BusinessEntity_rowguid" ON aw_person."BusinessEntity"("rowguid") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_BusinessEntityAddress_rowguid" ON aw_person."BusinessEntityAddress"("rowguid") ON "PRIMARY";
CREATE INDEX "IX_BusinessEntityAddress_AddressID" ON aw_person."BusinessEntityAddress"("AddressID") ON "PRIMARY";
CREATE INDEX "IX_BusinessEntityAddress_AddressTypeID" ON aw_person."BusinessEntityAddress"("AddressTypeID") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_BusinessEntityContact_rowguid" ON aw_person."BusinessEntityContact"("rowguid") ON "PRIMARY";
CREATE INDEX "IX_BusinessEntityContact_PersonID" ON aw_person."BusinessEntityContact"("PersonID") ON "PRIMARY";
CREATE INDEX "IX_BusinessEntityContact_ContactTypeID" ON aw_person."BusinessEntityContact"("ContactTypeID") ON "PRIMARY";
GO


CREATE UNIQUE INDEX "AK_ContactType_Name" ON aw_person."ContactType"("Name") ON "PRIMARY";
GO

CREATE INDEX "IX_CountryRegionCurrency_CurrencyCode" ON aw_sales."CountryRegionCurrency"("CurrencyCode") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_CountryRegion_Name" ON aw_person."CountryRegion"("Name") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_CreditCard_CardNumber" ON aw_sales."CreditCard"("CardNumber") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_Culture_Name" ON aw_production."Culture"("Name") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_Currency_Name" ON aw_sales."Currency"("Name") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_CurrencyRate_CurrencyRateDate_FromCurrencyCode_ToCurrencyCode" ON aw_sales."CurrencyRate"("CurrencyRateDate", "FromCurrencyCode", "ToCurrencyCode") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_Customer_rowguid" ON aw_sales."Customer"("rowguid") ON "PRIMARY";
CREATE UNIQUE INDEX "AK_Customer_AccountNumber" ON aw_sales."Customer"("AccountNumber") ON "PRIMARY";
CREATE INDEX "IX_Customer_TerritoryID" ON aw_sales."Customer"("TerritoryID") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_Department_Name" ON aw_humanresources."Department"("Name") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_Document_DocumentLevel_DocumentNode" ON aw_production."Document" ("DocumentLevel", "DocumentNode");
CREATE UNIQUE INDEX "AK_Document_rowguid" ON aw_production."Document"("rowguid") ON "PRIMARY";
CREATE INDEX "IX_Document_FileName_Revision" ON aw_production."Document"("FileName", "Revision") ON "PRIMARY";
GO

CREATE INDEX "IX_EmailAddress_EmailAddress" ON aw_person."EmailAddress"("EmailAddress") ON "PRIMARY";
GO

CREATE INDEX "IX_Employee_OrganizationNode" ON aw_humanresources."Employee" ("OrganizationNode");
CREATE INDEX "IX_Employee_OrganizationLevel_OrganizationNode" ON aw_humanresources."Employee" ("OrganizationLevel", "OrganizationNode");
CREATE UNIQUE INDEX "AK_Employee_LoginID" ON aw_humanresources."Employee"("LoginID") ON "PRIMARY";
CREATE UNIQUE INDEX "AK_Employee_NationalIDNumber" ON aw_humanresources."Employee"("NationalIDNumber") ON "PRIMARY";
CREATE UNIQUE INDEX "AK_Employee_rowguid" ON aw_humanresources."Employee"("rowguid") ON "PRIMARY";
GO

CREATE INDEX "IX_EmployeeDepartmentHistory_DepartmentID" ON aw_humanresources."EmployeeDepartmentHistory"("DepartmentID") ON "PRIMARY";
CREATE INDEX "IX_EmployeeDepartmentHistory_ShiftID" ON aw_humanresources."EmployeeDepartmentHistory"("ShiftID") ON "PRIMARY";
GO

CREATE INDEX "IX_JobCandidate_BusinessEntityID" ON aw_humanresources."JobCandidate"("BusinessEntityID") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_Location_Name" ON aw_production."Location"("Name") ON "PRIMARY";
GO

CREATE INDEX "IX_Person_LastName_FirstName_MiddleName" ON aw_person."Person" ("LastName", "FirstName", "MiddleName") ON "PRIMARY";
CREATE UNIQUE INDEX "AK_Person_rowguid" ON aw_person."Person"("rowguid") ON "PRIMARY";

CREATE INDEX "IX_PersonPhone_PhoneNumber" on aw_person."PersonPhone" ("PhoneNumber") ON "PRIMARY";

CREATE UNIQUE INDEX "AK_Product_ProductNumber" ON aw_production."Product"("ProductNumber") ON "PRIMARY";
CREATE UNIQUE INDEX "AK_Product_Name" ON aw_production."Product"("Name") ON "PRIMARY";
CREATE UNIQUE INDEX "AK_Product_rowguid" ON aw_production."Product"("rowguid") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_ProductCategory_Name" ON aw_production."ProductCategory"("Name") ON "PRIMARY";
CREATE UNIQUE INDEX "AK_ProductCategory_rowguid" ON aw_production."ProductCategory"("rowguid") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_ProductDescription_rowguid" ON aw_production."ProductDescription"("rowguid") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_ProductModel_Name" ON aw_production."ProductModel"("Name") ON "PRIMARY";
CREATE UNIQUE INDEX "AK_ProductModel_rowguid" ON aw_production."ProductModel"("rowguid") ON "PRIMARY";
GO

CREATE NONCLUSTERED INDEX "IX_ProductReview_ProductID_Name" ON aw_production."ProductReview"("ProductID", "ReviewerName") INCLUDE ("Comments") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_ProductSubcategory_Name" ON aw_production."ProductSubcategory"("Name") ON "PRIMARY";
CREATE UNIQUE INDEX "AK_ProductSubcategory_rowguid" ON aw_production."ProductSubcategory"("rowguid") ON "PRIMARY";
GO

CREATE INDEX "IX_ProductVendor_UnitMeasureCode" ON aw_purchasing."ProductVendor"("UnitMeasureCode") ON "PRIMARY";
CREATE INDEX "IX_ProductVendor_BusinessEntityID" ON aw_purchasing."ProductVendor"("BusinessEntityID") ON "PRIMARY";
GO

CREATE INDEX "IX_PurchaseOrderDetail_ProductID" ON aw_purchasing."PurchaseOrderDetail"("ProductID") ON "PRIMARY";
GO

CREATE INDEX "IX_PurchaseOrderHeader_VendorID" ON aw_purchasing."PurchaseOrderHeader"("VendorID") ON "PRIMARY";
CREATE INDEX "IX_PurchaseOrderHeader_EmployeeID" ON aw_purchasing."PurchaseOrderHeader"("EmployeeID") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_SalesOrderDetail_rowguid" ON aw_sales."SalesOrderDetail"("rowguid") ON "PRIMARY";
CREATE INDEX "IX_SalesOrderDetail_ProductID" ON aw_sales."SalesOrderDetail"("ProductID") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_SalesOrderHeader_rowguid" ON aw_sales."SalesOrderHeader"("rowguid") ON "PRIMARY";
CREATE UNIQUE INDEX "AK_SalesOrderHeader_SalesOrderNumber" ON aw_sales."SalesOrderHeader"("SalesOrderNumber") ON "PRIMARY";
CREATE INDEX "IX_SalesOrderHeader_CustomerID" ON aw_sales."SalesOrderHeader"("CustomerID") ON "PRIMARY";
CREATE INDEX "IX_SalesOrderHeader_SalesPersonID" ON aw_sales."SalesOrderHeader"("SalesPersonID") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_SalesPerson_rowguid" ON aw_sales."SalesPerson"("rowguid") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_SalesPersonQuotaHistory_rowguid" ON aw_sales."SalesPersonQuotaHistory"("rowguid") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_SalesTaxRate_StateProvinceID_TaxType" ON aw_sales."SalesTaxRate"("StateProvinceID", "TaxType") ON "PRIMARY";
CREATE UNIQUE INDEX "AK_SalesTaxRate_rowguid" ON aw_sales."SalesTaxRate"("rowguid") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_SalesTerritory_Name" ON aw_sales."SalesTerritory"("Name") ON "PRIMARY";
CREATE UNIQUE INDEX "AK_SalesTerritory_rowguid" ON aw_sales."SalesTerritory"("rowguid") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_SalesTerritoryHistory_rowguid" ON aw_sales."SalesTerritoryHistory"("rowguid") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_ScrapReason_Name" ON aw_production."ScrapReason"("Name") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_Shift_Name" ON aw_humanresources."Shift"("Name") ON "PRIMARY";
CREATE UNIQUE INDEX "AK_Shift_StartTime_EndTime" ON aw_humanresources."Shift"("StartTime", "EndTime") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_ShipMethod_Name" ON aw_purchasing."ShipMethod"("Name") ON "PRIMARY";
CREATE UNIQUE INDEX "AK_ShipMethod_rowguid" ON aw_purchasing."ShipMethod"("rowguid") ON "PRIMARY";
GO

CREATE INDEX "IX_ShoppingCartItem_ShoppingCartID_ProductID" ON aw_sales."ShoppingCartItem"("ShoppingCartID", "ProductID") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_SpecialOffer_rowguid" ON aw_sales."SpecialOffer"("rowguid") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_SpecialOfferProduct_rowguid" ON aw_sales."SpecialOfferProduct"("rowguid") ON "PRIMARY";
CREATE INDEX "IX_SpecialOfferProduct_ProductID" ON aw_sales."SpecialOfferProduct"("ProductID") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_StateProvince_Name" ON aw_person."StateProvince"("Name") ON "PRIMARY";
CREATE UNIQUE INDEX "AK_StateProvince_StateProvinceCode_CountryRegionCode" ON aw_person."StateProvince"("StateProvinceCode", "CountryRegionCode") ON "PRIMARY";
CREATE UNIQUE INDEX "AK_StateProvince_rowguid" ON aw_person."StateProvince"("rowguid") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_Store_rowguid" ON aw_sales."Store"("rowguid") ON "PRIMARY";
CREATE INDEX "IX_Store_SalesPersonID" ON aw_sales."Store"("SalesPersonID") ON "PRIMARY";
GO

CREATE INDEX "IX_TransactionHistory_ProductID" ON aw_production."TransactionHistory"("ProductID") ON "PRIMARY";
CREATE INDEX "IX_TransactionHistory_ReferenceOrderID_ReferenceOrderLineID" ON aw_production."TransactionHistory"("ReferenceOrderID", "ReferenceOrderLineID") ON "PRIMARY";
GO

CREATE INDEX "IX_TransactionHistoryArchive_ProductID" ON aw_production."TransactionHistoryArchive"("ProductID") ON "PRIMARY";
CREATE INDEX "IX_TransactionHistoryArchive_ReferenceOrderID_ReferenceOrderLineID" ON aw_production."TransactionHistoryArchive"("ReferenceOrderID", "ReferenceOrderLineID") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_UnitMeasure_Name" ON aw_production."UnitMeasure"("Name") ON "PRIMARY";
GO

CREATE UNIQUE INDEX "AK_Vendor_AccountNumber" ON aw_purchasing."Vendor"("AccountNumber") ON "PRIMARY";
GO

CREATE INDEX "IX_WorkOrder_ScrapReasonID" ON aw_production."WorkOrder"("ScrapReasonID") ON "PRIMARY";
CREATE INDEX "IX_WorkOrder_ProductID" ON aw_production."WorkOrder"("ProductID") ON "PRIMARY";
GO

CREATE INDEX "IX_WorkOrderRouting_ProductID" ON aw_production."WorkOrderRouting"("ProductID") ON "PRIMARY";
GO
