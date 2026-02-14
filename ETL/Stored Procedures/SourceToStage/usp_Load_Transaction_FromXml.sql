CREATE PROCEDURE [SourceToStage].[usp_Load_Transaction_FromXml]
(
    @FilePath NVARCHAR(4000),
    @TruncateStage BIT = 1
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @TruncateStage = 1
        TRUNCATE TABLE [$(Staging)].[dbo].[transaction];

    DECLARE @x XML;

    SELECT @x = TRY_CONVERT(XML, BulkColumn)
    FROM OPENROWSET(BULK @FilePath, SINGLE_BLOB) AS [src];

    ;WITH [rows] AS
    (
        SELECT
            [r].[n].value('(transaction_number/text())[1]', 'INT') AS [transaction_number],
            [r].[n].value('(account_number/text())[1]', 'INT') AS [account_number],
            TRY_CONVERT(DATE, [r].[n].value('(transaction_date/text())[1]', 'NVARCHAR(30)')) AS [transaction_date],
            TRY_CONVERT(DECIMAL(19,4), [r].[n].value('(amount/text())[1]', 'NVARCHAR(60)')) AS [amount],
            NULLIF([r].[n].value('(description/text())[1]', 'NVARCHAR(400)'), N'') AS [description]
        FROM @x.nodes(N'/rows/row') AS [r]([n])
    )
    INSERT INTO [$(Staging)].[dbo].[transaction]
    (
        [source_file_name],
        [row_hash],
        [transaction_number],
        [account_number],
        [transaction_date],
        [amount],
        [description]
    )
    SELECT
        @FilePath,
        HASHBYTES
        (
            N'SHA2_256',
            CONVERT(VARBINARY(MAX),
                CONCAT_WS(N'|',
                    COALESCE(CONVERT(NVARCHAR(20), [account_number]), N''),
                    COALESCE(CONVERT(NVARCHAR(30), [transaction_date], 126), N''),
                    COALESCE(CONVERT(NVARCHAR(60), [amount]), N''),
                    COALESCE(CONVERT(NVARCHAR(400), [description]), N'')
                )
            )
        ),
        [transaction_number],
        [account_number],
        [transaction_date],
        [amount],
        [description]
    FROM [rows];
END
