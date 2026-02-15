CREATE PROCEDURE [StageToODS].[usp_StageToODS_Account]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AsOfDts DATETIME2(3) =
        (SELECT MAX([load_dts]) FROM [$(Staging)].[dbo].[account]);

    IF @AsOfDts IS NULL
        RETURN;

    DECLARE @OpenEnded DATETIME2(3) = CONVERT(DATETIME2(3), '9999-12-31 23:59:59.997');

    ;WITH [src] AS
    (
        SELECT
            [account_number],
            [row_hash],
            [customer_number],
            [account_type],
            [opened_date],
            [status]
        FROM [$(Staging)].[dbo].[account]
    ),
    [cur] AS
    (
        SELECT
            [account_number],
            [row_hash]
        FROM [$(ODS)].[dbo].[account]
        WHERE [is_current] = 1
    )
    UPDATE [t]
        SET [t].[effective_to] = @AsOfDts,
            [t].[is_current]   = 0
    FROM [$(ODS)].[dbo].[account] AS [t]
    INNER JOIN [src] AS [s]
        ON [s].[account_number] = [t].[account_number]
    WHERE [t].[is_current] = 1
      AND ( [t].[row_hash] <> [s].[row_hash] OR ([t].[row_hash] IS NULL AND [s].[row_hash] IS NOT NULL) OR ([t].[row_hash] IS NOT NULL AND [s].[row_hash] IS NULL) );

    INSERT INTO [$(ODS)].[dbo].[account]
    (
        [effective_from],
        [effective_to],
        [is_current],
        [is_deleted],
        [row_hash],
        [account_number],
        [customer_number],
        [account_type],
        [opened_date],
        [status]
    )
    SELECT
        @AsOfDts,
        @OpenEnded,
        1,
        0,
        [s].[row_hash],
        [s].[account_number],
        [s].[customer_number],
        [s].[account_type],
        [s].[opened_date],
        [s].[status]
    FROM [src] AS [s]
    LEFT JOIN [cur] AS [c]
        ON [c].[account_number] = [s].[account_number]
    WHERE [c].[account_number] IS NULL
       OR ( [c].[row_hash] <> [s].[row_hash] OR ([c].[row_hash] IS NULL AND [s].[row_hash] IS NOT NULL) OR ([c].[row_hash] IS NOT NULL AND [s].[row_hash] IS NULL) );

    UPDATE [t]
        SET [t].[effective_to] = @AsOfDts,
            [t].[is_current]   = 0
    FROM [$(ODS)].[dbo].[account] AS [t]
    LEFT JOIN [$(Staging)].[dbo].[account] AS [s]
        ON [s].[account_number] = [t].[account_number]
    WHERE [t].[is_current] = 1
      AND [t].[is_deleted] = 0
      AND [s].[account_number] IS NULL;

    INSERT INTO [$(ODS)].[dbo].[account]
    (
        [effective_from],
        [effective_to],
        [is_current],
        [is_deleted],
        [row_hash],
        [account_number],
        [customer_number],
        [account_type],
        [opened_date],
        [status]
    )
    SELECT
        @AsOfDts,
        @OpenEnded,
        1,
        1,
        [t].[row_hash],
        [t].[account_number],
        [t].[customer_number],
        [t].[account_type],
        [t].[opened_date],
        [t].[status]
    FROM [$(ODS)].[dbo].[account] AS [t]
    LEFT JOIN [$(Staging)].[dbo].[account] AS [s]
        ON [s].[account_number] = [t].[account_number]
    WHERE [t].[effective_to] = @AsOfDts
      AND [t].[is_current] = 0
      AND [t].[is_deleted] = 0
      AND [s].[account_number] IS NULL;
END
