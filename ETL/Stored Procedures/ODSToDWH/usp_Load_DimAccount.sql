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
        [$(ODS)].[dbo].[account].[account_number],
        [$(ODS)].[dbo].[account].[customer_number],
        [$(ODS)].[dbo].[account].[effective_from],
        [$(ODS)].[dbo].[account].[effective_to],
        [$(ODS)].[dbo].[account].[is_current],
        [$(ODS)].[dbo].[account].[is_deleted],
        [$(ODS)].[dbo].[account].[row_hash],
        [$(ODS)].[dbo].[account].[account_type],
        [$(ODS)].[dbo].[account].[opened_date],
        [$(ODS)].[dbo].[account].[status]
    FROM [$(ODS)].[dbo].[account]
    LEFT JOIN [$(DWH)].[dim].[Account]
        ON [$(DWH)].[dim].[Account].[account_number] = [$(ODS)].[dbo].[account].[account_number]
       AND [$(DWH)].[dim].[Account].[effective_from]  = [$(ODS)].[dbo].[account].[effective_from]
    WHERE [$(DWH)].[dim].[Account].[account_sk] IS NULL;
END
GO
