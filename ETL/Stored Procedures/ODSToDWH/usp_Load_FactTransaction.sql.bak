CREATE PROCEDURE [ODSToDWH].[usp_Load_FactTransaction]
AS
BEGIN
    SET NOCOUNT ON;

    MERGE [$(DWH)].[fact].[Transaction] AS [t]
    USING
    (
        SELECT
            [o].[transaction_number],
            CONVERT(INT, CONVERT(CHAR(8), [o].[transaction_date], 112)) AS [transaction_date_sk],
            [da].[account_sk],
            [dc].[customer_sk],
            [o].[amount],
            [o].[description],
            [o].[row_hash]
        FROM [$(ODS)].[dbo].[transaction] AS [o]
        INNER JOIN [$(DWH)].[dim].[Account] AS [da]
            ON [da].[account_number] = [o].[account_number]
           AND [o].[transaction_date] >= CONVERT(DATE, [da].[effective_from])
           AND [o].[transaction_date] <  CONVERT(DATE, [da].[effective_to])
        INNER JOIN [$(DWH)].[dim].[Customer] AS [dc]
            ON [dc].[customer_number] = [da].[customer_number]
           AND [o].[transaction_date] >= CONVERT(DATE, [dc].[effective_from])
           AND [o].[transaction_date] <  CONVERT(DATE, [dc].[effective_to])
    ) AS [s]
        ON [t].[transaction_number] = [s].[transaction_number]
    WHEN MATCHED AND ( [t].[row_hash] <> [s].[row_hash] OR ([t].[row_hash] IS NULL AND [s].[row_hash] IS NOT NULL) OR ([t].[row_hash] IS NOT NULL AND [s].[row_hash] IS NULL) )
        THEN UPDATE SET
            [t].[transaction_date_sk] = [s].[transaction_date_sk],
            [t].[account_sk]          = [s].[account_sk],
            [t].[customer_sk]         = [s].[customer_sk],
            [t].[amount]              = [s].[amount],
            [t].[description]         = [s].[description],
            [t].[row_hash]            = [s].[row_hash]
    WHEN NOT MATCHED BY TARGET
        THEN INSERT
        (
            [transaction_number],
            [transaction_date_sk],
            [account_sk],
            [customer_sk],
            [amount],
            [description],
            [row_hash]
        )
        VALUES
        (
            [s].[transaction_number],
            [s].[transaction_date_sk],
            [s].[account_sk],
            [s].[customer_sk],
            [s].[amount],
            [s].[description],
            [s].[row_hash]
        );
END
