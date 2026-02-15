CREATE PROCEDURE [SourceToStage].[usp_Load_Customer_FromXml]
(
    @FilePath NVARCHAR(4000),
    @TruncateStage BIT = 1
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @TruncateStage = 1
        TRUNCATE TABLE [$(Staging)].[dbo].[customer];

    DECLARE @x XML;
    DECLARE @sql NVARCHAR(MAX);

    SET @sql =
        N'SELECT @xOut = TRY_CONVERT(XML, BulkColumn)
          FROM OPENROWSET(BULK ''' + REPLACE(@FilePath, N'''', N'''''') + N''', SINGLE_BLOB) AS [B];';

    EXEC sys.sp_executesql
        @sql,
        N'@xOut XML OUTPUT',
        @xOut = @x OUTPUT;

    INSERT INTO [$(Staging)].[dbo].[customer]
    (
        [source_file_name],
        [row_hash],
        [customer_number],
        [customer_name],
        [email],
        [phone]
    )
    SELECT
        @FilePath,
        HASHBYTES
        (
            N'SHA2_256',
            CONVERT(VARBINARY(MAX),
                CONCAT_WS(N'|',
                    COALESCE(CONVERT(NVARCHAR(200), NULLIF([r].[n].value('(customer_name/text())[1]', 'NVARCHAR(200)'), N'')), N''),
                    COALESCE(CONVERT(NVARCHAR(320), NULLIF([r].[n].value('(email/text())[1]', 'NVARCHAR(320)'), N'')),        N''),
                    COALESCE(CONVERT(NVARCHAR(50),  NULLIF([r].[n].value('(phone/text())[1]', 'NVARCHAR(50)'), N'')),         N'')
                )
            )
        ),
        [r].[n].value('(customer_number/text())[1]', 'INT'),
        NULLIF([r].[n].value('(customer_name/text())[1]', 'NVARCHAR(200)'), N''),
        NULLIF([r].[n].value('(email/text())[1]', 'NVARCHAR(320)'), N''),
        NULLIF([r].[n].value('(phone/text())[1]', 'NVARCHAR(50)'), N'')
    FROM @x.nodes(N'/rows/row') AS [r]([n]);
END;
GO
