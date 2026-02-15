CREATE PROCEDURE [StageToODS].[usp_StageToODS_Transaction]
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
        transaction_number INT           NOT NULL PRIMARY KEY,
        row_hash           VARBINARY(32)  NULL,
        is_deleted         BIT           NOT NULL,
        account_number     INT           NOT NULL,
        transaction_date   DATE          NULL,
        amount             DECIMAL(19,4) NULL,
        description        NVARCHAR(400) NULL
    );

    INSERT INTO @cur
    (
        transaction_number,
        row_hash,
        is_deleted,
        account_number,
        transaction_date,
        amount,
        description
    )
    SELECT
        [$(ODS)].[dbo].[transaction].[transaction_number],
        [$(ODS)].[dbo].[transaction].[row_hash],
        [$(ODS)].[dbo].[transaction].[is_deleted],
        [$(ODS)].[dbo].[transaction].[account_number],
        [$(ODS)].[dbo].[transaction].[transaction_date],
        [$(ODS)].[dbo].[transaction].[amount],
        [$(ODS)].[dbo].[transaction].[description]
    FROM [$(ODS)].[dbo].[transaction]
    WHERE [$(ODS)].[dbo].[transaction].[is_current] = 1;

    UPDATE [$(ODS)].[dbo].[transaction]
        SET
            [$(ODS)].[dbo].[transaction].[effective_to] = @AsOfDts,
            [$(ODS)].[dbo].[transaction].[is_current]   = 0
    FROM [$(ODS)].[dbo].[transaction]
    INNER JOIN [$(Staging)].[dbo].[transaction]
        ON [$(Staging)].[dbo].[transaction].[transaction_number] = [$(ODS)].[dbo].[transaction].[transaction_number]
    WHERE [$(ODS)].[dbo].[transaction].[is_current] = 1
      AND
      (
            ([$(ODS)].[dbo].[transaction].[row_hash] <> [$(Staging)].[dbo].[transaction].[row_hash])
         OR ([$(ODS)].[dbo].[transaction].[row_hash] IS NULL AND [$(Staging)].[dbo].[transaction].[row_hash] IS NOT NULL)
         OR ([$(ODS)].[dbo].[transaction].[row_hash] IS NOT NULL AND [$(Staging)].[dbo].[transaction].[row_hash] IS NULL)
         OR ([$(ODS)].[dbo].[transaction].[is_deleted] = 1)
      );

    UPDATE [$(ODS)].[dbo].[transaction]
        SET
            [$(ODS)].[dbo].[transaction].[effective_to] = @AsOfDts,
            [$(ODS)].[dbo].[transaction].[is_current]   = 0
    FROM [$(ODS)].[dbo].[transaction]
    LEFT JOIN [$(Staging)].[dbo].[transaction]
        ON [$(Staging)].[dbo].[transaction].[transaction_number] = [$(ODS)].[dbo].[transaction].[transaction_number]
    WHERE [$(ODS)].[dbo].[transaction].[is_current] = 1
      AND [$(Staging)].[dbo].[transaction].[transaction_number] IS NULL;

    INSERT INTO [$(ODS)].[dbo].[transaction]
    (
        effective_from,
        effective_to,
        is_current,
        is_deleted,
        row_hash,
        transaction_number,
        account_number,
        transaction_date,
        amount,
        description
    )
    SELECT
        @AsOfDts,
        @OpenEnded,
        1,
        1,
        @cur.[row_hash],
        @cur.[transaction_number],
        @cur.[account_number],
        @cur.[transaction_date],
        @cur.[amount],
        @cur.[description]
    FROM @cur
    LEFT JOIN [$(Staging)].[dbo].[transaction]
        ON [$(Staging)].[dbo].[transaction].[transaction_number] = @cur.[transaction_number]
    WHERE [$(Staging)].[dbo].[transaction].[transaction_number] IS NULL
      AND @cur.[is_deleted] = 0;

    INSERT INTO [$(ODS)].[dbo].[transaction]
    (
        effective_from,
        effective_to,
        is_current,
        is_deleted,
        row_hash,
        transaction_number,
        account_number,
        transaction_date,
        amount,
        description
    )
    SELECT
        @AsOfDts,
        @OpenEnded,
        1,
        0,
        [$(Staging)].[dbo].[transaction].[row_hash],
        [$(Staging)].[dbo].[transaction].[transaction_number],
        [$(Staging)].[dbo].[transaction].[account_number],
        [$(Staging)].[dbo].[transaction].[transaction_date],
        [$(Staging)].[dbo].[transaction].[amount],
        [$(Staging)].[dbo].[transaction].[description]
    FROM [$(Staging)].[dbo].[transaction]
    LEFT JOIN @cur
        ON @cur.[transaction_number] = [$(Staging)].[dbo].[transaction].[transaction_number]
    WHERE @cur.[transaction_number] IS NULL
       OR
       (
            (@cur.[row_hash] <> [$(Staging)].[dbo].[transaction].[row_hash])
         OR (@cur.[row_hash] IS NULL AND [$(Staging)].[dbo].[transaction].[row_hash] IS NOT NULL)
         OR (@cur.[row_hash] IS NOT NULL AND [$(Staging)].[dbo].[transaction].[row_hash] IS NULL)
         OR (@cur.[is_deleted] = 1)
       );
END;
GO
