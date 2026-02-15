CREATE PROCEDURE [StageToODS].[usp_StageToODS_Account]
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
        account_number  INT           NOT NULL PRIMARY KEY,
        row_hash        VARBINARY(32) NULL,
        is_deleted      BIT           NOT NULL,
        customer_number INT           NOT NULL,
        account_type    NVARCHAR(50) NULL,
        opened_date     DATE         NULL,
        status          NVARCHAR(20) NULL
    );

    INSERT INTO @cur
    (
        account_number,
        row_hash,
        is_deleted,
        customer_number,
        account_type,
        opened_date,
        status
    )
    SELECT
        [$(ODS)].[dbo].[account].[account_number],
        [$(ODS)].[dbo].[account].[row_hash],
        [$(ODS)].[dbo].[account].[is_deleted],
        [$(ODS)].[dbo].[account].[customer_number],
        [$(ODS)].[dbo].[account].[account_type],
        [$(ODS)].[dbo].[account].[opened_date],
        [$(ODS)].[dbo].[account].[status]
    FROM [$(ODS)].[dbo].[account]
    WHERE [$(ODS)].[dbo].[account].[is_current] = 1;

    UPDATE [ods_account]
        SET
            [ods_account].[effective_to] = @AsOfDts,
            [ods_account].[is_current]   = 0
    FROM [$(ODS)].[dbo].[account] AS [ods_account]
    INNER JOIN [$(Staging)].[dbo].[account] AS [stg_account]
        ON [stg_account].[account_number] = [ods_account].[account_number]
    WHERE [ods_account].[is_current] = 1
      AND
      (
            ([ods_account].[row_hash] <> [stg_account].[row_hash])
         OR ([ods_account].[row_hash] IS NULL AND [stg_account].[row_hash] IS NOT NULL)
         OR ([ods_account].[row_hash] IS NOT NULL AND [stg_account].[row_hash] IS NULL)
         OR ([ods_account].[is_deleted] = 1)
      );

    UPDATE [ods_account]
        SET
            [ods_account].[effective_to] = @AsOfDts,
            [ods_account].[is_current]   = 0
    FROM [$(ODS)].[dbo].[account] AS [ods_account]
    LEFT JOIN [$(Staging)].[dbo].[account] AS [stg_account]
        ON [stg_account].[account_number] = [ods_account].[account_number]
    WHERE [ods_account].[is_current] = 1
      AND [stg_account].[account_number] IS NULL;

    INSERT INTO [$(ODS)].[dbo].[account]
    (
        effective_from,
        effective_to,
        is_current,
        is_deleted,
        row_hash,
        account_number,
        customer_number,
        account_type,
        opened_date,
        status
    )
    SELECT
        @AsOfDts,
        @OpenEnded,
        1,
        1,
        [tv_cur].[row_hash],
        [tv_cur].[account_number],
        [tv_cur].[customer_number],
        [tv_cur].[account_type],
        [tv_cur].[opened_date],
        [tv_cur].[status]
    FROM @cur AS [tv_cur]
    LEFT JOIN [$(Staging)].[dbo].[account] AS [stg_account]
        ON [stg_account].[account_number] = [tv_cur].[account_number]
    WHERE [stg_account].[account_number] IS NULL
      AND [tv_cur].[is_deleted] = 0;

    INSERT INTO [$(ODS)].[dbo].[account]
    (
        effective_from,
        effective_to,
        is_current,
        is_deleted,
        row_hash,
        account_number,
        customer_number,
        account_type,
        opened_date,
        status
    )
    SELECT
        @AsOfDts,
        @OpenEnded,
        1,
        0,
        [stg_account].[row_hash],
        [stg_account].[account_number],
        [stg_account].[customer_number],
        [stg_account].[account_type],
        [stg_account].[opened_date],
        [stg_account].[status]
    FROM [$(Staging)].[dbo].[account] AS [stg_account]
    LEFT JOIN @cur AS [tv_cur]
        ON [tv_cur].[account_number] = [stg_account].[account_number]
    WHERE [tv_cur].[account_number] IS NULL
       OR
       (
            ([tv_cur].[row_hash] <> [stg_account].[row_hash])
         OR ([tv_cur].[row_hash] IS NULL AND [stg_account].[row_hash] IS NOT NULL)
         OR ([tv_cur].[row_hash] IS NOT NULL AND [stg_account].[row_hash] IS NULL)
         OR ([tv_cur].[is_deleted] = 1)
       );
END;
GO
