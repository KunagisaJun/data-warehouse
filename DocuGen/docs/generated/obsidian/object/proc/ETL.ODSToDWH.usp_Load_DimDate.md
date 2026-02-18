---
tags:
  - sql
  - db/ETL
  - type/proc
docugen_key: ETL.ODSToDWH.usp_Load_DimDate
docugen_type: proc
docugen_db: ETL
---

# ETL.ODSToDWH.usp_Load_DimDate

- Schema: [[ETL.ODSToDWH]]
- Type: `Proc`

## Definition
```sql
CREATE PROCEDURE [ODSToDWH].[usp_Load_DimDate]
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @HasAnyRow AS BIT = 0;
    SELECT TOP (1) @HasAnyRow = 1
    FROM   [$(DWH)].[dim].[Date];
    IF @HasAnyRow = 1
        RETURN;
    DECLARE @StartDate AS DATE = CONVERT (DATE, '2000-01-01');
    DECLARE @EndDate AS DATE = CONVERT (DATE, '2035-12-31');
    DECLARE @d AS DATE = @StartDate;
    WHILE @d <= @EndDate
        BEGIN
            INSERT  INTO [$(DWH)].[dim].[Date] ([date_sk], [date_value], [year_number], [month_number], [day_number], [day_of_week], [day_name], [month_name], [quarter_number], [is_weekend])
            VALUES                            (CONVERT (INT, CONVERT (CHAR (8), @d, 112)), @d, DATEPART(YEAR, @d), DATEPART(MONTH, @d), DATEPART(DAY, @d), DATEPART(WEEKDAY, @d), DATENAME(WEEKDAY, @d), DATENAME(MONTH, @d), DATEPART(QUARTER, @d), CASE WHEN DATENAME(WEEKDAY, @d) IN (N'Saturday', N'Sunday') THEN 1 ELSE 0 END);
            SET @d = DATEADD(DAY, 1, @d);
        END
END
```

## zc-plugin-parent-node
- [[DWH.dim.Date]]
- [[ETL.ODSToDWH]]

## zc-plugin-parent-node-data

