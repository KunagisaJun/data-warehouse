---
tags: [sql, db/ETL, type/proc]
docugen_key: "ETL.StageToODS.usp_StageToODS_Customer"
docugen_type: "proc"
docugen_db: "ETL"
---

# ETL.StageToODS.usp_StageToODS_Customer

- Schema: [[ETL.StageToODS]]
- Type: `Proc`

## Definition
```sql
CREATE PROCEDURE [StageToODS].[usp_StageToODS_Customer]
@AsOfDts DATETIME2 (7)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @AsOfDts IS NULL
        SET @AsOfDts = SYSUTCDATETIME();
    DECLARE @OpenEnded AS DATETIME2 (7) = CONVERT (DATETIME2 (7), '9999-12-31 23:59:59.9999999');
    DECLARE @cur TABLE (
        customer_number INT            NOT NULL PRIMARY KEY,
        row_hash        VARBINARY (32) NULL,
        is_deleted      BIT            NOT NULL,
        customer_name   NVARCHAR (200) NULL,
        email           NVARCHAR (320) NULL,
        phone           NVARCHAR (50)  NULL);
    INSERT INTO @cur (customer_number, row_hash, is_deleted, customer_name, email, phone)
    SELECT [$(ODS)].[dbo].[customer].[customer_number],
           [$(ODS)].[dbo].[customer].[row_hash],
           [$(ODS)].[dbo].[customer].[is_deleted],
           [$(ODS)].[dbo].[customer].[customer_name],
           [$(ODS)].[dbo].[customer].[email],
           [$(ODS)].[dbo].[customer].[phone]
    FROM   [$(ODS)].[dbo].[customer]
    WHERE  [$(ODS)].[dbo].[customer].[is_current] = 1;
    UPDATE [ods_customer]
    SET    [ods_customer].[effective_to] = @AsOfDts,
           [ods_customer].[is_current]   = 0
    FROM   [$(ODS)].[dbo].[customer] AS [ods_customer]
           INNER JOIN
           [$(Staging)].[dbo].[customer] AS [stg_customer]
           ON [stg_customer].[customer_number] = [ods_customer].[customer_number]
    WHERE  [ods_customer].[is_current] = 1
           AND (([ods_customer].[row_hash] <> [stg_customer].[row_hash])
                OR ([ods_customer].[row_hash] IS NULL
                    AND [stg_customer].[row_hash] IS NOT NULL)
                OR ([ods_customer].[row_hash] IS NOT NULL
                    AND [stg_customer].[row_hash] IS NULL)
                OR ([ods_customer].[is_deleted] = 1));
    UPDATE [ods_customer]
    SET    [ods_customer].[effective_to] = @AsOfDts,
           [ods_customer].[is_current]   = 0
    FROM   [$(ODS)].[dbo].[customer] AS [ods_customer]
           LEFT OUTER JOIN
           [$(Staging)].[dbo].[customer] AS [stg_customer]
           ON [stg_customer].[customer_number] = [ods_customer].[customer_number]
    WHERE  [ods_customer].[is_current] = 1
           AND [stg_customer].[customer_number] IS NULL;
    INSERT INTO [$(ODS)].[dbo].[customer] (effective_from, effective_to, is_current, is_deleted, row_hash, customer_number, customer_name, email, phone)
    SELECT @AsOfDts,
           @OpenEnded,
           1,
           1,
           [tv_cur].[row_hash],
           [tv_cur].[customer_number],
           [tv_cur].[customer_name],
           [tv_cur].[email],
           [tv_cur].[phone]
    FROM   @cur AS [tv_cur]
           LEFT OUTER JOIN
           [$(Staging)].[dbo].[customer] AS [stg_customer]
           ON [stg_customer].[customer_number] = [tv_cur].[customer_number]
    WHERE  [stg_customer].[customer_number] IS NULL
           AND [tv_cur].[is_deleted] = 0;
    INSERT INTO [$(ODS)].[dbo].[customer] (effective_from, effective_to, is_current, is_deleted, row_hash, customer_number, customer_name, email, phone)
    SELECT @AsOfDts,
           @OpenEnded,
           1,
           0,
           [stg_customer].[row_hash],
           [stg_customer].[customer_number],
           [stg_customer].[customer_name],
           [stg_customer].[email],
           [stg_customer].[phone]
    FROM   [$(Staging)].[dbo].[customer] AS [stg_customer]
           LEFT OUTER JOIN
           @cur AS [tv_cur]
           ON [tv_cur].[customer_number] = [stg_customer].[customer_number]
    WHERE  [tv_cur].[customer_number] IS NULL
           OR (([tv_cur].[row_hash] <> [stg_customer].[row_hash])
               OR ([tv_cur].[row_hash] IS NULL
                   AND [stg_customer].[row_hash] IS NOT NULL)
               OR ([tv_cur].[row_hash] IS NOT NULL
                   AND [stg_customer].[row_hash] IS NULL)
               OR ([tv_cur].[is_deleted] = 1));
END
```

## zc-plugin-parent-node
- [[ETL.StageToODS]]
- [[ODS.dbo.customer]]
- [[Staging.dbo.customer]]

## zc-plugin-parent-node-data
- [[Staging.dbo.customer]]

