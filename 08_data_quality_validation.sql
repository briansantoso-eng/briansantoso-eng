-- ================================
-- Module 8: Data Quality & Validation
-- Author: Brian Santoso
-- Date: July 2026
-- ================================
-- WHAT THIS FILE DOES:
-- 1. Validates data BEFORE loading to warehouse
-- 2. Detects orphaned records, duplicates, invalid values
-- 3. Ensures referential integrity
-- 4. Provides quality metrics and audit trail
-- ================================

USE FreightDW;
GO

SELECT '=== MODULE 8: DATA QUALITY & VALIDATION ===' AS [Section];
GO

-- ================================
-- SECTION 1: ORPHANED RECORDS
-- ================================
-- Find shipments where dimension records don't exist

SELECT '=== SECTION 1: ORPHANED RECORDS ===' AS [Section];
GO

-- Orphaned Customers
SELECT '--- Orphaned Customers (Shipments with missing Dim_Customer) ---' AS [Check];
SELECT
    fs.ShipmentID,
    fs.CustomerSK,
    'MISSING CUSTOMER' AS Issue
FROM dbo.Fact_Shipment fs
LEFT JOIN dbo.Dim_Customer dc ON fs.CustomerSK = dc.CustomerSK
WHERE dc.CustomerSK IS NULL;
GO

-- Orphaned Carriers
SELECT '--- Orphaned Carriers (Shipments with missing Dim_Carrier) ---' AS [Check];
SELECT
    fs.ShipmentID,
    fs.CarrierSK,
    'MISSING CARRIER' AS Issue
FROM dbo.Fact_Shipment fs
LEFT JOIN dbo.Dim_Carrier dca ON fs.CarrierSK = dca.CarrierSK
WHERE dca.CarrierSK IS NULL;
GO

-- Orphaned Ports
SELECT '--- Orphaned Ports (Shipments with missing Dim_Port) ---' AS [Check];
SELECT
    fs.ShipmentID,
    fs.OriginPortSK,
    fs.DestPortSK,
    'MISSING PORT' AS Issue
FROM dbo.Fact_Shipment fs
LEFT JOIN dbo.Dim_Port dp_origin ON fs.OriginPortSK = dp_origin.PortSK
LEFT JOIN dbo.Dim_Port dp_dest ON fs.DestPortSK = dp_dest.PortSK
WHERE dp_origin.PortSK IS NULL OR dp_dest.PortSK IS NULL;
GO

-- ================================
-- SECTION 2: INVALID VALUES
-- ================================
-- Find impossible or out-of-range values

SELECT '=== SECTION 2: INVALID VALUES ===' AS [Section];
GO

-- Negative Revenue
SELECT '--- Negative Revenue (Should Never Happen) ---' AS [Check];
SELECT
    ShipmentID,
    Revenue,
    ShipmentCost,
    'NEGATIVE REVENUE' AS Issue
FROM dbo.Fact_Shipment
WHERE Revenue < 0;
GO

-- Negative Cost
SELECT '--- Negative Shipment Cost ---' AS [Check];
SELECT
    ShipmentID,
    ShipmentCost,
    Revenue,
    'NEGATIVE COST' AS Issue
FROM dbo.Fact_Shipment
WHERE ShipmentCost < 0;
GO

-- Negative Weight/Volume
SELECT '--- Negative Weight or Volume ---' AS [Check];
SELECT
    ShipmentID,
    WeightKg,
    VolumeCbm,
    CASE WHEN WeightKg < 0 THEN 'NEGATIVE WEIGHT'
         WHEN VolumeCbm < 0 THEN 'NEGATIVE VOLUME' END AS Issue
FROM dbo.Fact_Shipment
WHERE WeightKg < 0 OR VolumeCbm < 0;
GO

-- Invalid Credit Ratings (not A, B, C, D)
SELECT '--- Invalid Credit Ratings ---' AS [Check];
SELECT
    CustomerSK,
    CustomerBK,
    CreditRating,
    'INVALID CREDIT RATING' AS Issue
FROM dbo.Dim_Customer
WHERE CreditRating NOT IN ('A', 'B', 'C', 'D', 'SUSPENDED')
  AND IsCurrent = 1;
GO

-- ================================
-- SECTION 3: NULL VALUES
-- ================================
-- Find missing required data

SELECT '=== SECTION 3: NULL VALUES IN REQUIRED FIELDS ===' AS [Section];
GO

-- Null Shipment Status
SELECT '--- Null Shipment Status ---' AS [Check];
SELECT COUNT(*) AS NullCount FROM dbo.Fact_Shipment WHERE ShipmentStatus IS NULL;
GO

-- Null Customer Name
SELECT '--- Null Customer Names (Current Only) ---' AS [Check];
SELECT COUNT(*) AS NullCount FROM dbo.Dim_Customer WHERE CustomerName IS NULL AND IsCurrent = 1;
GO

-- Null Carrier Name
SELECT '--- Null Carrier Names ---' AS [Check];
SELECT COUNT(*) AS NullCount FROM dbo.Dim_Carrier WHERE CarrierName IS NULL;
GO

-- ================================
-- SECTION 4: DUPLICATES
-- ================================
-- Find duplicate records in staging or dimensions

SELECT '=== SECTION 4: DUPLICATE DETECTION ===' AS [Section];
GO

-- Duplicate Customers in Staging
SELECT '--- Duplicate Customers in Staging ---' AS [Check];
SELECT
    SourceCustomerID,
    COUNT(*) AS DuplicateCount
FROM dbo.Stg_Customer
GROUP BY SourceCustomerID
HAVING COUNT(*) > 1
ORDER BY DuplicateCount DESC;
GO

-- Multiple Current Versions (SCD Type 2 Violation)
SELECT '--- SCD Type 2 Violation: Multiple Current Records per Customer ---' AS [Check];
SELECT
    CustomerBK,
    COUNT(*) AS CurrentVersionCount
FROM dbo.Dim_Customer
WHERE IsCurrent = 1
GROUP BY CustomerBK
HAVING COUNT(*) > 1;
GO

-- ================================
-- SECTION 5: DATA CONSISTENCY
-- ================================
-- Check cross-table consistency

SELECT '=== SECTION 5: DATA CONSISTENCY CHECKS ===' AS [Section];
GO

-- Arrival Before Departure
SELECT '--- Shipments Arriving Before Departure (Impossible) ---' AS [Check];
SELECT
    fs.ShipmentID,
    dd_dep.FullDate AS DepartureDate,
    dd_arr.FullDate AS ArrivalDate,
    'ARRIVAL BEFORE DEPARTURE' AS Issue
FROM dbo.Fact_Shipment fs
JOIN dbo.Dim_Date dd_dep ON fs.DepartureDateSK = dd_dep.DateKey
LEFT JOIN dbo.Dim_Date dd_arr ON fs.ArrivalDateSK = dd_arr.DateKey
WHERE dd_arr.FullDate < dd_dep.FullDate;
GO

-- Booking After Departure
SELECT '--- Shipments Booked After Departure ---' AS [Check];
SELECT
    fs.ShipmentID,
    dd_book.FullDate AS BookingDate,
    dd_dep.FullDate AS DepartureDate,
    'BOOKING AFTER DEPARTURE' AS Issue
FROM dbo.Fact_Shipment fs
JOIN dbo.Dim_Date dd_book ON fs.BookingDateSK = dd_book.DateKey
JOIN dbo.Dim_Date dd_dep ON fs.DepartureDateSK = dd_dep.DateKey
WHERE dd_book.FullDate > dd_dep.FullDate;
GO

-- Cost Greater Than Revenue (Loss on Every Shipment)
SELECT '--- Shipments Where Cost > Revenue (Unprofitable) ---' AS [Check];
SELECT TOP 10
    ShipmentID,
    ShipmentCost,
    Revenue,
    (Revenue - ShipmentCost) AS Profit
FROM dbo.Fact_Shipment
WHERE ShipmentCost > Revenue
ORDER BY (Revenue - ShipmentCost);
GO

-- ================================
-- SECTION 6: QUALITY SCORECARD
-- ================================
-- Overall data quality metrics

SELECT '=== SECTION 6: DATA QUALITY SCORECARD ===' AS [Section];
GO

SELECT
    'Total Shipments' AS Metric,
    COUNT(*) AS Count,
    'N/A' AS Quality_Status
FROM dbo.Fact_Shipment
UNION ALL
SELECT
    'Shipments with Valid Customers',
    COUNT(*) AS Count,
    CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM dbo.Fact_Shipment) THEN 'PASS' ELSE 'FAIL' END
FROM dbo.Fact_Shipment fs
JOIN dbo.Dim_Customer dc ON fs.CustomerSK = dc.CustomerSK
UNION ALL
SELECT
    'Shipments with Positive Revenue',
    COUNT(*) AS Count,
    CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM dbo.Fact_Shipment) THEN 'PASS' ELSE 'FAIL' END
FROM dbo.Fact_Shipment
WHERE Revenue > 0
UNION ALL
SELECT
    'Customers with Valid Credit Rating',
    COUNT(*) AS Count,
    CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM dbo.Dim_Customer WHERE IsCurrent = 1) THEN 'PASS' ELSE 'FAIL' END
FROM dbo.Dim_Customer
WHERE CreditRating IN ('A', 'B', 'C', 'D', 'SUSPENDED') AND IsCurrent = 1
UNION ALL
SELECT
    'SCD Type 2 Integrity (One Current per Customer)',
    COUNT(*) AS Count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM (
    SELECT CustomerBK, COUNT(*) as cnt
    FROM dbo.Dim_Customer
    WHERE IsCurrent = 1
    GROUP BY CustomerBK
    HAVING COUNT(*) > 1
) violations;
GO

-- ================================
-- SECTION 7: VALIDATION BEST PRACTICES
-- ================================

SELECT '=== SECTION 7: VALIDATION BEST PRACTICES ===' AS [Section];
GO

SELECT 'Best Practices for Data Quality:

1. RUN BEFORE LOADING
   - Check staging data BEFORE moving to warehouse
   - Quarantine bad records, don''t corrupt production

2. FAIL FAST
   - If critical validation fails (orphaned FK), stop the load
   - Log errors for investigation

3. TRACK METRICS
   - How many records passed/failed each check?
   - Trend quality over time

4. ALERT ON DEGRADATION
   - If 99% of records usually pass a check, alert when it drops to 85%
   - Indicates a problem in upstream system

5. DOCUMENT THRESHOLDS
   - What % failure is acceptable? (Usually 0%)
   - What column is "optional" vs "required"?

6. AUDIT TRAIL
   - Log every validation run
   - Track who ran it, when, what passed/failed
   - Helps with compliance (SOX, GDPR, etc.)
' AS [Best_Practices];
GO

PRINT '=== Module 8 Complete ==='
GO
