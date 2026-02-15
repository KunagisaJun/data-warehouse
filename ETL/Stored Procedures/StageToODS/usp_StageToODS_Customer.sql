CREATE PROCEDURE [StageToODS].[usp_StageToODS_Customer]
(
    @AsOfDts DATETIME2(7) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @AsOfDts IS NULL
        SET @AsOfDts = SYSUTCDATETIME();

    DECLARE @OpenEnded DATETIME2(7) = CONVERT(DATETIME2(7), '9999-12-31 23:59:59.9999999');

    DECLARE @cur TABLE
    (
        customer_number INT          NOT NULL PRIMARY KEY,
        row_hash        VARBINARY(32) NULL,
        is_deleted      BIT          NOT NULL,
        customer_name   NVARCHAR(200) NULL,
        email           NVARCHAR(320) NULL,
        phone           NVARCHAR(50)  NULL
    );

    INSERT INTO @cur
    (
        customer_number,
        row_hash,
        is_deleted,
        customer_name,
        email,
        phone
    )
    SELECT
        [$(ODS)].[dbo].[customer].[customer_number],
        [$(ODS)].[dbo].[customer].[row_hash],
        [$(ODS)].[dbo].[customer].[is_deleted],
        [$(ODS)].[dbo].[customer].[customer_name],
        [$(ODS)].[dbo].[customer].[email],
        [$(ODS)].[dbo].[customer].[phone]
    FROM [$(ODS)].[dbo].[customer]
    WHERE [$(ODS)].[dbo].[customer].[is_current] = 1;

    UPDATE [$(ODS)].[dbo].[customer]
        SET
            [$(ODS)].[dbo].[customer].[effective_to] = @AsOfDts,
            [$(ODS)].[dbo].[customer].[is_current]   = 0
    FROM [$(ODS)].[dbo].[customer]
    INNER JOIN [$(Staging)].[dbo].[customer]
        ON [$(Staging)].[dbo].[customer].[customer_number] = [$(ODS)].[dbo].[customer].[customer_number]
    WHERE [$(ODS)].[dbo].[customer].[is_current] = 1
      AND
      (
            ([$(ODS)].[dbo].[customer].[row_hash] <> [$(Staging)].[dbo].[customer].[row_hash])
         OR ([$(ODS)].[dbo].[customer].[row_hash] IS NULL AND [$(Staging)].[dbo].[customer].[row_hash] IS NOT NULL)
         OR ([$(ODS)].[dbo].[customer].[row_hash] IS NOT NULL AND [$(Staging)].[dbo].[customer].[row_hash] IS NULL)
         OR ([$(ODS)].[dbo].[customer].[is_deleted] = 1)
      );

    UPDATE [$(ODS)].[dbo].[customer]
        SET
            [$(ODS)].[dbo].[customer].[effective_to] = @AsOfDts,
            [$(ODS)].[dbo].[customer].[is_current]   = 0
    FROM [$(ODS)].[dbo].[customer]
    LEFT JOIN [$(Staging)].[dbo].[customer]
        ON [$(Staging)].[dbo].[customer].[customer_number] = [$(ODS)].[dbo].[customer].[customer_number]
    WHERE [$(ODS)].[dbo].[customer].[is_current] = 1
      AND [$(Staging)].[dbo].[customer].[customer_number] IS NULL;

    INSERT INTO [$(ODS)].[dbo].[customer]
    (
        effective_from,
        effective_to,
        is_current,
        is_deleted,
        row_hash,
        customer_number,
        customer_name,
        email,
        phone
    )
    SELECT
        @AsOfDts,
        @OpenEnded,
        1,
        1,
        @cur.[row_hash],
        @cur.[customer_number],
        @cur.[customer_name],
        @cur.[email],
        @cur.[phone]
    FROM @cur
    LEFT JOIN [$(Staging)].[dbo].[customer]
        ON [$(Staging)].[dbo].[customer].[customer_number] = @cur.[customer_number]
    WHERE [$(Staging)].[dbo].[customer].[customer_number] IS NULL
      AND @cur.[is_deleted] = 0;

    INSERT INTO [$(ODS)].[dbo].[customer]
    (
        effective_from,
        effective_to,
        is_current,
        is_deleted,
        row_hash,
        customer_number,
        customer_name,
        email,
        phone
    )
    SELECT
        @AsOfDts,
        @OpenEnded,
        1,
        0,
        [$(Staging)].[dbo].[customer].[row_hash],
        [$(Staging)].[dbo].[customer].[customer_number],
        [$(Staging)].[dbo].[customer].[customer_name],
        [$(Staging)].[dbo].[customer].[email],
        [$(Staging)].[dbo].[customer].[phone]
    FROM [$(Staging)].[dbo].[customer]
    LEFT JOIN @cur
        ON @cur.[customer_number] = [$(Staging)].[dbo].[customer].[customer_number]
    WHERE @cur.[customer_number] IS NULL
       OR
       (
            (@cur.[row_hash] <> [$(Staging)].[dbo].[customer].[row_hash])
         OR (@cur.[row_hash] IS NULL AND [$(Staging)].[dbo].[customer].[row_hash] IS NOT NULL)
         OR (@cur.[row_hash] IS NOT NULL AND [$(Staging)].[dbo].[customer].[row_hash] IS NULL)
         OR (@cur.[is_deleted] = 1)
       );
END;
GO
