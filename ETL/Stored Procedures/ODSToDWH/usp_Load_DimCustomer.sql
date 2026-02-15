CREATE PROCEDURE [ODSToDWH].[usp_Load_DimCustomer]
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [$(DWH)].[dim].[Customer]
    (
        [customer_number],
        [effective_from],
        [effective_to],
        [is_current],
        [is_deleted],
        [row_hash],
        [customer_name],
        [email],
        [phone]
    )
    SELECT
        [$(ODS)].[dbo].[customer].[customer_number],
        [$(ODS)].[dbo].[customer].[effective_from],
        [$(ODS)].[dbo].[customer].[effective_to],
        [$(ODS)].[dbo].[customer].[is_current],
        [$(ODS)].[dbo].[customer].[is_deleted],
        [$(ODS)].[dbo].[customer].[row_hash],
        [$(ODS)].[dbo].[customer].[customer_name],
        [$(ODS)].[dbo].[customer].[email],
        [$(ODS)].[dbo].[customer].[phone]
    FROM [$(ODS)].[dbo].[customer]
    LEFT JOIN [$(DWH)].[dim].[Customer]
        ON [$(DWH)].[dim].[Customer].[customer_number] = [$(ODS)].[dbo].[customer].[customer_number]
       AND [$(DWH)].[dim].[Customer].[effective_from]   = [$(ODS)].[dbo].[customer].[effective_from]
    WHERE [$(DWH)].[dim].[Customer].[customer_sk] IS NULL;
END
GO
