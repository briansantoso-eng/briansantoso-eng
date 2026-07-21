-- ================================
-- Module 2: Dimension Tables
-- Author: Brian Santoso
-- Date: June 2026
-- ================================
-- WHAT THIS FILE DOES:
-- 1. Creates Dim_Customer (with SCD Type 2)
-- 2. Creates Dim_Carrier (with SCD Type 1)
-- 3. Creates Dim_Port (role-playing dimension)
-- 4. Creates Dim_Commodity
-- 5. Inserts sample data into each
-- 6. Verifies row counts
-- ================================

USE FreightDW;
GO

-- ================================
-- Dim_Customer: Customer dimension
-- ================================
-- Uses SCD Type 2 (Slowly Changing Dimension)
--
-- WHY SCD TYPE 2?
-- When a customer's details change (e.g. CreditRating drops from 'A' to
-- 'SUSPENDED'), we do NOT overwrite the old record. Instead we:
--   1. Set EffectiveEndDate on the old row to yesterday's date
--   2. Set IsCurrent = 0 on the old row
--   3. Insert a new row with the updated details and IsCurrent = 1
--
-- This means both rows stay in the table:
--   CustomerSK 1 | CUST0001 | CreditRating = A         | IsCurrent = 0 (historical)
--   CustomerSK 2 | CUST0001 | CreditRating = SUSPENDED | IsCurrent = 1 (current)
--
-- WHY THIS MATTERS:
-- A shipment booked in 2023 points to CustomerSK 1 -- correctly showing
-- the customer had an 'A' rating at that time.
-- A shipment booked in 2025 points to CustomerSK 2 -- correctly showing
-- 'SUSPENDED'. If we overwrote, all historical shipments would wrongly
-- show 'SUSPENDED' even for 2022 and 2023.
--
-- WHY EffectiveEndDate ALLOWS NULL:
-- NULL means this record has no end date yet - it is still the current
-- version. Once a newer record replaces it, we fill in this date.
-- ================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Dim_Customer')
BEGIN
    CREATE TABLE dbo.Dim_Customer (
        -- Surrogate key (system generated, never changes)
        CustomerSK          INT             NOT NULL IDENTITY(1,1),
        -- Business key (comes from source system e.g. CargoWise)
        CustomerBK          VARCHAR(20)     NOT NULL,
        -- Customer details
        CustomerName        VARCHAR(100)    NOT NULL,
        CustomerType        VARCHAR(30)     NOT NULL,  -- 'Importer','Exporter','Broker'
        Country             VARCHAR(60)     NOT NULL,
        City                VARCHAR(60)     NOT NULL,
        CreditRating        VARCHAR(10)     NOT NULL,  -- 'A','B','C','SUSPENDED'
        IsActive            BIT             NOT NULL DEFAULT 1,
        -- SCD Type 2 tracking columns
        EffectiveStartDate  DATE            NOT NULL,
        EffectiveEndDate    DATE            NULL,      -- NULL = still the current record
        IsCurrent           BIT             NOT NULL DEFAULT 1,
        -- Audit column: when was this row created
        CreatedDate         DATETIME        NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_DimCustomer PRIMARY KEY (CustomerSK)
    );
    PRINT 'Dim_Customer created successfully';
END
ELSE
    PRINT 'Dim_Customer already exists - skipping';
GO

-- ================================
-- Dim_Carrier: Shipping carrier dimension
-- ================================
-- Uses SCD Type 1 (overwrite on change)
--
-- WHY NOT SCD TYPE 2 HERE?
-- Carrier details like name and country rarely change.
-- We don't need to track the history of those changes
-- for shipment analysis - just the current state is enough.
--
-- WHY SCACCode IS NULLABLE:
-- SCAC codes are a sea freight standard only.
-- Air carriers use IATA codes, road carriers often have
-- nothing at all - so forcing a value here would be
-- meaningless for non-sea carriers.
-- ================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Dim_Carrier')
BEGIN
    CREATE TABLE dbo.Dim_Carrier (
        -- Surrogate key
        CarrierSK       INT             NOT NULL IDENTITY(1,1),
        -- Business key (internal carrier code)
        CarrierBK       VARCHAR(20)     NOT NULL,
        -- Carrier details
        CarrierName     VARCHAR(100)    NOT NULL,
        CarrierType     VARCHAR(30)     NOT NULL,  -- 'Sea','Air','Road','Rail'
        Country         VARCHAR(60)     NOT NULL,
        SCACCode        VARCHAR(4)      NULL,      -- Sea freight standard only
        IsActive        BIT             NOT NULL DEFAULT 1,
        -- Audit
        CreatedDate     DATETIME        NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_DimCarrier PRIMARY KEY (CarrierSK)
    );
    PRINT 'Dim_Carrier created successfully';
END
ELSE
    PRINT 'Dim_Carrier already exists - skipping';
GO

-- ================================
-- Dim_Port: Port and airport dimension
-- ================================
-- Role-playing dimension - used twice in Fact_Shipment:
--   OriginPortSK = where the shipment departed from
--   DestPortSK   = where the shipment arrived
--
-- WHY ONE TABLE USED TWICE?
-- Rather than creating Dim_OriginPort and Dim_DestPort
-- as separate identical tables, we reuse Dim_Port twice
-- in the fact table with different foreign key names.
-- This avoids duplicating data and is standard star
-- schema practice - called a "role-playing dimension".
--
-- Dim_Date is also a role-playing dimension - used three
-- times in Fact_Shipment for BookingDate, DepartureDate,
-- and ArrivalDate.
-- ================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Dim_Port')
BEGIN
    CREATE TABLE dbo.Dim_Port (
        -- Surrogate key
        PortSK          INT             NOT NULL IDENTITY(1,1),
        -- Business key (UN/LOCODE e.g. 'AUSYD' = Sydney Australia)
        PortBK          VARCHAR(10)     NOT NULL,
        -- Port details
        PortName        VARCHAR(100)    NOT NULL,
        PortType        VARCHAR(20)     NOT NULL,  -- 'Sea','Air','Inland'
        Country         VARCHAR(60)     NOT NULL,
        Region          VARCHAR(60)     NOT NULL,  -- e.g. 'Asia Pacific','Europe'
        IsActive        BIT             NOT NULL DEFAULT 1,
        -- Audit
        CreatedDate     DATETIME        NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_DimPort PRIMARY KEY (PortSK)
    );
    PRINT 'Dim_Port created successfully';
END
ELSE
    PRINT 'Dim_Port already exists - skipping';
GO

-- ================================
-- Dim_Commodity: Cargo commodity dimension
-- ================================
-- Describes what is being shipped.
--
-- KEY DESIGN DECISIONS:
-- IsDangerous and RequiresRefrig use BIT (0 or 1) not VARCHAR
-- ('Yes'/'No') - faster filtering, smaller storage, prevents
-- data entry errors like 'yes','YES','Y' all meaning the same thing.
-- DEFAULT 0 means safe and non-refrigerated unless specified.
--
-- HSCode is nullable - not all commodities map to an HS code.
-- ================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Dim_Commodity')
BEGIN
    CREATE TABLE dbo.Dim_Commodity (
        -- Surrogate key
        CommoditySK     INT             NOT NULL IDENTITY(1,1),
        -- Business key
        CommodityBK     VARCHAR(20)     NOT NULL,
        -- Commodity details
        CommodityName   VARCHAR(100)    NOT NULL,
        HSCode          VARCHAR(10)     NULL,      -- Harmonised System code (nullable)
        Category        VARCHAR(60)     NOT NULL,  -- e.g. 'Electronics','Food','Chemicals'
        IsDangerous     BIT             NOT NULL DEFAULT 0,
        RequiresRefrig  BIT             NOT NULL DEFAULT 0,
        -- Audit
        CreatedDate     DATETIME        NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_DimCommodity PRIMARY KEY (CommoditySK)
    );
    PRINT 'Dim_Commodity created successfully';
END
ELSE
    PRINT 'Dim_Commodity already exists - skipping';
GO

-- ================================
-- Verify all dimension tables exist
-- ================================

SELECT
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME IN ('Dim_Date','Dim_Customer','Dim_Carrier','Dim_Port','Dim_Commodity')
ORDER BY TABLE_NAME;
GO

-- ================================
-- Sample data for all dimensions
-- ================================

-- Clear existing data before inserting
DELETE FROM dbo.Dim_Commodity;
DELETE FROM dbo.Dim_Port;
DELETE FROM dbo.Dim_Carrier;
DELETE FROM dbo.Dim_Customer;
GO

-- Dim_Customer
INSERT INTO dbo.Dim_Customer
    (CustomerBK, CustomerName, CustomerType, Country, City,
     CreditRating, IsActive, EffectiveStartDate, EffectiveEndDate, IsCurrent)
VALUES
    ('CUST0001', 'Acme Logistics',     'Importer', 'Australia', 'Sydney',    'A', 1, '2022-01-01', NULL, 1),
    ('CUST0002', 'Pacific Trade Co',   'Exporter', 'Australia', 'Melbourne', 'B', 1, '2022-01-01', NULL, 1),
    ('CUST0003', 'Global Freight Ltd', 'Broker',   'Singapore', 'Singapore', 'A', 1, '2022-01-01', NULL, 1),
    ('CUST0004', 'Dragon Imports',     'Importer', 'China',     'Shanghai',  'C', 1, '2022-01-01', NULL, 1),
    ('CUST0005', 'Euro Cargo GmbH',    'Exporter', 'Germany',   'Hamburg',   'A', 1, '2022-01-01', NULL, 1);
GO

-- Dim_Carrier
INSERT INTO dbo.Dim_Carrier
    (CarrierBK, CarrierName, CarrierType, Country, SCACCode, IsActive)
VALUES
    ('MSC001', 'MSC Mediterranean Shipping', 'Sea',  'Switzerland', 'MSCU', 1),
    ('MAE001', 'Maersk Line',                'Sea',  'Denmark',     'MAEU', 1),
    ('CMA001', 'CMA CGM',                    'Sea',  'France',      'CMDU', 1),
    ('QAN001', 'Qantas Freight',             'Air',  'Australia',   NULL,   1),
    ('EMI001', 'Emirates SkyCargo',          'Air',  'UAE',         NULL,   1),
    ('TOL001', 'Toll Group',                 'Road', 'Australia',   NULL,   1);
GO

-- Dim_Port
INSERT INTO dbo.Dim_Port
    (PortBK, PortName, PortType, Country, Region, IsActive)
VALUES
    ('AUSYD', 'Port of Sydney',       'Sea',    'Australia',   'Asia Pacific', 1),
    ('AUMEL', 'Port of Melbourne',    'Sea',    'Australia',   'Asia Pacific', 1),
    ('CNSHA', 'Port of Shanghai',     'Sea',    'China',       'Asia Pacific', 1),
    ('SGSIN', 'Port of Singapore',    'Sea',    'Singapore',   'Asia Pacific', 1),
    ('NLRTM', 'Port of Rotterdam',    'Sea',    'Netherlands', 'Europe',       1),
    ('YSYD',  'Sydney Airport',       'Air',    'Australia',   'Asia Pacific', 1),
    ('YDXB',  'Dubai Airport',        'Air',    'UAE',         'Middle East',  1),
    ('TOLM',  'Toll Melbourne Depot', 'Inland', 'Australia',   'Asia Pacific', 1);
GO

-- Dim_Commodity
INSERT INTO dbo.Dim_Commodity
    (CommodityBK, CommodityName, HSCode, Category, IsDangerous, RequiresRefrig)
VALUES
    ('ELEC001', 'Consumer Electronics', '8471', 'Electronics', 0, 0),
    ('APRL001', 'Apparel and Textiles', '6110', 'Fashion',     0, 0),
    ('MACH001', 'Industrial Machinery', '8479', 'Machinery',   0, 0),
    ('FOOD001', 'Perishable Foods',     '2106', 'Food',        0, 1),
    ('CHEM001', 'Industrial Chemicals', '2901', 'Chemicals',   1, 0),
    ('PHAR001', 'Pharmaceuticals',      '3004', 'Healthcare',  0, 1);
GO

-- ================================
-- Verify row counts
-- ================================

USE FreightDW;
GO

SELECT 'Dim_Customer' AS TableName, COUNT(*) AS Rows FROM dbo.Dim_Customer
UNION ALL
SELECT 'Dim_Carrier',               COUNT(*)         FROM dbo.Dim_Carrier
UNION ALL
SELECT 'Dim_Port',                  COUNT(*)         FROM dbo.Dim_Port
UNION ALL
SELECT 'Dim_Commodity',             COUNT(*)         FROM dbo.Dim_Commodity
ORDER BY TableName;
GO