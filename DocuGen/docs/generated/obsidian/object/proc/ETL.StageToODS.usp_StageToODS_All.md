---
tags:
  - sql
  - db/ETL
  - type/proc
docugen_key: ETL.StageToODS.usp_StageToODS_All
docugen_type: proc
docugen_db: ETL
---

# ETL.StageToODS.usp_StageToODS_All

- Schema: [[ETL.StageToODS]]
- Type: `Proc`

## Definition
```sql
CREATE PROCEDURE [StageToODS].[usp_StageToODS_All]
@AsOfDts DATETIME2 (7)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @AsOfDts IS NULL
        SET @AsOfDts = SYSUTCDATETIME();
    BEGIN TRY
        BEGIN TRANSACTION;
        EXECUTE [ETL].[StageToODS].[usp_StageToODS_Customer] @AsOfDts = @AsOfDts;
        EXECUTE [ETL].[StageToODS].[usp_StageToODS_Account] @AsOfDts = @AsOfDts;
        EXECUTE [ETL].[StageToODS].[usp_StageToODS_Transaction] @AsOfDts = @AsOfDts;
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
- [[ETL.StageToODS]]
- [[ETL.StageToODS.usp_StageToODS_Account]]
- [[ETL.StageToODS.usp_StageToODS_Customer]]
- [[ETL.StageToODS.usp_StageToODS_Transaction]]

