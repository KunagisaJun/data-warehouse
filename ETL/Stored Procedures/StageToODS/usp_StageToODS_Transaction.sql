CREATE PROCEDURE [StageToODS].[usp_StageToODS_Transaction]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AsOfDts DATETIME2(3) =
        (SELECT MAX([load_dts]) FROM [$(Staging)].[dbo].[transaction]);

    IF @AsOfDts IS NULL
        RETURN;

    DECLARE @OpenEnded DATETIME2(3) = CONVERT(DATETIME2(3), '9999-12-31 23:59:59.997');

    ;WITH [src] AS
    (
        SELECT
            [transaction_number],
            [row_hash],
            [account_number],
            [transaction_date],
            [amount],
            [description]
        FROM [$(Staging)].[dbo].[transaction]
    ),
    [cur] AS
    (
        SELECT
            [transaction_number],
            [row_hash]
        FROM [$(ODS)].[dbo].[transaction]
        WHERE [is_current] = 1
    )
    UPDATE [t]
        SET [t].[effective_to] = @AsOfDts,
            [t].[is_current]   = 0
    FROM [$(ODS)].[dbo].[transaction] AS [t]
    INNER JOIN [src] AS [s]
        ON [s].[transaction_number] = [t].[transaction_number]
    WHERE [t].[is_current] = 1
      AND ( [t].[row_hash] <> [s].[row_hash] OR ([t].[row_hash] IS NULL AND [s].[row_hash] IS NOT NULL) OR ([t].[row_hash] IS NOT NULL AND [s].[row_hash] IS NULL) );

    INSERT INTO [$(ODS)].[dbo].[transaction]
    (
        [effective_from],
        [effective_to],
        [is_current],
        [is_deleted],
        [row_hash],
        [transaction_number],
        [account_number],
        [transaction_date],
        [amount],
        [description]
    )
    SELECT
        @AsOfDts,
        @OpenEnded,
        1,
        0,
        [s].[row_hash],
        [s].[transaction_number],
        [s].[account_number],
        [s].[transaction_date],
        [s].[amount],
        [s].[description]
    FROM [src] AS [s]
    LEFT JOIN [cur] AS [c]
        ON [c].[transaction_number] = [s].[transaction_number]
    WHERE [c].[transaction_number] IS NULL
       OR ( [c].[row_hash] <> [s].[row_hash] OR ([c].[row_hash] IS NULL AND [s].[row_hash] IS NOT NULL) OR ([c].[row_hash] IS NOT NULL AND [s].[row_hash] IS NULL) );

    UPDATE [t]
        SET [t].[effective_to] = @AsOfDts,
            [t].[is_current]   = 0
    FROM [$(ODS)].[dbo].[transaction] AS [t]
    LEFT JOIN [$(Staging)].[dbo].[transaction] AS [s]
        ON [s].[transaction_number] = [t].[transaction_number]
    WHERE [t].[is_current] = 1
      AND [t].[is_deleted] = 0
      AND [s].[transaction_number] IS NULL;

    INSERT INTO [$(ODS)].[dbo].[transaction]
    (
        [effective_from],
        [effective_to],
        [is_current],
        [is_deleted],
        [row_hash],
        [transaction_number],
        [account_number],
        [transaction_date],
        [amount],
        [description]
    )
    SELECT
        @AsOfDts,
        @OpenEnded,
        1,
        1,
        [t].[row_hash],
        [t].[transaction_number],
        [t].[account_number],
        [t].[transaction_date],
        [t].[amount],
        [t].[description]
    FROM [$(ODS)].[dbo].[transaction] AS [t]
    LEFT JOIN [$(Staging)].[dbo].[transaction] AS [s]
        ON [s].[transaction_number] = [t].[transaction_number]
    WHERE [t].[effective_to] = @AsOfDts
      AND [t].[is_current] = 0
      AND [t].[is_deleted] = 0
      AND [s].[transaction_number] IS NULL;
END
