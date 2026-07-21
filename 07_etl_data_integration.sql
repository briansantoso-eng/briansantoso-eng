-- ================================
-- Module 7: ETL / Data Integration
-- Author: Brian Santoso
-- Date: July 2026
-- ================================
-- WHAT THIS FILE DOES:
-- 1. Creates staging tables (raw incoming data)
-- 2. Demonstrates load logic from source → warehouse
-- 3. Implements SCD Type 2 for customer changes
-- 4. Handles error detection and data quality
-- 5. Provides audit trails and logging
-- ================================

USE FreightDW;
GO

SELECT '=== MODULE 7: ETL / DATA INTEGRATION ===' AS [Section];
GO

-- ================================
-- SECTION 1: STAGING TABLES
-- ================================
-- Staging tables hold RAW data from source systems
-- (e.g., CargoWise, port authorities, carrier APIs)
-- They are temporary - data is validated, then moved to warehouse

SELECT '=== SECTION 1: STAGING TABLES ===' AS [Section];
GO

-- Staging Customer Data (from source system like CargoWise)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Stg_Customer')
BEGIN
    CREATE TABLE dbo.Stg_Customer (
        -- Source system keys
        SourceSystemID      INT             NOT NULL,  -- Which system? 1=CargoWise, 2=ERP, etc.
        SourceCustomerID    VARCHAR(20)     NOT NULL,  -- External ID

        -- Customer details
        CustomerName        VARCHAR(100)    NOT NULL,
        CustomerType        VARCHAR(30)     NOT NULL,
        Country             VARCHAR(60)     NOT NULL,
        City                VARCHAR(60)     NOT NULL,
        CreditRating        VARCHAR(10)     NOT NULL,
        IsActive            BIT             NOT NULL,

        -- Audit columns
        ExtractDate         DATETIME        NOT NULL DEFAULT GETDATE(),
        LoadDate            DATETIME        NULL,
        LoadStatus          VARCHAR(20)     DEFAULT 'Pending',  -- Pending, Success, Error
        ErrorMessage        VARCHAR(500)    NULL,

        CONSTRAINT PK_StgCustomer PRIMARY KEY (SourceSystemID, SourceCustomerID)
    );
    PRINT 'Created Stg_Customer';
END
GO

-- Staging Carrier Data
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Stg_Carrier')
BEGIN
    CREATE TABLE dbo.Stg_Carrier (
        SourceSystemID      INT             NOT NULL,
        SourceCarrierID     VARCHAR(20)     NOT NULL,
        CarrierName         VARCHAR(100)    NOT NULL,
        CarrierType         VARCHAR(30)     NOT NULL,
        Country             VARCHAR(60)     NOT NULL,
        SCACCode            VARCHAR(4)      NULL,
        IsActive            BIT             NOT NULL,
        ExtractDate         DATETIME        NOT NULL DEFAULT GETDATE(),
        LoadDate            DATETIME        NULL,
        LoadStatus          VARCHAR(20)     DEFAULT 'Pending',
        ErrorMessage        VARCHAR(500)    NULL,

        CONSTRAINT PK_StgCarrier PRIMARY KEY (SourceSystemID, SourceCarrierID)
    );
    PRINT 'Created Stg_Carrier';
END
GO

-- Staging Shipment Data
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Stg_Shipment')
BEGIN
    CREATE TABLE dbo.Stg_Shipment (
        SourceSystemID      INT             NOT NULL,
        SourceShipmentID    VARCHAR(20)     NOT NULL,
        SourceLoadNumber    VARCHAR(20)     NOT NULL,
        SourceCustomerID    VARCHAR(20)     NOT NULL,
        SourceCarrierID     VARCHAR(20)     NOT NULL,
        SourceOriginPort    VARCHAR(10)     NOT NULL,
        SourceDestPort      VARCHAR(10)     NOT NULL,
        SourceCommodityID   VARCHAR(20)     NOT NULL,

        BookingDate         DATE            NOT NULL,
        DepartureDate       DATE            NOT NULL,
        ArrivalDate         DATE            NULL,

        ShipmentCost        DECIMAL(12,2)   NOT NULL,
        Revenue             DECIMAL(12,2)   NOT NULL,
        WeightKg            DECIMAL(10,2)   NOT NULL,
        VolumeCbm           DECIMAL(10,2)   NOT NULL,
        NumContainers       INT             NOT NULL,
        ShipmentStatus      VARCHAR(20)     NOT NULL,

        ExtractDate         DATETIME        NOT NULL DEFAULT GETDATE(),
        LoadDate            DATETIME        NULL,
        LoadStatus          VARCHAR(20)     DEFAULT 'Pending',
        ErrorMessage        VARCHAR(500)    NULL,

        CONSTRAINT PK_StgShipment PRIMARY KEY (SourceSystemID, SourceShipmentID, SourceLoadNumber)
    );
    PRINT 'Created Stg_Shipment';
END
GO

-- ================================
-- SECTION 2: LOAD AUDIT LOG
-- ================================
-- Tracks every ETL load attempt for debugging and auditing

SELECT '=== SECTION 2: LOAD AUDIT LOG ===' AS [Section];
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Audit_LoadLog')
BEGIN
    CREATE TABLE dbo.Audit_LoadLog (
        LoadLogID           INT             NOT NULL IDENTITY(1,1),
        LoadDate            DATETIME        NOT NULL DEFAULT GETDATE(),
        TableName           VARCHAR(50)     NOT NULL,
        SourceSystem        INT             NOT NULL,
        RecordsExtracted    INT             NOT NULL,
        RecordsLoaded       INT             NOT NULL,
        RecordsErrored      INT             NOT NULL,
        LoadDurationMS      INT             NULL,
        LoadStatus          VARCHAR(20)     NOT NULL,  -- Success, PartialSuccess, Failed
        ErrorDetails        VARCHAR(MAX)    NULL,

        CONSTRAINT PK_AuditLoadLog PRIMARY KEY (LoadLogID)
    );
    PRINT 'Created Audit_LoadLog';
END
GO

-- ================================
-- SECTION 3: SAMPLE STAGING DATA
-- ================================
-- Simulate data coming from source systems

SELECT '=== SECTION 3: SAMPLE STAGING DATA ===' AS [Section];
GO

-- Insert sample customer data into staging (simulating CargoWise extract)
DELETE FROM dbo.Stg_Customer;
INSERT INTO dbo.Stg_Customer
    (SourceSystemID, SourceCustomerID, CustomerName, CustomerType, Country, City, CreditRating, IsActive)
VALUES
    (1, 'CUST0001', 'Acme Logistics',      'Importer',  'Australia', 'Sydney',      'A', 1),
    (1, 'CUST0002', 'Pacific Trade Co',    'Exporter',  'Australia', 'Melbourne',   'B', 1),
    (1, 'CUST0003', 'Global Freight Ltd',  'Broker',    'Singapore', 'Singapore',   'A', 1),
    (1, 'CUST0004', 'Dragon Imports',      'Importer',  'China',     'Shanghai',    'C', 1),
    (1, 'CUST0005', 'Euro Cargo GmbH',     'Exporter',  'Germany',   'Hamburg',     'A', 1),
    -- Simulate a change: Acme Logistics credit rating downgrade
    (1, 'CUST0001', 'Acme Logistics',      'Importer',  'Australia', 'Sydney',      'B', 1);

PRINT 'Loaded 6 records into Stg_Customer';
GO

-- ================================
-- SECTION 4: SCD TYPE 2 LOGIC
-- ================================
-- Slowly Changing Dimension Type 2:
-- When a customer detail changes, we don't overwrite.
-- Instead: Close old row (set EndDate, IsCurrent=0), Insert new row

SELECT '=== SECTION 4: SCD TYPE 2 LOGIC ===' AS [Section];
GO

-- Procedure: Load customers with SCD Type 2 logic
CREATE OR ALTER PROCEDURE dbo.sp_LoadDimCustomer_SCD2
    @SourceSystemID INT = 1
AS
BEGIN
    DECLARE @LoadLogID INT;
    DECLARE @RecordsExtracted INT = 0;
    DECLARE @RecordsLoaded INT = 0;
    DECLARE @RecordsErrored INT = 0;
    DECLARE @StartTime DATETIME = GETDATE();

    -- Log the load start
    INSERT INTO dbo.Audit_LoadLog (TableName, SourceSystem, RecordsExtracted, RecordsLoaded, RecordsErrored, LoadStatus)
    VALUES ('Dim_Customer', @SourceSystemID, 0, 0, 0, 'In Progress');
    SET @LoadLogID = @@IDENTITY;

    BEGIN TRY
        -- Step 1: Count records in staging
        SELECT @RecordsExtracted = COUNT(*) FROM dbo.Stg_Customer WHERE SourceSystemID = @SourceSystemID;

        -- Step 2: Find customers with changes (compare staging to current dimension)
        -- If customer details changed, close old record and insert new
        DECLARE @CustomerChanges TABLE (
            SourceCustomerID VARCHAR(20),
            Action VARCHAR(20),  -- 'New' or 'Changed'
            ExistingCustomerSK INT
        );

        INSERT INTO @CustomerChanges
        SELECT
            stg.SourceCustomerID,
            CASE
                WHEN dim.CustomerSK IS NULL THEN 'New'
                WHEN stg.CreditRating <> dim.CreditRating
                  OR stg.CustomerName <> dim.CustomerName THEN 'Changed'
            END,
            dim.CustomerSK
        FROM dbo.Stg_Customer stg
        LEFT JOIN dbo.Dim_Customer dim ON stg.SourceCustomerID = dim.CustomerBK AND dim.IsCurrent = 1
        WHERE stg.SourceSystemID = @SourceSystemID
          AND stg.LoadStatus IS NULL;

        -- Step 3a: For CHANGED customers, close old record
        UPDATE dbo.Dim_Customer
        SET EffectiveEndDate = DATEADD(DAY, -1, CAST(GETDATE() AS DATE)),
            IsCurrent = 0,
            LastUpdatedDate = GETDATE()
        WHERE CustomerSK IN (SELECT ExistingCustomerSK FROM @CustomerChanges WHERE Action = 'Changed');

        -- Step 3b: Insert new/updated customers
        INSERT INTO dbo.Dim_Customer
            (CustomerBK, CustomerName, CustomerType, Country, City, CreditRating, IsActive,
             EffectiveStartDate, EffectiveEndDate, IsCurrent, CreatedDate)
        SELECT
            stg.SourceCustomerID,
            stg.CustomerName,
            stg.CustomerType,
            stg.Country,
            stg.City,
            stg.CreditRating,
            stg.IsActive,
            CAST(GETDATE() AS DATE),
            NULL,
            1,
            GETDATE()
        FROM dbo.Stg_Customer stg
        INNER JOIN @CustomerChanges cc ON stg.SourceCustomerID = cc.SourceCustomerID
        WHERE stg.SourceSystemID = @SourceSystemID;

        SET @RecordsLoaded = @@ROWCOUNT;

        -- Step 4: Mark staging records as loaded
        UPDATE dbo.Stg_Customer
        SET LoadStatus = 'Success', LoadDate = GETDATE()
        WHERE SourceSystemID = @SourceSystemID;

        -- Update audit log
        UPDATE dbo.Audit_LoadLog
        SET RecordsExtracted = @RecordsExtracted,
            RecordsLoaded = @RecordsLoaded,
            RecordsErrored = 0,
            LoadStatus = 'Success',
            LoadDurationMS = DATEDIFF(MILLISECOND, @StartTime, GETDATE())
        WHERE LoadLogID = @LoadLogID;

        PRINT 'SCD Type 2 Load Complete: ' + CAST(@RecordsLoaded AS VARCHAR) + ' records loaded';

    END TRY
    BEGIN CATCH
        SET @RecordsErrored = @RecordsExtracted - @RecordsLoaded;

        -- Log error
        UPDATE dbo.Audit_LoadLog
        SET RecordsErrored = @RecordsErrored,
            LoadStatus = 'Failed',
            ErrorDetails = ERROR_MESSAGE(),
            LoadDurationMS = DATEDIFF(MILLISECOND, @StartTime, GETDATE())
        WHERE LoadLogID = @LoadLogID;

        -- Update staging records as errored
        UPDATE dbo.Stg_Customer
        SET LoadStatus = 'Error', ErrorMessage = ERROR_MESSAGE()
        WHERE SourceSystemID = @SourceSystemID AND LoadStatus IS NULL;

        PRINT 'ERROR: ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- ================================
-- SECTION 5: EXECUTE THE LOAD
-- ================================

SELECT '=== SECTION 5: EXECUTE SCD TYPE 2 LOAD ===' AS [Section];
GO

-- Execute the SCD Type 2 load procedure
EXEC dbo.sp_LoadDimCustomer_SCD2 @SourceSystemID = 1;
GO

-- ================================
-- SECTION 6: VERIFY RESULTS
-- ================================

SELECT '=== SECTION 6: LOAD RESULTS ===' AS [Section];
GO

-- Show all customers (including historical)
SELECT '--- All Customers (Including History) ---' AS Result;
SELECT
    CustomerSK,
    CustomerBK,
    CustomerName,
    CreditRating,
    EffectiveStartDate,
    EffectiveEndDate,
    IsCurrent
FROM dbo.Dim_Customer
ORDER BY CustomerBK, EffectiveStartDate;
GO

-- Show only current customers
SELECT '--- Current Customers Only ---' AS Result;
SELECT
    CustomerSK,
    CustomerBK,
    CustomerName,
    CreditRating,
    EffectiveStartDate
FROM dbo.Dim_Customer
WHERE IsCurrent = 1
ORDER BY CustomerBK;
GO

-- Show load history
SELECT '--- Load Audit Log ---' AS Result;
SELECT
    LoadLogID,
    LoadDate,
    TableName,
    RecordsExtracted,
    RecordsLoaded,
    RecordsErrored,
    LoadStatus,
    LoadDurationMS
FROM dbo.Audit_LoadLog
ORDER BY LoadDate DESC;
GO

-- Show staging status
SELECT '--- Staging Load Status ---' AS Result;
SELECT
    SourceCustomerID,
    CustomerName,
    CreditRating,
    LoadStatus,
    LoadDate,
    ErrorMessage
FROM dbo.Stg_Customer
ORDER BY SourceCustomerID;
GO

-- ================================
-- SECTION 7: DATA QUALITY CHECKS
-- ================================

SELECT '=== SECTION 7: DATA QUALITY VALIDATION ===' AS [Section];
GO

-- Check for orphaned customer records (shipments with missing customers)
SELECT '--- Orphaned Records Check ---' AS QualityCheck;
SELECT
    fs.ShipmentID,
    fs.CustomerSK,
    'MISSING CUSTOMER' AS Issue
FROM dbo.Fact_Shipment fs
LEFT JOIN dbo.Dim_Customer dc ON fs.CustomerSK = dc.CustomerSK
WHERE dc.CustomerSK IS NULL;

-- Check for data consistency
SELECT '--- Data Consistency Check ---' AS QualityCheck;
SELECT
    'Dim_Customer (Current)' AS Table_Checked,
    COUNT(*) AS Record_Count,
    COUNT(DISTINCT CustomerBK) AS Unique_Customers,
    CASE WHEN COUNT(*) = COUNT(DISTINCT CustomerBK) THEN 'OK' ELSE 'DUPLICATE KEYS!' END AS Status
FROM dbo.Dim_Customer
WHERE IsCurrent = 1;

-- Check for negative revenue
SELECT '--- Negative Values Check ---' AS QualityCheck;
SELECT
    COUNT(*) AS NegativeRecords
FROM dbo.Fact_Shipment
WHERE Revenue < 0 OR ShipmentCost < 0;

GO

-- ================================
-- SECTION 8: INCREMENTAL LOAD PATTERN
-- ================================
-- Show how you'd load only NEW/CHANGED records

SELECT '=== SECTION 8: INCREMENTAL LOAD PATTERN ===' AS [Section];
GO

SELECT 'In production, you would:
1. Track LastModifiedDate in source systems
2. Only extract records modified since last load
3. Apply SCD logic only to changed records
4. Log every change for audit trail

Example query (pseudo-code):
SELECT * FROM SourceCargoWise
WHERE LastModifiedDate > @PreviousLoadDate

This prevents reprocessing and improves performance.' AS [Incremental Load Strategy];
GO

PRINT '=== Module 7 Complete ==='
GO
