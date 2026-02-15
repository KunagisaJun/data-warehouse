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
        account_number  INT          NOT NULL PRIMARY KEY,
        row_hash        VARBINARY(32) NULL,
        is_deleted      BIT          NOT NULL,
        customer_number INT          NOT NULL,
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

    UPDATE [$(ODS)].[dbo].[account]
        SET
            [$(ODS)].[dbo].[account].[effective_to] = @AsOfDts,
            [$(ODS)].[dbo].[account].[is_current]   = 0
    FROM [$(ODS)].[dbo].[account]
    INNER JOIN [$(Staging)].[dbo].[account]
        ON [$(Staging)].[dbo].[account].[account_number] = [$(ODS)].[dbo].[account].[account_number]
    WHERE [$(ODS)].[dbo].[account].[is_current] = 1
      AND
      (
            ([$(ODS)].[dbo].[account].[row_hash] <> [$(Staging)].[dbo].[account].[row_hash])
         OR ([$(ODS)].[dbo].[account].[row_hash] IS NULL AND [$(Staging)].[dbo].[account].[row_hash] IS NOT NULL)
         OR ([$(ODS)].[dbo].[account].[row_hash] IS NOT NULL AND [$(Staging)].[dbo].[account].[row_hash] IS NULL)
         OR ([$(ODS)].[dbo].[account].[is_deleted] = 1)
      );

    UPDATE [$(ODS)].[dbo].[account]
        SET
            [$(ODS)].[dbo].[account].[effective_to] = @AsOfDts,
            [$(ODS)].[dbo].[account].[is_current]   = 0
    FROM [$(ODS)].[dbo].[account]
    LEFT JOIN [$(Staging)].[dbo].[account]
        ON [$(Staging)].[dbo].[account].[account_number] = [$(ODS)].[dbo].[account].[account_number]
    WHERE [$(ODS)].[dbo].[account].[is_current] = 1
      AND [$(Staging)].[dbo].[account].[account_number] IS NULL;

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
        @cur.[row_hash],
        @cur.[account_number],
        @cur.[customer_number],
        @cur.[account_type],
        @cur.[opened_date],
        @cur.[status]
    FROM @cur
    LEFT JOIN [$(Staging)].[dbo].[account]
        ON [$(Staging)].[dbo].[account].[account_number] = @cur.[account_number]
    WHERE [$(Staging)].[dbo].[account].[account_number] IS NULL
      AND @cur.[is_deleted] = 0;

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
        [$(Staging)].[dbo].[account].[row_hash],
        [$(Staging)].[dbo].[account].[account_number],
        [$(Staging)].[dbo].[account].[customer_number],
        [$(Staging)].[dbo].[account].[account_type],
        [$(Staging)].[dbo].[account].[opened_date],
        [$(Staging)].[dbo].[account].[status]
    FROM [$(Staging)].[dbo].[account]
    LEFT JOIN @cur
        ON @cur.[account_number] = [$(Staging)].[dbo].[account].[account_number]
    WHERE @cur.[account_number] IS NULL
       OR
       (
            (@cur.[row_hash] <> [$(Staging)].[dbo].[account].[row_hash])
         OR (@cur.[row_hash] IS NULL AND [$(Staging)].[dbo].[account].[row_hash] IS NOT NULL)
         OR (@cur.[row_hash] IS NOT NULL AND [$(Staging)].[dbo].[account].[row_hash] IS NULL)
         OR (@cur.[is_deleted] = 1)
       );
END;
GO
