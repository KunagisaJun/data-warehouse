CREATE PROCEDURE [ODSToDWH].[usp_Load_FactTransaction]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @s TABLE
    (
        transaction_number    INT           NOT NULL PRIMARY KEY,
        transaction_date_sk   INT           NOT NULL,
        account_sk            INT           NOT NULL,
        customer_sk           INT           NOT NULL,
        amount                DECIMAL(19,4) NULL,
        description           NVARCHAR(400) NULL,
        row_hash              VARBINARY(32) NULL
    );

    INSERT INTO @s
    (
        transaction_number,
        transaction_date_sk,
        account_sk,
        customer_sk,
        amount,
        description,
        row_hash
    )
    SELECT
        [$(ODS)].[dbo].[transaction].[transaction_number],
        CONVERT(INT, CONVERT(CHAR(8), [$(ODS)].[dbo].[transaction].[transaction_date], 112)),
        [$(DWH)].[dim].[Account].[account_sk],
        [$(DWH)].[dim].[Customer].[customer_sk],
        [$(ODS)].[dbo].[transaction].[amount],
        [$(ODS)].[dbo].[transaction].[description],
        [$(ODS)].[dbo].[transaction].[row_hash]
    FROM [$(ODS)].[dbo].[transaction]
    INNER JOIN [$(DWH)].[dim].[Account]
        ON [$(DWH)].[dim].[Account].[account_number] = [$(ODS)].[dbo].[transaction].[account_number]
       AND [$(ODS)].[dbo].[transaction].[transaction_date] >= CONVERT(DATE, [$(DWH)].[dim].[Account].[effective_from])
       AND [$(ODS)].[dbo].[transaction].[transaction_date] <  CONVERT(DATE, [$(DWH)].[dim].[Account].[effective_to])
    INNER JOIN [$(DWH)].[dim].[Customer]
        ON [$(DWH)].[dim].[Customer].[customer_number] = [$(DWH)].[dim].[Account].[customer_number]
       AND [$(ODS)].[dbo].[transaction].[transaction_date] >= CONVERT(DATE, [$(DWH)].[dim].[Customer].[effective_from])
       AND [$(ODS)].[dbo].[transaction].[transaction_date] <  CONVERT(DATE, [$(DWH)].[dim].[Customer].[effective_to]);

    UPDATE [$(DWH)].[fact].[Transaction]
        SET
            [$(DWH)].[fact].[Transaction].[transaction_date_sk] = @s.[transaction_date_sk],
            [$(DWH)].[fact].[Transaction].[account_sk]          = @s.[account_sk],
            [$(DWH)].[fact].[Transaction].[customer_sk]         = @s.[customer_sk],
            [$(DWH)].[fact].[Transaction].[amount]              = @s.[amount],
            [$(DWH)].[fact].[Transaction].[description]         = @s.[description],
            [$(DWH)].[fact].[Transaction].[row_hash]            = @s.[row_hash]
    FROM [$(DWH)].[fact].[Transaction]
    INNER JOIN @s
        ON @s.[transaction_number] = [$(DWH)].[fact].[Transaction].[transaction_number]
    WHERE
            ([$(DWH)].[fact].[Transaction].[row_hash] <> @s.[row_hash])
         OR ([$(DWH)].[fact].[Transaction].[row_hash] IS NULL AND @s.[row_hash] IS NOT NULL)
         OR ([$(DWH)].[fact].[Transaction].[row_hash] IS NOT NULL AND @s.[row_hash] IS NULL);

    INSERT INTO [$(DWH)].[fact].[Transaction]
    (
        [transaction_number],
        [transaction_date_sk],
        [account_sk],
        [customer_sk],
        [amount],
        [description],
        [row_hash]
    )
    SELECT
        @s.[transaction_number],
        @s.[transaction_date_sk],
        @s.[account_sk],
        @s.[customer_sk],
        @s.[amount],
        @s.[description],
        @s.[row_hash]
    FROM @s
    LEFT JOIN [$(DWH)].[fact].[Transaction]
        ON [$(DWH)].[fact].[Transaction].[transaction_number] = @s.[transaction_number]
    WHERE [$(DWH)].[fact].[Transaction].[transaction_number] IS NULL;
END
GO
