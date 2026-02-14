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

        EXEC [ETL].[SourceToStage].[usp_Load_Customer_FromXml]
            @FilePath = @CustomerXmlPath,
            @TruncateStage = 1;

        EXEC [ETL].[SourceToStage].[usp_Load_Account_FromXml]
            @FilePath = @AccountXmlPath,
            @TruncateStage = 1;

        EXEC [ETL].[SourceToStage].[usp_Load_Transaction_FromXml]
            @FilePath = @TransactionXmlPath,
            @TruncateStage = 1;

        EXEC [ETL].[StageToODS].[usp_StageToODS_All];
        EXEC [ETL].[ODSToDWH].[usp_LoadAll_ODSToDWH];

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        DECLARE
            @ErrMsg NVARCHAR(2048) = ERROR_MESSAGE(),
            @ErrNum INT = ERROR_NUMBER(),
            @ErrState INT = ERROR_STATE(),
            @ErrSeverity INT = ERROR_SEVERITY(),
            @ErrLine INT = ERROR_LINE(),
            @ErrProc NVARCHAR(256) = ERROR_PROCEDURE();

        RAISERROR(
            N'Load failed. Number=%d, Severity=%d, State=%d, Line=%d, Proc=%s, Message=%s',
            @ErrSeverity, 1,
            @ErrNum, @ErrSeverity, @ErrState, @ErrLine, @ErrProc, @ErrMsg
        );
    END CATCH
END
