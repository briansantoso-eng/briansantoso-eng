--====================================
-- Dim_Date: Date Dimension Table
--====================================

-- 1. Create the Date Dimension Table
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


-- 2. Verify the table structure
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Dim_Date'
ORDER BY ORDINAL_POSITION;
GO


-- 3. Insert sample data into Dim_Date (for demonstration purposes)
INSERT INTO dbo.Dim_Date
    (DateKey, FullDate, DayOfWeek, DayName, DayOfMonth,
     Month, MonthName, Quarter, Year, IsWeekend)
VALUES
    (20240101, '2024-01-01', 1, 'Monday',   1, 1, 'January', 1, 2024, 0),
    (20240102, '2024-01-02', 2, 'Tuesday',  2, 1, 'January', 1, 2024, 0),
    (20240106, '2024-01-06', 6, 'Saturday', 6, 1, 'January', 1, 2024, 1);
GO

-- 4. Check what you just inserted
SELECT * FROM dbo.Dim_Date;
GO

-- 5. Clear the 3 test rows
DELETE FROM dbo.Dim_Date;
GO

-- 6. Populate all dates from 2022 to 2025
DECLARE @StartDate DATE = '2022-01-01';
DECLARE @EndDate   DATE = '2025-12-31';
DECLARE @Current   DATE = @StartDate;

-- Loop through each date and insert into the Dim_Date table
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

-- 7. Count total rows (should be 1,461)
SELECT COUNT(*) AS TotalDays FROM dbo.Dim_Date;
GO

-- 8. Spot check January 2024
SELECT * FROM dbo.Dim_Date
WHERE Year = 2024 AND Month = 1
ORDER BY DateKey;
GO