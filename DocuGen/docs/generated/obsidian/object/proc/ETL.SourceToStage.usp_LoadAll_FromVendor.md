---
tags:
  - sql
  - db/ETL
  - type/proc
docugen_key: ETL.SourceToStage.usp_LoadAll_FromVendor
docugen_type: proc
docugen_db: ETL
---

# ETL.SourceToStage.usp_LoadAll_FromVendor

- Schema: [[ETL.SourceToStage]]
- Type: `Proc`

## Definition
```sql
CREATE PROCEDURE [SourceToStage].[usp_LoadAll_FromVendor]
@AccountXmlPath NVARCHAR (4000), @CustomerXmlPath NVARCHAR (4000), @TransactionXmlPath NVARCHAR (4000)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        TRUNCATE TABLE [$(Staging)].[dbo].[transaction];
        TRUNCATE TABLE [$(Staging)].[dbo].[account];
        TRUNCATE TABLE [$(Staging)].[dbo].[customer];
        EXECUTE [ETL].[SourceToStage].[usp_Load_Customer_FromXml] @FilePath = @CustomerXmlPath, @TruncateStage = 0;
        EXECUTE [ETL].[SourceToStage].[usp_Load_Account_FromXml] @FilePath = @AccountXmlPath, @TruncateStage = 0;
        EXECUTE [ETL].[SourceToStage].[usp_Load_Transaction_FromXml] @FilePath = @TransactionXmlPath, @TruncateStage = 0;
        EXECUTE [ETL].[StageToODS].[usp_StageToODS_All] ;
        EXECUTE [ETL].[ODSToDWH].[usp_LoadAll_ODSToDWH] ;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
        THROW;
    END CATCH
END
```

## zc-plugin-parent-node
- [[ETL.ODSToDWH.usp_LoadAll_ODSToDWH]]
- [[ETL.SourceToStage]]
- [[ETL.SourceToStage.usp_Load_Account_FromXml]]
- [[ETL.SourceToStage.usp_Load_Customer_FromXml]]
- [[ETL.SourceToStage.usp_Load_Transaction_FromXml]]
- [[ETL.StageToODS.usp_StageToODS_All]]
- [[Staging.dbo.account]]
- [[Staging.dbo.customer]]
- [[Staging.dbo.transaction]]

## zc-plugin-parent-node-data

