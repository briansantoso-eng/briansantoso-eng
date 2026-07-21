-- ================================
-- Module 1: Create Database
-- Author: Brian Santoso
-- Date: June 2026
-- ================================
-- WHAT THIS FILE DOES:
-- 1. Creates the FreightDW database
-- 2. Creates Dim_Date dimension table
-- 3. Populates 1,461 days (2022-2025)
-- ================================

-- Step 1: Create the database (only if it doesn't already exist)
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'FreightDW')
    CREATE DATABASE FreightDW;
GO

-- Step 2: Use the newly created database
USE FreightDW;
GO

-- Step 3: Verify we are in the right database
SELECT DB_NAME() AS CurrentDatabase;
GO

-- ================================
-- Dim_Date: Date dimension table
-- ================================

-- Step 4: Create Dim_Date table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Dim_Date')
BEGIN
    CREATE TABLE dbo.Dim_Date (
        DateKey     INT          NOT NULL,
        FullDate    DATE         NOT NULL,
        DayOfWeek   TINYINT      NOT NULL,
        DayName     VARCHAR(10)  NOT NULL,
        DayOfMonth  TINYINT      NOT NULL,
        Month       TINYINT      NOT NULL,
        MonthName   VARCHAR(10)  NOT NULL,
        Quarter     TINYINT      NOT NULL,
        Year        SMALLINT     NOT NULL,
        IsWeekend   BIT          NOT NULL DEFAULT 0,

        CONSTRAINT PK_DimDate PRIMARY KEY (DateKey)
    );
    PRINT 'Dim_Date created successfully';
END
ELSE
    PRINT 'Dim_Date already exists - skipping';
GO

-- Step 5: Verify table structure
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Dim_Date'
ORDER BY ORDINAL_POSITION;
GO

-- ================================
-- Populate Dim_Date
-- ================================

-- Step 6: Clear any existing rows before populating
DELETE FROM dbo.Dim_Date;
GO

-- Step 7: Populate all dates from 2022 to 2025 using a WHILE loop
DECLARE @StartDate DATE = '2022-01-01';
DECLARE @EndDate   DATE = '2025-12-31';
DECLARE @Current   DATE = @StartDate;

WHILE @Current <= @EndDate
BEGIN
    INSERT INTO dbo.Dim_Date
        (DateKey, FullDate, DayOfWeek, DayName, DayOfMonth,
         Month, MonthName, Quarter, Year, IsWeekend)
    VALUES (
        CAST(FORMAT(@Current, 'yyyyMMdd') AS INT),
        @Current,
        DATEPART(WEEKDAY, @Current),
        DATENAME(WEEKDAY, @Current),
        DAY(@Current),
        MONTH(@Current),
        DATENAME(MONTH, @Current),
        DATEPART(QUARTER, @Current),
        YEAR(@Current),
        CASE WHEN DATEPART(WEEKDAY, @Current) IN (1, 7) THEN 1 ELSE 0 END
    );

    SET @Current = DATEADD(DAY, 1, @Current);
END;
GO

-- ================================
-- Verification queries
-- ================================

-- Step 8: Count total rows (should be 1,461)
SELECT COUNT(*) AS TotalDays FROM dbo.Dim_Date;
GO

-- Step 9: How many weekend days in each year?
SELECT Year, COUNT(*) AS WeekendDays
FROM dbo.Dim_Date
WHERE IsWeekend = 1
GROUP BY Year
ORDER BY Year;
GO

-- Step 10: Count of each day name (e.g. how many Mondays, Tuesdays, etc.)
SELECT DayName, COUNT(*) AS DayCount
FROM dbo.Dim_Date
GROUP BY DayName, DayOfWeek
ORDER BY DayOfWeek;
GO

-- Step 11: Quarters with fewer than 92 days
SELECT Year, Quarter, COUNT(*) AS DayCount
FROM dbo.Dim_Date
GROUP BY Year, Quarter
HAVING COUNT(*) < 92
ORDER BY Year, Quarter;
GO
