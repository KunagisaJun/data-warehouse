CREATE PROCEDURE [SourceToStage].[usp_Load_Account_FromXml]
(
    @FilePath NVARCHAR(4000),
    @TruncateStage BIT = 1
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @FilePath IS NULL OR LTRIM(RTRIM(@FilePath)) = N''
        THROW 50000, 'Account XML load: @FilePath is required.', 1;

    IF RIGHT(LOWER(@FilePath), 4) <> N'.xml'
        THROW 50000, 'Account XML load: @FilePath must end with .xml', 1;

    IF @FilePath LIKE N'%''%' OR @FilePath LIKE N'%;%' OR @FilePath LIKE N'%--%' OR @FilePath LIKE N'%/*%' OR @FilePath LIKE N'%*/%'
        THROW 50000, 'Account XML load: @FilePath contains invalid characters.', 1;

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
        THROW 50000, 'Account XML load: file does not exist (or SQL Server cannot access it).', 1;

    DECLARE @x XML;
    DECLARE @sql NVARCHAR(MAX) =
        N'SELECT @xOut = TRY_CONVERT(XML, BulkColumn)
          FROM OPENROWSET(BULK ''' + REPLACE(@FilePath, N'''', N'''''') + N''', SINGLE_BLOB) AS [B];';

    EXEC sys.sp_executesql
        @sql,
        N'@xOut XML OUTPUT',
        @xOut = @x OUTPUT;

    IF @x IS NULL
        THROW 50000, 'Account XML load: file could not be parsed as XML.', 1;

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
                    COALESCE(CONVERT(NVARCHAR(50), [account_type]),    N''),
                    COALESCE(CONVERT(NVARCHAR(30), [opened_date],126), N''),
                    COALESCE(CONVERT(NVARCHAR(20), [status]),          N'')
                )
            )
        ),
        [account_number],
        [customer_number],
        [account_type],
        [opened_date],
        [status]
    FROM [rows];
END;
GO
