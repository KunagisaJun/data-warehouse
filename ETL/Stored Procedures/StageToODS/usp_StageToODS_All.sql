CREATE PROCEDURE [StageToODS].[usp_StageToODS_All]
(
    @AsOfDts DATETIME2(7) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @AsOfDts IS NULL
        SET @AsOfDts = SYSUTCDATETIME();

    BEGIN TRY
        BEGIN TRAN;

        EXEC [ETL].[StageToODS].[usp_StageToODS_Customer]    @AsOfDts = @AsOfDts;
        EXEC [ETL].[StageToODS].[usp_StageToODS_Account]     @AsOfDts = @AsOfDts;
        EXEC [ETL].[StageToODS].[usp_StageToODS_Transaction] @AsOfDts = @AsOfDts;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO
