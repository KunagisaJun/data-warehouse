CREATE PROCEDURE [SourceToStage].[usp_LoadAll_FromVendor]
(
    @AccountXmlPath     NVARCHAR(4000),
    @CustomerXmlPath    NVARCHAR(4000),
    @TransactionXmlPath NVARCHAR(4000)
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        --------------------------------------------------------------------
        -- Clear staging tables safely (no FK drop, no TRUNCATE)
        -- Child -> Parent order to satisfy FKs
        --------------------------------------------------------------------
        DELETE FROM [$(Staging)].[dbo].[transaction];
        DELETE FROM [$(Staging)].[dbo].[account];
        DELETE FROM [$(Staging)].[dbo].[customer];

        --------------------------------------------------------------------
        -- Load stage tables (Customer -> Account -> Transaction)
        --------------------------------------------------------------------
        EXEC [ETL].[SourceToStage].[usp_Load_Customer_FromXml]
            @FilePath      = @CustomerXmlPath,
            @TruncateStage = 0;

        EXEC [ETL].[SourceToStage].[usp_Load_Account_FromXml]
            @FilePath      = @AccountXmlPath,
            @TruncateStage = 0;

        EXEC [ETL].[SourceToStage].[usp_Load_Transaction_FromXml]
            @FilePath      = @TransactionXmlPath,
            @TruncateStage = 0;

        --------------------------------------------------------------------
        -- Downstream loads
        --------------------------------------------------------------------
        EXEC [ETL].[StageToODS].[usp_StageToODS_All];
        EXEC [ETL].[ODSToDWH].[usp_LoadAll_ODSToDWH];

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        -- Re-throw the original error so callers see the real Proc/Line/Msg.
        THROW;
    END CATCH
END;
GO
