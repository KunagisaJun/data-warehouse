---
tags:
  - sql
  - db/ETL
  - type/proc
docugen_key: ETL.SourceToStage.usp_Load_Transaction_FromXml
docugen_type: proc
docugen_db: ETL
---

# ETL.SourceToStage.usp_Load_Transaction_FromXml

- Schema: [[ETL.SourceToStage]]
- Type: `Proc`

## Definition
```sql
CREATE PROCEDURE [SourceToStage].[usp_Load_Transaction_FromXml]
@FilePath NVARCHAR (4000), @TruncateStage BIT=1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @TruncateStage = 1
        TRUNCATE TABLE [$(Staging)].[dbo].[transaction];
    DECLARE @x AS XML;
    DECLARE @sql AS NVARCHAR (MAX);
    SET @sql = N'SELECT @xOut = TRY_CONVERT(XML, BulkColumn)
          FROM OPENROWSET(BULK ''' + REPLACE(@FilePath, N'''', N'''''') + N''', SINGLE_BLOB) AS [B];';
    EXECUTE sys.sp_executesql @sql, N'@xOut XML OUTPUT', @xOut = @x OUTPUT;
    INSERT INTO [$(Staging)].[dbo].[transaction] ([source_file_name], [row_hash], [transaction_number], [account_number], [transaction_date], [amount], [description])
    SELECT @FilePath,
           HASHBYTES(N'SHA2_256', CONVERT (VARBINARY (MAX), CONCAT_WS(N'|', COALESCE (CONVERT (NVARCHAR (20), [r].[n].value('(account_number/text())[1]', 'INT')), N''), COALESCE (CONVERT (NVARCHAR (30), TRY_CONVERT (DATE, [r].[n].value('(transaction_date/text())[1]', 'NVARCHAR(30)')), 126), N''), COALESCE (CONVERT (NVARCHAR (60), TRY_CONVERT (DECIMAL (19, 4), [r].[n].value('(amount/text())[1]', 'NVARCHAR(60)'))), N''), COALESCE (CONVERT (NVARCHAR (400), NULLIF ([r].[n].value('(description/text())[1]', 'NVARCHAR(400)'), N'')), N'')))),
           [r].[n].value('(transaction_number/text())[1]', 'INT'),
           [r].[n].value('(account_number/text())[1]', 'INT'),
           TRY_CONVERT (DATE, [r].[n].value('(transaction_date/text())[1]', 'NVARCHAR(30)')),
           TRY_CONVERT (DECIMAL (19, 4), [r].[n].value('(amount/text())[1]', 'NVARCHAR(60)')),
           NULLIF ([r].[n].value('(description/text())[1]', 'NVARCHAR(400)'), N'')
    FROM   @x.nodes(N'/rows/row') AS [r]([n]);
END
```

## zc-plugin-parent-node
- [[ETL.SourceToStage]]
- [[Staging.dbo.transaction]]

## zc-plugin-parent-node-data

