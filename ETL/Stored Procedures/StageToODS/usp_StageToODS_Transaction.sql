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

    UPDATE [ods_transaction]
        SET
            [ods_transaction].[effective_to] = @AsOfDts,
            [ods_transaction].[is_current]   = 0
    FROM [$(ODS)].[dbo].[transaction] AS [ods_transaction]
    INNER JOIN [$(Staging)].[dbo].[transaction] AS [stg_transaction]
        ON [stg_transaction].[transaction_number] = [ods_transaction].[transaction_number]
    WHERE [ods_transaction].[is_current] = 1
      AND
      (
            ([ods_transaction].[row_hash] <> [stg_transaction].[row_hash])
         OR ([ods_transaction].[row_hash] IS NULL AND [stg_transaction].[row_hash] IS NOT NULL)
         OR ([ods_transaction].[row_hash] IS NOT NULL AND [stg_transaction].[row_hash] IS NULL)
         OR ([ods_transaction].[is_deleted] = 1)
      );

    UPDATE [ods_transaction]
        SET
            [ods_transaction].[effective_to] = @AsOfDts,
            [ods_transaction].[is_current]   = 0
    FROM [$(ODS)].[dbo].[transaction] AS [ods_transaction]
    LEFT JOIN [$(Staging)].[dbo].[transaction] AS [stg_transaction]
        ON [stg_transaction].[transaction_number] = [ods_transaction].[transaction_number]
    WHERE [ods_transaction].[is_current] = 1
      AND [stg_transaction].[transaction_number] IS NULL;

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
        [tv_cur].[row_hash],
        [tv_cur].[transaction_number],
        [tv_cur].[account_number],
        [tv_cur].[transaction_date],
        [tv_cur].[amount],
        [tv_cur].[description]
    FROM @cur AS [tv_cur]
    LEFT JOIN [$(Staging)].[dbo].[transaction] AS [stg_transaction]
        ON [stg_transaction].[transaction_number] = [tv_cur].[transaction_number]
    WHERE [stg_transaction].[transaction_number] IS NULL
      AND [tv_cur].[is_deleted] = 0;

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
        [stg_transaction].[row_hash],
        [stg_transaction].[transaction_number],
        [stg_transaction].[account_number],
        [stg_transaction].[transaction_date],
        [stg_transaction].[amount],
        [stg_transaction].[description]
    FROM [$(Staging)].[dbo].[transaction] AS [stg_transaction]
    LEFT JOIN @cur AS [tv_cur]
        ON [tv_cur].[transaction_number] = [stg_transaction].[transaction_number]
    WHERE [tv_cur].[transaction_number] IS NULL
       OR
       (
            ([tv_cur].[row_hash] <> [stg_transaction].[row_hash])
         OR ([tv_cur].[row_hash] IS NULL AND [stg_transaction].[row_hash] IS NOT NULL)
         OR ([tv_cur].[row_hash] IS NOT NULL AND [stg_transaction].[row_hash] IS NULL)
         OR ([tv_cur].[is_deleted] = 1)
       );
END;
GO
