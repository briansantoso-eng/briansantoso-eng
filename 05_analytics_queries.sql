-- ================================
-- Module 5: Analytics Queries
-- Author: Brian Santoso
-- Date: July 2026
-- ================================
-- WHAT THIS FILE DOES:
-- Demonstrates 15+ business analytics queries
-- showing KPIs, trends, anomalies, and insights
-- ================================

USE FreightDW;
GO

SELECT '=== MODULE 5: ANALYTICS QUERIES ===' AS [Section];
GO

-- ================================
-- SECTION 1: REVENUE & PROFITABILITY
-- ================================

PRINT '=== 1. Total Revenue & Profit Analysis ==='
GO

SELECT
    COUNT(*) AS TotalShipments,
    SUM(ShipmentCost) AS TotalCost,
    SUM(Revenue) AS TotalRevenue,
    SUM(Revenue) - SUM(ShipmentCost) AS TotalProfit,
    ROUND(100.0 * (SUM(Revenue) - SUM(ShipmentCost)) / SUM(Revenue), 2) AS ProfitMarginPercent
FROM dbo.Fact_Shipment;
GO

-- ================================

SELECT '=== 2. Top 5 Customers by Revenue ===' AS [Section];
GO

SELECT TOP 5
    c.CustomerName,
    c.CreditRating,
    COUNT(fs.ShipmentSK) AS ShipmentCount,
    SUM(fs.Revenue) AS TotalRevenue,
    SUM(fs.Revenue) - SUM(fs.ShipmentCost) AS TotalProfit,
    ROUND(AVG(fs.Revenue), 2) AS AvgRevenuePerShipment
FROM dbo.Fact_Shipment fs
JOIN dbo.Dim_Customer c ON fs.CustomerSK = c.CustomerSK
GROUP BY c.CustomerName, c.CreditRating
ORDER BY TotalRevenue DESC;
GO

-- ================================

SELECT '=== 3. Customer Profitability Analysis ===' AS [Section];
GO

SELECT
    c.CustomerName,
    c.Country,
    COUNT(fs.ShipmentSK) AS ShipmentCount,
    SUM(fs.Revenue) AS TotalRevenue,
    SUM(fs.ShipmentCost) AS TotalCost,
    SUM(fs.Revenue) - SUM(fs.ShipmentCost) AS Profit,
    ROUND(100.0 * (SUM(fs.Revenue) - SUM(fs.ShipmentCost)) / SUM(fs.Revenue), 2) AS ProfitMarginPercent
FROM dbo.Fact_Shipment fs
JOIN dbo.Dim_Customer c ON fs.CustomerSK = c.CustomerSK
GROUP BY c.CustomerName, c.Country
ORDER BY Profit DESC;
GO

-- ================================
-- SECTION 2: CARRIER PERFORMANCE
-- ================================

SELECT '=== 4. Carrier Performance Dashboard ===' AS [Section];
GO

SELECT
    c.CarrierName,
    c.CarrierType,
    COUNT(fs.ShipmentSK) AS ShipmentCount,
    ROUND(AVG(fs.DaysInTransit), 1) AS AvgDaysInTransit,
    SUM(CASE WHEN fs.IsOnTime = 1 THEN 1 ELSE 0 END) AS OnTimeCount,
    ROUND(100.0 * SUM(CASE WHEN fs.IsOnTime = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS OnTimePercentage,
    SUM(fs.Revenue) AS TotalRevenue,
    ROUND(AVG(fs.Revenue), 2) AS AvgRevenuePerShipment
FROM dbo.Fact_Shipment fs
JOIN dbo.Dim_Carrier c ON fs.CarrierSK = c.CarrierSK
GROUP BY c.CarrierName, c.CarrierType
ORDER BY OnTimePercentage DESC;
GO

-- ================================

SELECT '=== 5. Delayed Shipments by Carrier ===' AS [Section];
GO

SELECT
    c.CarrierName,
    COUNT(fs.ShipmentSK) AS DelayedShipments,
    ROUND(AVG(CAST(fs.DaysInTransit AS FLOAT)), 1) AS AvgDaysDelayed,
    SUM(fs.Revenue) AS RevenueLost
FROM dbo.Fact_Shipment fs
JOIN dbo.Dim_Carrier c ON fs.CarrierSK = c.CarrierSK
WHERE fs.IsOnTime = 0
GROUP BY c.CarrierName
ORDER BY DelayedShipments DESC;
GO

-- ================================
-- SECTION 3: ROUTE & PORT ANALYSIS
-- ================================

SELECT '=== 6. Top Routes by Volume ===' AS [Section];
GO

SELECT TOP 10
    po.PortName AS OriginPort,
    pd.PortName AS DestinationPort,
    COUNT(fs.ShipmentSK) AS ShipmentCount,
    ROUND(SUM(fs.WeightKg), 0) AS TotalWeightKg,
    ROUND(SUM(fs.VolumeCbm), 1) AS TotalVolumeCbm,
    SUM(fs.Revenue) AS TotalRevenue
FROM dbo.Fact_Shipment fs
JOIN dbo.Dim_Port po ON fs.OriginPortSK = po.PortSK
JOIN dbo.Dim_Port pd ON fs.DestPortSK = pd.PortSK
GROUP BY po.PortName, pd.PortName
ORDER BY ShipmentCount DESC;
GO

-- ================================

SELECT '=== 7. Port Activity Analysis ===' AS [Section];
GO

SELECT
    p.PortName,
    p.PortType,
    p.Region,
    COUNT(DISTINCT CASE WHEN fs.OriginPortSK = p.PortSK THEN fs.ShipmentSK END) AS OutboundShipments,
    COUNT(DISTINCT CASE WHEN fs.DestPortSK = p.PortSK THEN fs.ShipmentSK END) AS InboundShipments,
    COUNT(DISTINCT fs.ShipmentSK) AS TotalShipments
FROM dbo.Dim_Port p
LEFT JOIN dbo.Fact_Shipment fs ON (fs.OriginPortSK = p.PortSK OR fs.DestPortSK = p.PortSK)
GROUP BY p.PortName, p.PortType, p.Region
ORDER BY TotalShipments DESC;
GO

-- ================================
-- SECTION 4: COMMODITY & PRODUCT ANALYSIS
-- ================================

SELECT '=== 8. Commodity Analysis ===' AS [Section];
GO

SELECT
    cm.CommodityName,
    cm.Category,
    COUNT(fs.ShipmentSK) AS ShipmentCount,
    ROUND(SUM(fs.WeightKg), 0) AS TotalWeightKg,
    ROUND(SUM(fs.VolumeCbm), 1) AS TotalVolumeCbm,
    ROUND(AVG(fs.DaysInTransit), 1) AS AvgDaysInTransit,
    SUM(fs.Revenue) AS TotalRevenue
FROM dbo.Fact_Shipment fs
JOIN dbo.Dim_Commodity cm ON fs.CommoditySK = cm.CommoditySK
GROUP BY cm.CommodityName, cm.Category
ORDER BY TotalRevenue DESC;
GO

-- ================================

SELECT '=== 9. Dangerous & Refrigerated Cargo Analysis ===' AS [Section];
GO

SELECT
    CASE WHEN cm.IsDangerous = 1 THEN 'Yes' ELSE 'No' END AS IsDangerous,
    CASE WHEN cm.RequiresRefrig = 1 THEN 'Yes' ELSE 'No' END AS RequiresRefrig,
    COUNT(fs.ShipmentSK) AS ShipmentCount,
    SUM(fs.Revenue) AS TotalRevenue,
    ROUND(AVG(fs.DaysInTransit), 1) AS AvgDaysInTransit
FROM dbo.Fact_Shipment fs
JOIN dbo.Dim_Commodity cm ON fs.CommoditySK = cm.CommoditySK
GROUP BY cm.IsDangerous, cm.RequiresRefrig
ORDER BY ShipmentCount DESC;
GO

-- ================================
-- SECTION 5: TIME-SERIES & TRENDS
-- ================================

SELECT '=== 10. Revenue Trend by Month ===' AS [Section];
GO

SELECT
    dd.Year,
    dd.Month,
    dd.MonthName,
    COUNT(fs.ShipmentSK) AS ShipmentCount,
    SUM(fs.Revenue) AS TotalRevenue,
    ROUND(AVG(fs.Revenue), 2) AS AvgRevenuePerShipment,
    SUM(fs.Revenue) - SUM(fs.ShipmentCost) AS Profit
FROM dbo.Fact_Shipment fs
JOIN dbo.Dim_Date dd ON fs.BookingDateSK = dd.DateKey
GROUP BY dd.Year, dd.Month, dd.MonthName
ORDER BY dd.Year, dd.Month;
GO

-- ================================

SELECT '=== 11. Shipment Volume Trend ===' AS [Section];
GO

SELECT
    dd.Year,
    dd.Quarter,
    COUNT(fs.ShipmentSK) AS ShipmentCount,
    ROUND(SUM(fs.WeightKg), 0) AS TotalWeightKg,
    ROUND(SUM(fs.VolumeCbm), 1) AS TotalVolumeCbm,
    SUM(fs.NumContainers) AS TotalContainers
FROM dbo.Fact_Shipment fs
JOIN dbo.Dim_Date dd ON fs.BookingDateSK = dd.DateKey
GROUP BY dd.Year, dd.Quarter
ORDER BY dd.Year, dd.Quarter;
GO

-- ================================
-- SECTION 6: SHIPMENT STATUS & ANOMALIES
-- ================================

SELECT '=== 12. Shipment Status Summary ===' AS [Section];
GO

SELECT
    ShipmentStatus,
    COUNT(*) AS Count,
    SUM(Revenue) AS TotalRevenue,
    ROUND(AVG(DaysInTransit), 1) AS AvgDaysInTransit,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM dbo.Fact_Shipment), 2) AS PercentageOfTotal
FROM dbo.Fact_Shipment
GROUP BY ShipmentStatus
ORDER BY Count DESC;
GO

-- ================================

SELECT '=== 13. On-Time Performance by Month ===' AS [Section];
GO

SELECT
    dd.Year,
    dd.MonthName,
    COUNT(*) AS TotalShipments,
    SUM(CASE WHEN fs.IsOnTime = 1 THEN 1 ELSE 0 END) AS OnTimeShipments,
    ROUND(100.0 * SUM(CASE WHEN fs.IsOnTime = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS OnTimePercentage
FROM dbo.Fact_Shipment fs
JOIN dbo.Dim_Date dd ON fs.BookingDateSK = dd.DateKey
GROUP BY dd.Year, dd.MonthName
ORDER BY dd.Year, dd.MonthName;
GO

-- ================================
-- SECTION 7: ADVANCED ANALYTICS
-- ================================

SELECT '=== 14. Average Transit Time by Route ===' AS [Section];
GO

SELECT TOP 10
    po.PortName AS Origin,
    pd.PortName AS Destination,
    COUNT(*) AS ShipmentCount,
    ROUND(AVG(CAST(fs.DaysInTransit AS FLOAT)), 1) AS AvgDaysInTransit,
    MIN(fs.DaysInTransit) AS MinDays,
    MAX(fs.DaysInTransit) AS MaxDays
FROM dbo.Fact_Shipment fs
JOIN dbo.Dim_Port po ON fs.OriginPortSK = po.PortSK
JOIN dbo.Dim_Port pd ON fs.DestPortSK = pd.PortSK
WHERE fs.DaysInTransit IS NOT NULL
GROUP BY po.PortName, pd.PortName
ORDER BY AvgDaysInTransit DESC;
GO

-- ================================

SELECT '=== 15. Customer Credit Rating Impact ===' AS [Section];
GO

SELECT
    c.CreditRating,
    COUNT(fs.ShipmentSK) AS ShipmentCount,
    SUM(fs.Revenue) AS TotalRevenue,
    ROUND(AVG(fs.Revenue), 2) AS AvgRevenuePerShipment,
    ROUND(100.0 * SUM(CASE WHEN fs.IsOnTime = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS OnTimePercentage,
    ROUND(AVG(CAST(fs.DaysInTransit AS FLOAT)), 1) AS AvgDaysInTransit
FROM dbo.Fact_Shipment fs
JOIN dbo.Dim_Customer c ON fs.CustomerSK = c.CustomerSK
GROUP BY c.CreditRating
ORDER BY CASE WHEN c.CreditRating = 'A' THEN 1 WHEN c.CreditRating = 'B' THEN 2 WHEN c.CreditRating = 'C' THEN 3 ELSE 4 END;
GO

-- ================================

SELECT '=== 16. Revenue per Container Analysis ===' AS [Section];
GO

SELECT
    CASE
        WHEN NumContainers = 0 THEN 'Air Freight (No Containers)'
        WHEN NumContainers = 1 THEN 'Single Container'
        WHEN NumContainers >= 2 THEN 'Multi-Container'
    END AS ContainerType,
    COUNT(*) AS ShipmentCount,
    ROUND(AVG(Revenue), 2) AS AvgRevenue,
    ROUND(AVG(CAST(WeightKg AS FLOAT) / NULLIF(NumContainers, 0)), 2) AS AvgWeightPerContainer,
    ROUND(AVG(CAST(VolumeCbm AS FLOAT) / NULLIF(NumContainers, 0)), 2) AS AvgVolumePerContainer
FROM dbo.Fact_Shipment
WHERE NumContainers > 0 OR (NumContainers = 0)  -- Include air freight
GROUP BY NumContainers
ORDER BY ShipmentCount DESC;
GO

-- ================================
-- SECTION 8: BUSINESS INSIGHTS
-- ================================

SELECT '=== 17. Profitability by Carrier & Customer Segment ===' AS [Section];
GO

SELECT TOP 10
    c.CarrierName,
    cust.CustomerType,
    COUNT(fs.ShipmentSK) AS ShipmentCount,
    SUM(fs.Revenue) - SUM(fs.ShipmentCost) AS Profit,
    ROUND(100.0 * (SUM(fs.Revenue) - SUM(fs.ShipmentCost)) / SUM(fs.Revenue), 2) AS ProfitMarginPercent
FROM dbo.Fact_Shipment fs
JOIN dbo.Dim_Carrier c ON fs.CarrierSK = c.CarrierSK
JOIN dbo.Dim_Customer cust ON fs.CustomerSK = cust.CustomerSK
GROUP BY c.CarrierName, cust.CustomerType
ORDER BY Profit DESC;
GO

-- ================================

SELECT '=== 18. In-Transit Shipments at Risk ===' AS [Section];
GO

SELECT
    fs.ShipmentID,
    c.CustomerName,
    car.CarrierName,
    po.PortName AS Origin,
    pd.PortName AS Destination,
    fs.DaysInTransit,
    CASE
        WHEN fs.DaysInTransit > 30 THEN 'High Risk'
        WHEN fs.DaysInTransit > 20 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS RiskLevel
FROM dbo.Fact_Shipment fs
JOIN dbo.Dim_Customer c ON fs.CustomerSK = c.CustomerSK
JOIN dbo.Dim_Carrier car ON fs.CarrierSK = car.CarrierSK
JOIN dbo.Dim_Port po ON fs.OriginPortSK = po.PortSK
JOIN dbo.Dim_Port pd ON fs.DestPortSK = pd.PortSK
WHERE fs.ShipmentStatus = 'In Transit'
ORDER BY fs.DaysInTransit DESC;
GO

SELECT '=== Module 5 Complete ===' AS [Section];
GO
