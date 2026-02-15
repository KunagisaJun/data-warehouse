CREATE PROCEDURE [StageToODS].[usp_StageToODS_Customer]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AsOfDts DATETIME2(3) =
        (SELECT MAX([load_dts]) FROM [$(Staging)].[dbo].[customer]);

    IF @AsOfDts IS NULL
        RETURN;

    DECLARE @OpenEnded DATETIME2(3) = CONVERT(DATETIME2(3), '9999-12-31 23:59:59.997');

    ;WITH [src] AS
    (
        SELECT
            [customer_number],
            [row_hash],
            [customer_name],
            [email],
            [phone]
        FROM [$(Staging)].[dbo].[customer]
    ),
    [cur] AS
    (
        SELECT
            [customer_number],
            [row_hash]
        FROM [$(ODS)].[dbo].[customer]
        WHERE [is_current] = 1
    )
    UPDATE [t]
        SET [t].[effective_to] = @AsOfDts,
            [t].[is_current]   = 0
    FROM [$(ODS)].[dbo].[customer] AS [t]
    INNER JOIN [src] AS [s]
        ON [s].[customer_number] = [t].[customer_number]
    WHERE [t].[is_current] = 1
      AND ( [t].[row_hash] <> [s].[row_hash] OR ([t].[row_hash] IS NULL AND [s].[row_hash] IS NOT NULL) OR ([t].[row_hash] IS NOT NULL AND [s].[row_hash] IS NULL) );

    INSERT INTO [$(ODS)].[dbo].[customer]
    (
        [effective_from],
        [effective_to],
        [is_current],
        [is_deleted],
        [row_hash],
        [customer_number],
        [customer_name],
        [email],
        [phone]
    )
    SELECT
        @AsOfDts,
        @OpenEnded,
        1,
        0,
        [s].[row_hash],
        [s].[customer_number],
        [s].[customer_name],
        [s].[email],
        [s].[phone]
    FROM [src] AS [s]
    LEFT JOIN [cur] AS [c]
        ON [c].[customer_number] = [s].[customer_number]
    WHERE [c].[customer_number] IS NULL
       OR ( [c].[row_hash] <> [s].[row_hash] OR ([c].[row_hash] IS NULL AND [s].[row_hash] IS NOT NULL) OR ([c].[row_hash] IS NOT NULL AND [s].[row_hash] IS NULL) );

    UPDATE [t]
        SET [t].[effective_to] = @AsOfDts,
            [t].[is_current]   = 0
    FROM [$(ODS)].[dbo].[customer] AS [t]
    LEFT JOIN [$(Staging)].[dbo].[customer] AS [s]
        ON [s].[customer_number] = [t].[customer_number]
    WHERE [t].[is_current] = 1
      AND [t].[is_deleted] = 0
      AND [s].[customer_number] IS NULL;

    INSERT INTO [$(ODS)].[dbo].[customer]
    (
        [effective_from],
        [effective_to],
        [is_current],
        [is_deleted],
        [row_hash],
        [customer_number],
        [customer_name],
        [email],
        [phone]
    )
    SELECT
        @AsOfDts,
        @OpenEnded,
        1,
        1,
        [t].[row_hash],
        [t].[customer_number],
        [t].[customer_name],
        [t].[email],
        [t].[phone]
    FROM [$(ODS)].[dbo].[customer] AS [t]
    LEFT JOIN [$(Staging)].[dbo].[customer] AS [s]
        ON [s].[customer_number] = [t].[customer_number]
    WHERE [t].[effective_to] = @AsOfDts
      AND [t].[is_current] = 0
      AND [t].[is_deleted] = 0
      AND [s].[customer_number] IS NULL;
END
