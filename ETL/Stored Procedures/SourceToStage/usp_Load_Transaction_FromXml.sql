CREATE PROCEDURE [SourceToStage].[usp_Load_Transaction_FromXml]
(
    @FilePath NVARCHAR(4000),
    @TruncateStage BIT = 1
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @FilePath IS NULL OR LTRIM(RTRIM(@FilePath)) = N''
        THROW 50000, 'Transaction XML load: @FilePath is required.', 1;

    IF RIGHT(LOWER(@FilePath), 4) <> N'.xml'
        THROW 50000, 'Transaction XML load: @FilePath must end with .xml', 1;

    IF @FilePath LIKE N'%''%' OR @FilePath LIKE N'%;%' OR @FilePath LIKE N'%--%' OR @FilePath LIKE N'%/*%' OR @FilePath LIKE N'%*/%'
        THROW 50000, 'Transaction XML load: @FilePath contains invalid characters.', 1;

    DECLARE @fileExists INT = 0;
    BEGIN TRY
        DECLARE @t TABLE ([FileExists] INT, [IsDir] INT, [ParentExists] INT);
        INSERT INTO @t EXEC master..xp_fileexist @FilePath;
        SELECT @fileExists = COALESCE([FileExists], 0) FROM @t;
    END TRY
    BEGIN CATCH
        SET @fileExists = 0;
    END CATCH;

    IF @fileExists = 0
        THROW 50000, 'Transaction XML load: file does not exist (or SQL Server cannot access it).', 1;

    DECLARE @x XML;
    DECLARE @sql NVARCHAR(MAX) =
        N'SELECT @xOut = TRY_CONVERT(XML, BulkColumn)
          FROM OPENROWSET(BULK ''' + REPLACE(@FilePath, N'''', N'''''') + N''', SINGLE_BLOB) AS [B];';

    EXEC sys.sp_executesql
        @sql,
        N'@xOut XML OUTPUT',
        @xOut = @x OUTPUT;

    IF @x IS NULL
        THROW 50000, 'Transaction XML load: file could not be parsed as XML.', 1;

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
                    COALESCE(CONVERT(NVARCHAR(20), [account_number]),         N''),
                    COALESCE(CONVERT(NVARCHAR(30), [transaction_date],126),   N''),
                    COALESCE(CONVERT(NVARCHAR(60), [amount]),                 N''),
                    COALESCE(CONVERT(NVARCHAR(400), [description]),           N'')
                )
            )
        ),
        [transaction_number],
        [account_number],
        [transaction_date],
        [amount],
        [description]
    FROM [rows];
END;
GO
