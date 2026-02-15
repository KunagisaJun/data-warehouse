CREATE PROCEDURE [StageToODS].[usp_StageToODS_Account]
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
        account_number  INT           NOT NULL PRIMARY KEY,
        row_hash        VARBINARY(32)  NULL,
        customer_number INT           NOT NULL,
        account_type    NVARCHAR(50)   NULL,
        opened_date     DATE          NULL,
        status          NVARCHAR(20)   NULL
    );

    INSERT INTO @src (account_number, row_hash, customer_number, account_type, opened_date, status)
    SELECT s.account_number, s.row_hash, s.customer_number, s.account_type, s.opened_date, s.status
    FROM
    (
        SELECT
            a.*,
            ROW_NUMBER() OVER
            (
                PARTITION BY a.account_number
                ORDER BY a.load_dts DESC
            ) AS rn
        FROM [$(Staging)].[dbo].[account] AS a
    ) AS s
    WHERE s.rn = 1;

    -------------------------------------------------------------------------
    -- Current ODS rows
    -------------------------------------------------------------------------
    DECLARE @cur TABLE
    (
        account_number  INT           NOT NULL PRIMARY KEY,
        row_hash        VARBINARY(32)  NULL,
        is_deleted      BIT           NOT NULL,
        effective_from  DATETIME2(7)  NOT NULL,
        effective_to    DATETIME2(7)  NOT NULL,
        customer_number INT           NOT NULL,
        account_type    NVARCHAR(50)  NULL,
        opened_date     DATE          NULL,
        status          NVARCHAR(20)  NULL
    );

    INSERT INTO @cur
    (
        account_number, row_hash, is_deleted, effective_from, effective_to,
        customer_number, account_type, opened_date, status
    )
    SELECT
        o.account_number, o.row_hash, o.is_deleted, o.effective_from, o.effective_to,
        o.customer_number, o.account_type, o.opened_date, o.status
    FROM [$(ODS)].[dbo].[account] AS o
    WHERE o.is_current = 1;

    -------------------------------------------------------------------------
    -- Close changed current rows (existing in src but hash differs)
    -------------------------------------------------------------------------
    UPDATE t
        SET t.effective_to = @AsOfDts,
            t.is_current   = 0
    FROM [$(ODS)].[dbo].[account] AS t
    INNER JOIN @src AS s
        ON s.account_number = t.account_number
    WHERE t.is_current = 1
      AND
      (
            (t.row_hash <> s.row_hash)
         OR (t.row_hash IS NULL AND s.row_hash IS NOT NULL)
         OR (t.row_hash IS NOT NULL AND s.row_hash IS NULL)
         OR (t.is_deleted = 1)
      );

    -------------------------------------------------------------------------
    -- Close rows missing from src (deletes)
    -------------------------------------------------------------------------
    UPDATE t
        SET t.effective_to = @AsOfDts,
            t.is_current   = 0
    FROM [$(ODS)].[dbo].[account] AS t
    LEFT JOIN @src AS s
        ON s.account_number = t.account_number
    WHERE t.is_current = 1
      AND s.account_number IS NULL;

    -------------------------------------------------------------------------
    -- Insert new "deleted current" versions for deletes
    -------------------------------------------------------------------------
    INSERT INTO [$(ODS)].[dbo].[account]
    (
        effective_from, effective_to, is_current, is_deleted, row_hash,
        account_number, customer_number, account_type, opened_date, status
    )
    SELECT
        @AsOfDts, @OpenEnded, 1, 1, c.row_hash,
        c.account_number, c.customer_number, c.account_type, c.opened_date, c.status
    FROM @cur AS c
    LEFT JOIN @src AS s
        ON s.account_number = c.account_number
    WHERE s.account_number IS NULL
      AND c.is_deleted = 0;

    -------------------------------------------------------------------------
    -- Insert new and changed active rows
    -------------------------------------------------------------------------
    INSERT INTO [$(ODS)].[dbo].[account]
    (
        effective_from, effective_to, is_current, is_deleted, row_hash,
        account_number, customer_number, account_type, opened_date, status
    )
    SELECT
        @AsOfDts, @OpenEnded, 1, 0, s.row_hash,
        s.account_number, s.customer_number, s.account_type, s.opened_date, s.status
    FROM @src AS s
    LEFT JOIN @cur AS c
        ON c.account_number = s.account_number
    WHERE c.account_number IS NULL
       OR
       (
            (c.row_hash <> s.row_hash)
         OR (c.row_hash IS NULL AND s.row_hash IS NOT NULL)
         OR (c.row_hash IS NOT NULL AND s.row_hash IS NULL)
         OR (c.is_deleted = 1)
       );
END;
GO
