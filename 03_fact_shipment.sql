-- ================================
-- Module 3: Fact Table - Shipments
-- Author: Brian Santoso
-- Date: July 2026
-- ================================
-- WHAT THIS FILE DOES:
-- 1. Creates Fact_Shipment table (core fact table)
-- 2. Connects to all dimension tables via foreign keys
-- 3. Stores shipment measures: cost, revenue, weight, volume, containers
-- 4. Tracks dates: booking, departure, arrival (role-playing Dim_Date)
-- 5. Inserts sample shipment data
-- ================================

USE FreightDW;
GO

-- ================================
-- Create Fact_Shipment Table
-- ================================
-- GRAIN: One row = one complete shipment (from origin to destination)
--
-- WHY THIS GRAIN?
-- We track shipments end-to-end. If a shipment has multiple legs
-- (Sydney -> Singapore -> Rotterdam), that's ONE shipment row.
-- Each leg would be tracked in audit/status fields, not separate rows.
--
-- ================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Fact_Shipment')
BEGIN
    CREATE TABLE dbo.Fact_Shipment (
        -- ===== SURROGATE KEY =====
        ShipmentSK              INT             NOT NULL IDENTITY(1,1),

        -- ===== BUSINESS KEY =====
        -- ShipmentID comes from source system (e.g., CargoWise)
        -- Combined with LoadNumber forms the unique identifier
        ShipmentID              VARCHAR(20)     NOT NULL,
        LoadNumber              VARCHAR(20)     NOT NULL,

        -- ===== FOREIGN KEYS TO DIMENSIONS =====
        CustomerSK              INT             NOT NULL,
        OriginPortSK            INT             NOT NULL,     -- Role-playing: origin
        DestPortSK              INT             NOT NULL,     -- Role-playing: destination
        CarrierSK               INT             NOT NULL,
        CommoditySK             INT             NOT NULL,
        BookingDateSK           INT             NOT NULL,     -- Role-playing: when booked
        DepartureDateSK         INT             NOT NULL,     -- Role-playing: when shipped
        ArrivalDateSK           INT             NULL,         -- NULL if not yet arrived

        -- ===== MEASURES (Facts) =====
        -- Cost = what we paid the carrier
        ShipmentCost            DECIMAL(12,2)   NOT NULL DEFAULT 0,
        -- Revenue = what customer paid us
        Revenue                 DECIMAL(12,2)   NOT NULL DEFAULT 0,
        -- Physical characteristics
        WeightKg                DECIMAL(10,2)   NOT NULL DEFAULT 0,
        VolumeCbm               DECIMAL(10,2)   NOT NULL DEFAULT 0,  -- Cubic meters
        NumContainers           INT             NOT NULL DEFAULT 1,

        -- ===== CALCULATED / DERIVED =====
        -- Days in transit (calculated as ArrivalDate - DepartureDate)
        -- NULL if shipment hasn't arrived yet
        DaysInTransit           SMALLINT        NULL,

        -- ===== STATUS & AUDIT =====
        ShipmentStatus          VARCHAR(20)     NOT NULL DEFAULT 'In Transit',  -- 'In Transit','Delivered','Delayed','Cancelled'
        IsOnTime                BIT             NOT NULL DEFAULT 1,
        CreatedDate             DATETIME        NOT NULL DEFAULT GETDATE(),
        LastUpdatedDate         DATETIME        NOT NULL DEFAULT GETDATE(),

        -- ===== CONSTRAINTS =====
        CONSTRAINT PK_FactShipment PRIMARY KEY (ShipmentSK),
        CONSTRAINT UK_ShipmentBusiness UNIQUE (ShipmentID, LoadNumber),

        -- Foreign Keys
        CONSTRAINT FK_FactShipment_Customer FOREIGN KEY (CustomerSK)
            REFERENCES dbo.Dim_Customer(CustomerSK),
        CONSTRAINT FK_FactShipment_OriginPort FOREIGN KEY (OriginPortSK)
            REFERENCES dbo.Dim_Port(PortSK),
        CONSTRAINT FK_FactShipment_DestPort FOREIGN KEY (DestPortSK)
            REFERENCES dbo.Dim_Port(PortSK),
        CONSTRAINT FK_FactShipment_Carrier FOREIGN KEY (CarrierSK)
            REFERENCES dbo.Dim_Carrier(CarrierSK),
        CONSTRAINT FK_FactShipment_Commodity FOREIGN KEY (CommoditySK)
            REFERENCES dbo.Dim_Commodity(CommoditySK),
        CONSTRAINT FK_FactShipment_BookingDate FOREIGN KEY (BookingDateSK)
            REFERENCES dbo.Dim_Date(DateKey),
        CONSTRAINT FK_FactShipment_DepartureDate FOREIGN KEY (DepartureDateSK)
            REFERENCES dbo.Dim_Date(DateKey),
        CONSTRAINT FK_FactShipment_ArrivalDate FOREIGN KEY (ArrivalDateSK)
            REFERENCES dbo.Dim_Date(DateKey)
    );
    PRINT 'Fact_Shipment created successfully';
END
ELSE
    PRINT 'Fact_Shipment already exists - skipping';
GO

-- ================================
-- Verify table structure
-- ================================

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Fact_Shipment'
ORDER BY ORDINAL_POSITION;
GO

-- ================================
-- Insert Sample Data
-- ================================

-- Clear any existing data
DELETE FROM dbo.Fact_Shipment;
GO

-- Insert 10 sample shipments
INSERT INTO dbo.Fact_Shipment
    (ShipmentID, LoadNumber, CustomerSK, OriginPortSK, DestPortSK, CarrierSK, CommoditySK,
     BookingDateSK, DepartureDateSK, ArrivalDateSK, ShipmentCost, Revenue, WeightKg,
     VolumeCbm, NumContainers, DaysInTransit, ShipmentStatus, IsOnTime)
VALUES
    -- Shipment 1: Sydney to Shanghai (Delivered, On-time)
    ('SHIP0001', 'LOAD0001', 16, 9, 11, 7, 7, 20240101, 20240105, 20240118, 5000.00, 7500.00, 15000.00, 45.00, 2, 13, 'Delivered', 1),

    -- Shipment 2: Melbourne to Singapore (Delivered, On-time)
    ('SHIP0002', 'LOAD0002', 17, 10, 12, 8, 8, 20240110, 20240115, 20240122, 4500.00, 6800.00, 12000.00, 38.00, 1, 7, 'Delivered', 1),

    -- Shipment 3: Sydney to Rotterdam (Delivered, On-time)
    ('SHIP0003', 'LOAD0003', 18, 9, 13, 7, 9, 20240120, 20240125, 20240228, 12000.00, 18000.00, 25000.00, 80.00, 3, 34, 'Delivered', 1),

    -- Shipment 4: Shanghai to Sydney (In Transit, not yet arrived)
    ('SHIP0004', 'LOAD0004', 19, 11, 9, 8, 10, 20240201, 20240205, NULL, 3500.00, 5200.00, 8000.00, 25.00, 1, NULL, 'In Transit', 1),

    -- Shipment 5: Shanghai to Melbourne (Delayed)
    ('SHIP0005', 'LOAD0005', 16, 11, 10, 9, 11, 20240110, 20240115, 20240205, 6000.00, 9000.00, 18000.00, 55.00, 2, 21, 'Delivered', 0),

    -- Shipment 6: Hamburg to Sydney (In Transit)
    ('SHIP0006', 'LOAD0006', 20, 13, 9, 7, 12, 20240215, 20240220, NULL, 8000.00, 12000.00, 22000.00, 70.00, 2, NULL, 'In Transit', 1),

    -- Shipment 7: Sydney to Singapore (Air freight)
    ('SHIP0007', 'LOAD0007', 17, 9, 12, 10, 7, 20240225, 20240226, 20240227, 15000.00, 22500.00, 5000.00, 15.00, 0, 1, 'Delivered', 1),

    -- Shipment 8: Melbourne to Shanghai (In Transit)
    ('SHIP0008', 'LOAD0008', 18, 10, 11, 11, 8, 20240305, 20240310, NULL, 5500.00, 8250.00, 14000.00, 42.00, 1, NULL, 'In Transit', 1),

    -- Shipment 9: Singapore to Rotterdam (Delivered)
    ('SHIP0009', 'LOAD0009', 19, 12, 13, 8, 9, 20240201, 20240210, 20240315, 9000.00, 13500.00, 20000.00, 65.00, 2, 33, 'Delivered', 1),

    -- Shipment 10: Dubai Airport to Sydney (Air freight)
    ('SHIP0010', 'LOAD0010', 20, 15, 9, 11, 10, 20240310, 20240311, 20240312, 18000.00, 27000.00, 3000.00, 10.00, 0, 1, 'Delivered', 1);
GO

-- ================================
-- Verification Queries
-- ================================

-- Row count
SELECT COUNT(*) AS TotalShipments FROM dbo.Fact_Shipment;
GO

-- Check all shipments
SELECT * FROM dbo.Fact_Shipment;
GO

-- Shipments by customer
SELECT
    c.CustomerName,
    COUNT(*) AS ShipmentCount,
    SUM(fs.Revenue) AS TotalRevenue,
    SUM(fs.WeightKg) AS TotalWeightKg
FROM dbo.Fact_Shipment fs
JOIN dbo.Dim_Customer c ON fs.CustomerSK = c.CustomerSK
GROUP BY c.CustomerName
ORDER BY TotalRevenue DESC;
GO

-- In-transit vs delivered
SELECT
    ShipmentStatus,
    COUNT(*) AS Count,
    AVG(DaysInTransit) AS AvgDaysInTransit
FROM dbo.Fact_Shipment
WHERE ShipmentStatus IN ('In Transit', 'Delivered')
GROUP BY ShipmentStatus;
GO
