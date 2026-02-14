CREATE PROCEDURE [ODSToDWH].[usp_Load_DimDate]
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM [$(DWH)].[dim].[Date])
        RETURN;

    DECLARE @StartDate DATE = CONVERT(DATE, '2000-01-01');
    DECLARE @EndDate   DATE = CONVERT(DATE, '2035-12-31');

    ;WITH [n] AS
    (
        SELECT TOP (DATEDIFF(DAY, @StartDate, DATEADD(DAY, 1, @EndDate)) )
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS [i]
        FROM [ETL].[sys].[all_objects] AS [a]
        CROSS JOIN [ETL].[sys].[all_objects] AS [b]
    ),
    [d] AS
    (
        SELECT DATEADD(DAY, [i], @StartDate) AS [dt]
        FROM [n]
    )
    INSERT INTO [$(DWH)].[dim].[Date]
    (
        [date_sk],
        [date_value],
        [year_number],
        [month_number],
        [day_number],
        [day_of_week],
        [day_name],
        [month_name],
        [quarter_number],
        [is_weekend]
    )
    SELECT
        CONVERT(INT, CONVERT(CHAR(8), [dt], 112)),
        [dt],
        DATEPART(YEAR, [dt]),
        DATEPART(MONTH, [dt]),
        DATEPART(DAY, [dt]),
        DATEPART(WEEKDAY, [dt]),
        DATENAME(WEEKDAY, [dt]),
        DATENAME(MONTH, [dt]),
        DATEPART(QUARTER, [dt]),
        CASE WHEN DATENAME(WEEKDAY, [dt]) IN (N'Saturday', N'Sunday') THEN 1 ELSE 0 END
    FROM [d];
END
