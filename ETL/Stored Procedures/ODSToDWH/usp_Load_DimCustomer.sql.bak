CREATE PROCEDURE [ODSToDWH].[usp_Load_DimCustomer]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OpenEnded DATETIME2(3) = CONVERT(DATETIME2(3), '9999-12-31 23:59:59.997');

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
        [o].[customer_number],
        [o].[effective_from],
        [o].[effective_to],
        [o].[is_current],
        [o].[is_deleted],
        [o].[row_hash],
        [o].[customer_name],
        [o].[email],
        [o].[phone]
    FROM [$(ODS)].[dbo].[customer] AS [o]
    LEFT JOIN [$(DWH)].[dim].[Customer] AS [d]
        ON [d].[customer_number] = [o].[customer_number]
       AND [d].[effective_from]  = [o].[effective_from]
    WHERE [d].[customer_sk] IS NULL;
END
