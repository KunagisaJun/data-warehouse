CREATE PROCEDURE [SourceToStage].[usp_Load_Account_FromXml]
(
    @FilePath NVARCHAR(4000),
    @TruncateStage BIT = 1
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @TruncateStage = 1
        TRUNCATE TABLE [$(Staging)].[dbo].[account];

    DECLARE @x XML;

    SELECT @x = TRY_CONVERT(XML, BulkColumn)
    FROM OPENROWSET(BULK @FilePath, SINGLE_BLOB) AS [src];

    ;WITH [rows] AS
    (
        SELECT
            [r].[n].value('(account_number/text())[1]', 'INT') AS [account_number],
            [r].[n].value('(customer_number/text())[1]', 'INT') AS [customer_number],
            NULLIF([r].[n].value('(account_type/text())[1]', 'NVARCHAR(50)'), N'') AS [account_type],
            TRY_CONVERT(DATE, [r].[n].value('(opened_date/text())[1]', 'NVARCHAR(30)')) AS [opened_date],
            NULLIF([r].[n].value('(status/text())[1]', 'NVARCHAR(20)'), N'') AS [status]
        FROM @x.nodes(N'/rows/row') AS [r]([n])
    )
    INSERT INTO [$(Staging)].[dbo].[account]
    (
        [source_file_name],
        [row_hash],
        [account_number],
        [customer_number],
        [account_type],
        [opened_date],
        [status]
    )
    SELECT
        @FilePath,
        HASHBYTES
        (
            N'SHA2_256',
            CONVERT(VARBINARY(MAX),
                CONCAT_WS(N'|',
                    COALESCE(CONVERT(NVARCHAR(20), [customer_number]), N''),
                    COALESCE(CONVERT(NVARCHAR(50), [account_type]), N''),
                    COALESCE(CONVERT(NVARCHAR(30), [opened_date], 126), N''),
                    COALESCE(CONVERT(NVARCHAR(20), [status]), N'')
                )
            )
        ),
        [account_number],
        [customer_number],
        [account_type],
        [opened_date],
        [status]
    FROM [rows];
END
