CREATE PROCEDURE [SourceToStage].[usp_Load_Customer_FromXml]
(
    @FilePath NVARCHAR(4000),
    @TruncateStage BIT = 1
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    ------------------------------------------------------------------------
    -- Validate path (defensive)
    ------------------------------------------------------------------------
    IF @FilePath IS NULL OR LTRIM(RTRIM(@FilePath)) = N''
        THROW 50000, 'Customer XML load: @FilePath is required.', 1;

    -- Require .xml extension (simple guard)
    IF RIGHT(LOWER(@FilePath), 4) <> N'.xml'
        THROW 50000, 'Customer XML load: @FilePath must end with .xml', 1;

    -- Block characters commonly used for injection or multi-statement tricks
    IF @FilePath LIKE N'%''%' OR @FilePath LIKE N'%;%' OR @FilePath LIKE N'%--%' OR @FilePath LIKE N'%/*%' OR @FilePath LIKE N'%*/%'
        THROW 50000, 'Customer XML load: @FilePath contains invalid characters.', 1;

    ------------------------------------------------------------------------
    -- Best-effort file existence check
    ------------------------------------------------------------------------
    DECLARE @fileExists INT = 0;
    BEGIN TRY
        DECLARE @t TABLE ([FileExists] INT, [IsDir] INT, [ParentExists] INT);
        INSERT INTO @t EXEC master..xp_fileexist @FilePath;
        SELECT @fileExists = COALESCE([FileExists], 0) FROM @t;
    END TRY
    BEGIN CATCH
        -- If xp_fileexist is blocked, proceed (OPENROWSET will error anyway)
        SET @fileExists = 0;
    END CATCH;

    IF @fileExists = 0
        THROW 50000, 'Customer XML load: file does not exist (or SQL Server cannot access it).', 1;

    ------------------------------------------------------------------------
    -- Read XML from file
    -- NOTE: OPENROWSET(BULK ...) requires a string literal, so minimal dynamic
    ------------------------------------------------------------------------
    DECLARE @x XML;
    DECLARE @sql NVARCHAR(MAX) =
        N'SELECT @xOut = TRY_CONVERT(XML, BulkColumn)
          FROM OPENROWSET(BULK ''' + REPLACE(@FilePath, N'''', N'''''') + N''', SINGLE_BLOB) AS [B];';

    BEGIN TRY
        EXEC sys.sp_executesql
            @sql,
            N'@xOut XML OUTPUT',
            @xOut = @x OUTPUT;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    IF @x IS NULL
        THROW 50000, 'Customer XML load: file could not be parsed as XML.', 1;

    ;WITH [rows] AS
    (
        SELECT
            [r].[n].value('(customer_number/text())[1]', 'INT') AS [customer_number],
            NULLIF([r].[n].value('(customer_name/text())[1]', 'NVARCHAR(200)'), N'') AS [customer_name],
            NULLIF([r].[n].value('(email/text())[1]', 'NVARCHAR(320)'), N'') AS [email],
            NULLIF([r].[n].value('(phone/text())[1]', 'NVARCHAR(50)'), N'') AS [phone]
        FROM @x.nodes(N'/rows/row') AS [r]([n])
    )
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
                    COALESCE(CONVERT(NVARCHAR(200), [customer_name]), N''),
                    COALESCE(CONVERT(NVARCHAR(320), [email]),         N''),
                    COALESCE(CONVERT(NVARCHAR(50),  [phone]),         N'')
                )
            )
        ),
        [customer_number],
        [customer_name],
        [email],
        [phone]
    FROM [rows];
END;
GO
