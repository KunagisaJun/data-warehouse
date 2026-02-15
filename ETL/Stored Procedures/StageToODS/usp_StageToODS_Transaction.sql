CREATE PROCEDURE [StageToODS].[usp_StageToODS_Transaction]
(
    @AsOfDts DATETIME2(7) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @AsOfDts IS NULL SET @AsOfDts = SYSUTCDATETIME();

    DECLARE @OpenEnded DATETIME2(7) = CONVERT(DATETIME2(7), '9999-12-31 23:59:59.9999999');

    -------------------------------------------------------------------------
    -- Source snapshot from Staging (dedupe to 1 row per business key)
    -------------------------------------------------------------------------
    DECLARE @src TABLE
    (
        transaction_number INT           NOT NULL PRIMARY KEY,
        row_hash           VARBINARY(32)  NULL,
        account_number     INT           NOT NULL,
        transaction_date   DATE          NULL,
        amount             DECIMAL(19,4) NULL,
        description        NVARCHAR(400) NULL
    );

    INSERT INTO @src (transaction_number, row_hash, account_number, transaction_date, amount, description)
    SELECT s.transaction_number, s.row_hash, s.account_number, s.transaction_date, s.amount, s.description
    FROM
    (
        SELECT
            t.*,
            ROW_NUMBER() OVER
            (
                PARTITION BY t.transaction_number
                ORDER BY t.load_dts DESC
            ) AS rn
        FROM [$(Staging)].[dbo].[transaction] AS t
    ) AS s
    WHERE s.rn = 1;

    -------------------------------------------------------------------------
    -- Current ODS rows
    -------------------------------------------------------------------------
    DECLARE @cur TABLE
    (
        transaction_number INT           NOT NULL PRIMARY KEY,
        row_hash           VARBINARY(32)  NULL,
        is_deleted         BIT           NOT NULL,
        effective_from     DATETIME2(7)  NOT NULL,
        effective_to       DATETIME2(7)  NOT NULL,
        account_number     INT           NOT NULL,
        transaction_date   DATE          NULL,
        amount             DECIMAL(19,4) NULL,
        description        NVARCHAR(400) NULL
    );

    INSERT INTO @cur
    (
        transaction_number, row_hash, is_deleted, effective_from, effective_to,
        account_number, transaction_date, amount, description
    )
    SELECT
        o.transaction_number, o.row_hash, o.is_deleted, o.effective_from, o.effective_to,
        o.account_number, o.transaction_date, o.amount, o.description
    FROM [$(ODS)].[dbo].[transaction] AS o
    WHERE o.is_current = 1;

    -------------------------------------------------------------------------
    -- Close changed current rows
    -------------------------------------------------------------------------
    UPDATE t
        SET t.effective_to = @AsOfDts,
            t.is_current   = 0
    FROM [$(ODS)].[dbo].[transaction] AS t
    INNER JOIN @src AS s
        ON s.transaction_number = t.transaction_number
    WHERE t.is_current = 1
      AND
      (
            (t.row_hash <> s.row_hash)
         OR (t.row_hash IS NULL AND s.row_hash IS NOT NULL)
         OR (t.row_hash IS NOT NULL AND s.row_hash IS NULL)
         OR (t.is_deleted = 1)
      );

    -------------------------------------------------------------------------
    -- Close missing from src (deletes)
    -------------------------------------------------------------------------
    UPDATE t
        SET t.effective_to = @AsOfDts,
            t.is_current   = 0
    FROM [$(ODS)].[dbo].[transaction] AS t
    LEFT JOIN @src AS s
        ON s.transaction_number = t.transaction_number
    WHERE t.is_current = 1
      AND s.transaction_number IS NULL;

    -------------------------------------------------------------------------
    -- Insert new deleted-current versions for deletes
    -------------------------------------------------------------------------
    INSERT INTO [$(ODS)].[dbo].[transaction]
    (
        effective_from, effective_to, is_current, is_deleted, row_hash,
        transaction_number, account_number, transaction_date, amount, description
    )
    SELECT
        @AsOfDts, @OpenEnded, 1, 1, c.row_hash,
        c.transaction_number, c.account_number, c.transaction_date, c.amount, c.description
    FROM @cur AS c
    LEFT JOIN @src AS s
        ON s.transaction_number = c.transaction_number
    WHERE s.transaction_number IS NULL
      AND c.is_deleted = 0;

    -------------------------------------------------------------------------
    -- Insert new and changed active rows
    -------------------------------------------------------------------------
    INSERT INTO [$(ODS)].[dbo].[transaction]
    (
        effective_from, effective_to, is_current, is_deleted, row_hash,
        transaction_number, account_number, transaction_date, amount, description
    )
    SELECT
        @AsOfDts, @OpenEnded, 1, 0, s.row_hash,
        s.transaction_number, s.account_number, s.transaction_date, s.amount, s.description
    FROM @src AS s
    LEFT JOIN @cur AS c
        ON c.transaction_number = s.transaction_number
    WHERE c.transaction_number IS NULL
       OR
       (
            (c.row_hash <> s.row_hash)
         OR (c.row_hash IS NULL AND s.row_hash IS NOT NULL)
         OR (c.row_hash IS NOT NULL AND s.row_hash IS NULL)
         OR (c.is_deleted = 1)
       );
END;
GO
