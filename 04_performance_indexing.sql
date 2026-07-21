-- ================================
-- Module 4: Performance & Indexing
-- Author: Brian Santoso
-- Date: July 2026
-- ================================
-- WHAT THIS FILE DOES:
-- 1. Creates non-clustered indexes on foreign keys
-- 2. Creates non-clustered index on date columns
-- 3. Creates filtered index on ShipmentStatus
-- 4. Demonstrates query execution plans
-- 5. Shows performance impact of indexes
-- ================================

USE FreightDW;
GO

-- ================================
-- Section 1: Verify Current State
-- ================================

PRINT '=== BEFORE INDEXES ==='
GO

-- Show current indexes (only clustered PK exists)
SELECT
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType
FROM sys.indexes i
WHERE OBJECT_NAME(i.object_id) = 'Fact_Shipment'
ORDER BY i.type_desc;
GO

-- ================================
-- Section 2: Create Non-Clustered Indexes
-- ================================

PRINT '=== CREATING INDEXES ==='
GO

-- Index 1: Foreign Key - CustomerSK
-- WHY: Queries filter/join on CustomerSK frequently
-- EXAMPLE: "Find all shipments for customer 16"
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactShipment_CustomerSK')
BEGIN
    CREATE NONCLUSTERED INDEX IX_FactShipment_CustomerSK
    ON dbo.Fact_Shipment (CustomerSK)
    INCLUDE (ShipmentID, Revenue, ShipmentStatus);

    PRINT 'Created IX_FactShipment_CustomerSK';
END
GO

-- Index 2: Foreign Key - CarrierSK
-- WHY: Queries analyze shipments by carrier
-- EXAMPLE: "Which carrier has highest on-time rate?"
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactShipment_CarrierSK')
BEGIN
    CREATE NONCLUSTERED INDEX IX_FactShipment_CarrierSK
    ON dbo.Fact_Shipment (CarrierSK)
    INCLUDE (DaysInTransit, IsOnTime, Revenue);

    PRINT 'Created IX_FactShipment_CarrierSK';
END
GO

-- Index 3: Foreign Key - OriginPortSK
-- WHY: Route analysis queries
-- EXAMPLE: "What shipments originate from Sydney?"
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactShipment_OriginPortSK')
BEGIN
    CREATE NONCLUSTERED INDEX IX_FactShipment_OriginPortSK
    ON dbo.Fact_Shipment (OriginPortSK)
    INCLUDE (DestPortSK, ShipmentStatus);

    PRINT 'Created IX_FactShipment_OriginPortSK';
END
GO

-- Index 4: Foreign Key - DestPortSK
-- WHY: Destination analysis
-- EXAMPLE: "Total volume arriving at Shanghai?"
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactShipment_DestPortSK')
BEGIN
    CREATE NONCLUSTERED INDEX IX_FactShipment_DestPortSK
    ON dbo.Fact_Shipment (DestPortSK)
    INCLUDE (WeightKg, VolumeCbm, NumContainers);

    PRINT 'Created IX_FactShipment_DestPortSK';
END
GO

-- Index 5: Date Key - BookingDateSK
-- WHY: Time-series analysis
-- EXAMPLE: "Revenue by booking month?"
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactShipment_BookingDateSK')
BEGIN
    CREATE NONCLUSTERED INDEX IX_FactShipment_BookingDateSK
    ON dbo.Fact_Shipment (BookingDateSK)
    INCLUDE (Revenue, ShipmentStatus);

    PRINT 'Created IX_FactShipment_BookingDateSK';
END
GO

-- Index 6: Filtered Index - Active Shipments
-- WHY: Most queries focus on In-Transit and recent shipments
-- This index is SMALLER (fewer rows), FASTER for common queries
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactShipment_ActiveShipments')
BEGIN
    CREATE NONCLUSTERED INDEX IX_FactShipment_ActiveShipments
    ON dbo.Fact_Shipment (ShipmentStatus, CustomerSK)
    INCLUDE (DaysInTransit, IsOnTime)
    WHERE ShipmentStatus IN ('In Transit', 'Delayed');

    PRINT 'Created IX_FactShipment_ActiveShipments (filtered index)';
END
GO

-- ================================
-- Section 3: Verify Indexes Created
-- ================================

PRINT '=== AFTER INDEXES ==='
GO

SELECT
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    (SELECT COUNT(*) FROM sys.index_columns ic WHERE ic.index_id = i.index_id AND ic.object_id = i.object_id) AS KeyColumnCount
FROM sys.indexes i
WHERE OBJECT_NAME(i.object_id) = 'Fact_Shipment'
ORDER BY i.type_desc, i.name;
GO

-- ================================
-- Section 4: Query Execution Plans & Performance
-- ================================

PRINT '=== QUERY PERFORMANCE EXAMPLES ==='
GO

-- Query 1: Find all shipments by customer
-- Benefit: Index on CustomerSK allows quick lookup
SELECT
    ShipmentID,
    ShipmentStatus,
    Revenue
FROM dbo.Fact_Shipment
WHERE CustomerSK = 16
ORDER BY ShipmentID;
GO

-- Query 2: Carrier performance analysis
-- Benefit: Index on CarrierSK + included DaysInTransit, IsOnTime
SELECT
    CarrierSK,
    COUNT(*) AS ShipmentCount,
    AVG(DaysInTransit) AS AvgDaysInTransit,
    SUM(CASE WHEN IsOnTime = 1 THEN 1 ELSE 0 END) AS OnTimeCount,
    ROUND(100.0 * SUM(CASE WHEN IsOnTime = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS OnTimePercentage
FROM dbo.Fact_Shipment
GROUP BY CarrierSK
ORDER BY OnTimePercentage DESC;
GO

-- Query 3: Route analysis
-- Benefit: Indexes on OriginPortSK and DestPortSK
SELECT TOP 10
    fs.ShipmentID,
    po.PortName AS OriginPort,
    pd.PortName AS DestPort,
    fs.WeightKg,
    fs.VolumeCbm,
    fs.ShipmentStatus
FROM dbo.Fact_Shipment fs
JOIN dbo.Dim_Port po ON fs.OriginPortSK = po.PortSK
JOIN dbo.Dim_Port pd ON fs.DestPortSK = pd.PortSK
WHERE fs.OriginPortSK = 9  -- Sydney
ORDER BY fs.ShipmentID;
GO

-- Query 4: Time-series analysis
-- Benefit: Index on BookingDateSK
SELECT
    dd.Year,
    dd.Month,
    dd.MonthName,
    COUNT(*) AS ShipmentCount,
    SUM(fs.Revenue) AS TotalRevenue,
    AVG(fs.Revenue) AS AvgRevenue
FROM dbo.Fact_Shipment fs
JOIN dbo.Dim_Date dd ON fs.BookingDateSK = dd.DateKey
GROUP BY dd.Year, dd.Month, dd.MonthName
ORDER BY dd.Year, dd.Month;
GO

-- Query 5: Active shipment tracking (uses filtered index)
-- Benefit: Filtered index only contains In-Transit/Delayed, making it smaller and faster
SELECT
    ShipmentID,
    CustomerSK,
    CarrierSK,
    DaysInTransit,
    IsOnTime
FROM dbo.Fact_Shipment
WHERE ShipmentStatus IN ('In Transit', 'Delayed')
ORDER BY DaysInTransit DESC;
GO

-- ================================
-- Section 5: Index Statistics & Maintenance Info
-- ================================

PRINT '=== INDEX STATISTICS ==='
GO

-- Show index sizes and fragmentation
SELECT
    i.name AS IndexName,
    ips.index_type_desc AS IndexType,
    ips.avg_fragmentation_in_percent AS FragmentationPercent,
    ips.page_count AS PageCount
FROM sys.dm_db_index_physical_stats(DB_ID('FreightDW'), OBJECT_ID('Fact_Shipment'), NULL, NULL, 'LIMITED') ips
JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.index_level = 0  -- Leaf level only
ORDER BY ips.avg_fragmentation_in_percent DESC;
GO

-- ================================
-- Section 6: Index Usage Statistics
-- ================================

PRINT '=== INDEX USAGE ANALYSIS ==='
GO

-- Which indexes are being used?
-- (This will show usage after queries have been run)
SELECT
    OBJECT_NAME(s.object_id) AS TableName,
    i.name AS IndexName,
    s.user_seeks AS Seeks,
    s.user_scans AS Scans,
    s.user_lookups AS Lookups,
    s.user_updates AS Updates
FROM sys.dm_db_index_usage_stats s
JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE database_id = DB_ID('FreightDW')
  AND OBJECT_NAME(s.object_id) = 'Fact_Shipment'
ORDER BY (s.user_seeks + s.user_scans + s.user_lookups) DESC;
GO

-- ================================
-- Section 7: Index Maintenance Recommendations
-- ================================

PRINT '=== INDEX MAINTENANCE INFO ==='
GO

-- Fragmentation > 30% = REBUILD needed
-- Fragmentation 10-30% = REORGANIZE recommended
-- Fragmentation < 10% = No action needed

SELECT
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent AS FragmentationPercent,
    CASE
        WHEN ips.avg_fragmentation_in_percent >= 30 THEN 'REBUILD'
        WHEN ips.avg_fragmentation_in_percent >= 10 THEN 'REORGANIZE'
        ELSE 'HEALTHY'
    END AS MaintenanceAction
FROM sys.dm_db_index_physical_stats(DB_ID('FreightDW'), OBJECT_ID('Fact_Shipment'), NULL, NULL, 'LIMITED') ips
JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.index_level = 0
ORDER BY ips.avg_fragmentation_in_percent DESC;
GO

-- ================================
-- Section 8: Example Maintenance Scripts
-- ================================

-- REORGANIZE INDEX (light maintenance, online operation)
-- ALTER INDEX IX_FactShipment_CustomerSK ON dbo.Fact_Shipment REORGANIZE;

-- REBUILD INDEX (heavy maintenance, takes lock, faster)
-- ALTER INDEX IX_FactShipment_CustomerSK ON dbo.Fact_Shipment REBUILD;

-- REBUILD ALL INDEXES on table
-- ALTER INDEX ALL ON dbo.Fact_Shipment REBUILD;

PRINT '=== Module 4 Complete ==='
GO
