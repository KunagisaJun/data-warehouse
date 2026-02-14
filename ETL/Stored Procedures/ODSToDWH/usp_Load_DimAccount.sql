CREATE PROCEDURE [ODSToDWH].[usp_Load_DimAccount]
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [$(DWH)].[dim].[Account]
    (
        [account_number],
        [customer_number],
        [effective_from],
        [effective_to],
        [is_current],
        [is_deleted],
        [row_hash],
        [account_type],
        [opened_date],
        [status]
    )
    SELECT
        [o].[account_number],
        [o].[customer_number],
        [o].[effective_from],
        [o].[effective_to],
        [o].[is_current],
        [o].[is_deleted],
        [o].[row_hash],
        [o].[account_type],
        [o].[opened_date],
        [o].[status]
    FROM [$(ODS)].[dbo].[account] AS [o]
    LEFT JOIN [$(DWH)].[dim].[Account] AS [d]
        ON [d].[account_number] = [o].[account_number]
       AND [d].[effective_from] = [o].[effective_from]
    WHERE [d].[account_sk] IS NULL;
END
