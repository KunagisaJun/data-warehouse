CREATE PROCEDURE [SourceToStage].[usp_Load_Account_FromXml]
(
    @FilePath NVARCHAR(4000),
    @TruncateStage BIT = 1
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @TruncateStage = 1
        TRUNCATE TABLE [$(Staging)].[dbo].[account];

    DECLARE @x XML;
    DECLARE @sql NVARCHAR(MAX);

    SET @sql =
        N'SELECT @xOut = TRY_CONVERT(XML, BulkColumn)
          FROM OPENROWSET(BULK ''' + REPLACE(@FilePath, N'''', N'''''') + N''', SINGLE_BLOB) AS [B];';

    EXEC sys.sp_executesql
        @sql,
        N'@xOut XML OUTPUT',
        @xOut = @x OUTPUT;

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
                    COALESCE(CONVERT(NVARCHAR(20),  [r].[n].value('(customer_number/text())[1]', 'INT')), N''),
                    COALESCE(CONVERT(NVARCHAR(50),  NULLIF([r].[n].value('(account_type/text())[1]', 'NVARCHAR(50)'), N'')), N''),
                    COALESCE(CONVERT(NVARCHAR(30),  TRY_CONVERT(DATE, [r].[n].value('(opened_date/text())[1]', 'NVARCHAR(30)')), 126), N''),
                    COALESCE(CONVERT(NVARCHAR(20),  NULLIF([r].[n].value('(status/text())[1]', 'NVARCHAR(20)'), N'')), N'')
                )
            )
        ),
        [r].[n].value('(account_number/text())[1]', 'INT'),
        [r].[n].value('(customer_number/text())[1]', 'INT'),
        NULLIF([r].[n].value('(account_type/text())[1]', 'NVARCHAR(50)'), N''),
        TRY_CONVERT(DATE, [r].[n].value('(opened_date/text())[1]', 'NVARCHAR(30)')),
        NULLIF([r].[n].value('(status/text())[1]', 'NVARCHAR(20)'), N'')
    FROM @x.nodes(N'/rows/row') AS [r]([n]);
END;
GO
