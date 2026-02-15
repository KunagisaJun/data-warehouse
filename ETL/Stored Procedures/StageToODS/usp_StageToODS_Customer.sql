CREATE PROCEDURE [StageToODS].[usp_StageToODS_Customer]
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
        customer_number INT           NOT NULL PRIMARY KEY,
        row_hash        VARBINARY(32)  NULL,
        customer_name   NVARCHAR(200)  NULL,
        email           NVARCHAR(320)  NULL,
        phone           NVARCHAR(50)   NULL
    );

    INSERT INTO @src (customer_number, row_hash, customer_name, email, phone)
    SELECT s.customer_number, s.row_hash, s.customer_name, s.email, s.phone
    FROM
    (
        SELECT
            c.*,
            ROW_NUMBER() OVER
            (
                PARTITION BY c.customer_number
                ORDER BY c.load_dts DESC
            ) AS rn
        FROM [$(Staging)].[dbo].[customer] AS c
    ) AS s
    WHERE s.rn = 1;

    -------------------------------------------------------------------------
    -- Current ODS rows
    -------------------------------------------------------------------------
    DECLARE @cur TABLE
    (
        customer_number INT           NOT NULL PRIMARY KEY,
        row_hash        VARBINARY(32)  NULL,
        is_deleted      BIT           NOT NULL,
        effective_from  DATETIME2(7)  NOT NULL,
        effective_to    DATETIME2(7)  NOT NULL,
        customer_name   NVARCHAR(200) NULL,
        email           NVARCHAR(320) NULL,
        phone           NVARCHAR(50)  NULL
    );

    INSERT INTO @cur
    (
        customer_number, row_hash, is_deleted, effective_from, effective_to,
        customer_name, email, phone
    )
    SELECT
        o.customer_number, o.row_hash, o.is_deleted, o.effective_from, o.effective_to,
        o.customer_name, o.email, o.phone
    FROM [$(ODS)].[dbo].[customer] AS o
    WHERE o.is_current = 1;

    -------------------------------------------------------------------------
    -- Close changed current rows (existing in src but hash differs)
    -------------------------------------------------------------------------
    UPDATE t
        SET t.effective_to = @AsOfDts,
            t.is_current   = 0
    FROM [$(ODS)].[dbo].[customer] AS t
    INNER JOIN @src AS s
        ON s.customer_number = t.customer_number
    WHERE t.is_current = 1
      AND
      (
            (t.row_hash <> s.row_hash)
         OR (t.row_hash IS NULL AND s.row_hash IS NOT NULL)
         OR (t.row_hash IS NOT NULL AND s.row_hash IS NULL)
         OR (t.is_deleted = 1) -- if previously deleted, we'll re-insert active
      );

    -------------------------------------------------------------------------
    -- Close rows missing from src (deletes)
    -------------------------------------------------------------------------
    UPDATE t
        SET t.effective_to = @AsOfDts,
            t.is_current   = 0
    FROM [$(ODS)].[dbo].[customer] AS t
    LEFT JOIN @src AS s
        ON s.customer_number = t.customer_number
    WHERE t.is_current = 1
      AND s.customer_number IS NULL;

    -------------------------------------------------------------------------
    -- Insert new "deleted current" versions for deletes
    -------------------------------------------------------------------------
    INSERT INTO [$(ODS)].[dbo].[customer]
    (
        effective_from, effective_to, is_current, is_deleted, row_hash,
        customer_number, customer_name, email, phone
    )
    SELECT
        @AsOfDts, @OpenEnded, 1, 1, c.row_hash,
        c.customer_number, c.customer_name, c.email, c.phone
    FROM @cur AS c
    LEFT JOIN @src AS s
        ON s.customer_number = c.customer_number
    WHERE s.customer_number IS NULL
      AND c.is_deleted = 0; -- only create a delete version if it wasn't already deleted

    -------------------------------------------------------------------------
    -- Insert new and changed active rows
    -------------------------------------------------------------------------
    INSERT INTO [$(ODS)].[dbo].[customer]
    (
        effective_from, effective_to, is_current, is_deleted, row_hash,
        customer_number, customer_name, email, phone
    )
    SELECT
        @AsOfDts, @OpenEnded, 1, 0, s.row_hash,
        s.customer_number, s.customer_name, s.email, s.phone
    FROM @src AS s
    LEFT JOIN @cur AS c
        ON c.customer_number = s.customer_number
    WHERE c.customer_number IS NULL
       OR
       (
            (c.row_hash <> s.row_hash)
         OR (c.row_hash IS NULL AND s.row_hash IS NOT NULL)
         OR (c.row_hash IS NOT NULL AND s.row_hash IS NULL)
         OR (c.is_deleted = 1) -- revive from deleted
       );
END;
GO
