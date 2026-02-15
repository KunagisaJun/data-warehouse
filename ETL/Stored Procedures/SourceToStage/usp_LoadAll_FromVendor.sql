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

        TRUNCATE TABLE [$(Staging)].[dbo].[transaction];
        TRUNCATE TABLE [$(Staging)].[dbo].[account];
        TRUNCATE TABLE [$(Staging)].[dbo].[customer];

        EXEC [ETL].[SourceToStage].[usp_Load_Customer_FromXml]
            @FilePath      = @CustomerXmlPath,
            @TruncateStage = 0;

        EXEC [ETL].[SourceToStage].[usp_Load_Account_FromXml]
            @FilePath      = @AccountXmlPath,
            @TruncateStage = 0;

        EXEC [ETL].[SourceToStage].[usp_Load_Transaction_FromXml]
            @FilePath      = @TransactionXmlPath,
            @TruncateStage = 0;

        EXEC [ETL].[StageToODS].[usp_StageToODS_All];
        EXEC [ETL].[ODSToDWH].[usp_LoadAll_ODSToDWH];

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO
