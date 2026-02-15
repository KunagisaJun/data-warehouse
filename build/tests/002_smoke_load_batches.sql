/*
002_smoke_load_batches.sql
Run in ETL DB.
Hardcoded paths (static).
*/

USE [ETL];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

PRINT '002_smoke_load_batches: begin';

DECLARE @Base NVARCHAR(4000) = N'X:\repos\data-warehouse\build\tests\data';

DECLARE
    @B1Customer NVARCHAR(4000) = @Base + N'\customer_batch1.xml',
    @B1Account  NVARCHAR(4000) = @Base + N'\account_batch1.xml',
    @B1Txn      NVARCHAR(4000) = @Base + N'\transaction_batch1.xml',
    @B2Customer NVARCHAR(4000) = @Base + N'\customer_batch2.xml',
    @B2Account  NVARCHAR(4000) = @Base + N'\account_batch2.xml',
    @B2Txn      NVARCHAR(4000) = @Base + N'\transaction_batch2.xml';

PRINT 'Using data folder: ' + @Base;

-- Batch 1
EXEC [ETL].[SourceToStage].[usp_LoadAll_FromVendor]
    @AccountXmlPath     = @B1Account,
    @CustomerXmlPath    = @B1Customer,
    @TransactionXmlPath = @B1Txn;

PRINT 'Batch1 load complete. Validating counts after batch1...';

-- Staging totals
IF (SELECT COUNT_BIG(1) FROM [Staging].[dbo].[customer]) <> 2
    RAISERROR('Batch1: Staging customer total expected 2', 16, 1);

IF (SELECT COUNT_BIG(1) FROM [Staging].[dbo].[account]) <> 2
    RAISERROR('Batch1: Staging account total expected 2', 16, 1);

IF (SELECT COUNT_BIG(1) FROM [Staging].[dbo].[transaction]) <> 3
    RAISERROR('Batch1: Staging transaction total expected 3', 16, 1);

-- ODS totals + current (active)
IF (SELECT COUNT_BIG(1) FROM [ODS].[dbo].[customer]) <> 2
    RAISERROR('Batch1: ODS customer total expected 2', 16, 1);

IF (SELECT COUNT_BIG(1) FROM [ODS].[dbo].[customer] WHERE [is_current]=1) <> 2
    RAISERROR('Batch1: ODS customer current expected 2', 16, 1);

IF (SELECT COUNT_BIG(1) FROM [ODS].[dbo].[customer] WHERE [is_current]=1 AND [is_deleted]=0) <> 2
    RAISERROR('Batch1: ODS customer current-active expected 2', 16, 1);

IF (SELECT COUNT_BIG(1) FROM [ODS].[dbo].[account]) <> 2
    RAISERROR('Batch1: ODS account total expected 2', 16, 1);

IF (SELECT COUNT_BIG(1) FROM [ODS].[dbo].[account] WHERE [is_current]=1) <> 2
    RAISERROR('Batch1: ODS account current expected 2', 16, 1);

IF (SELECT COUNT_BIG(1) FROM [ODS].[dbo].[account] WHERE [is_current]=1 AND [is_deleted]=0) <> 2
    RAISERROR('Batch1: ODS account current-active expected 2', 16, 1);

IF (SELECT COUNT_BIG(1) FROM [ODS].[dbo].[transaction]) <> 3
    RAISERROR('Batch1: ODS transaction total expected 3', 16, 1);

IF (SELECT COUNT_BIG(1) FROM [ODS].[dbo].[transaction] WHERE [is_current]=1) <> 3
    RAISERROR('Batch1: ODS transaction current expected 3', 16, 1);

IF (SELECT COUNT_BIG(1) FROM [ODS].[dbo].[transaction] WHERE [is_current]=1 AND [is_deleted]=0) <> 3
    RAISERROR('Batch1: ODS transaction current-active expected 3', 16, 1);

-- DWH totals
IF (SELECT COUNT_BIG(1) FROM [DWH].[dim].[Customer]) <> 2
    RAISERROR('Batch1: DWH dim.Customer total expected 2', 16, 1);

IF (SELECT COUNT_BIG(1) FROM [DWH].[dim].[Account]) <> 2
    RAISERROR('Batch1: DWH dim.Account total expected 2', 16, 1);

IF (SELECT COUNT_BIG(1) FROM [DWH].[dim].[Date]) = 0
    RAISERROR('Batch1: DWH dim.Date expected > 0', 16, 1);

IF (SELECT COUNT_BIG(1) FROM [DWH].[fact].[Transaction]) <> 0
    RAISERROR('Batch1: DWH fact.Transaction total expected 0', 16, 1);

PRINT 'Batch1 validation ok. Running batch2...';

-- Batch 2
EXEC [ETL].[SourceToStage].[usp_LoadAll_FromVendor]
    @AccountXmlPath     = @B2Account,
    @CustomerXmlPath    = @B2Customer,
    @TransactionXmlPath = @B2Txn;

PRINT 'Batch2 load complete. Validating SCD2 / deletes / final DWH contents...';

-- ODS totals + current
IF (SELECT COUNT_BIG(1) FROM [ODS].[dbo].[customer]) <> 2
    RAISERROR('Batch2: ODS customer total expected 2', 16, 1);

IF (SELECT COUNT_BIG(1) FROM [ODS].[dbo].[customer] WHERE [is_current]=1) <> 2
    RAISERROR('Batch2: ODS customer current expected 2', 16, 1);

IF (SELECT COUNT_BIG(1) FROM [ODS].[dbo].[customer] WHERE [is_current]=1 AND [is_deleted]=1) <> 0
    RAISERROR('Batch2: ODS customer deleted-current expected 0', 16, 1);

IF (SELECT COUNT_BIG(1) FROM [ODS].[dbo].[account]) <> 3
    RAISERROR('Batch2: ODS account total expected 3', 16, 1);

-- FIXED: current should be 2 (one current row per account_number)
IF (SELECT COUNT_BIG(1) FROM [ODS].[dbo].[account] WHERE [is_current]=1) <> 2
    RAISERROR('Batch2: ODS account current expected 2', 16, 1);

IF (SELECT COUNT_BIG(1) FROM [ODS].[dbo].[account] WHERE [is_current]=1 AND [is_deleted]=1) <> 0
    RAISERROR('Batch2: ODS account deleted-current expected 0', 16, 1);

IF (SELECT COUNT_BIG(1) FROM [ODS].[dbo].[transaction]) <> 4
    RAISERROR('Batch2: ODS transaction total expected 4', 16, 1);

IF (SELECT COUNT_BIG(1) FROM [ODS].[dbo].[transaction] WHERE [is_current]=1) <> 4
    RAISERROR('Batch2: ODS transaction current expected 4', 16, 1);

IF (SELECT COUNT_BIG(1) FROM [ODS].[dbo].[transaction] WHERE [is_current]=1 AND [is_deleted]=1) <> 0
    RAISERROR('Batch2: ODS transaction deleted-current expected 0', 16, 1);

-- DWH totals
IF (SELECT COUNT_BIG(1) FROM [DWH].[dim].[Customer]) <> 2
    RAISERROR('Batch2: DWH dim.Customer total expected 2', 16, 1);

IF (SELECT COUNT_BIG(1) FROM [DWH].[dim].[Account]) <> 3
    RAISERROR('Batch2: DWH dim.Account total expected 3', 16, 1);

IF (SELECT COUNT_BIG(1) FROM [DWH].[fact].[Transaction]) <> 0
    RAISERROR('Batch2: DWH fact.Transaction total expected 0', 16, 1);

PRINT '002_smoke_load_batches: ok';

SELECT
    (SELECT COUNT_BIG(1) FROM [DWH].[dim].[Customer])     AS dwh_dim_customer_rows,
    (SELECT COUNT_BIG(1) FROM [DWH].[dim].[Account])      AS dwh_dim_account_rows,
    (SELECT COUNT_BIG(1) FROM [DWH].[fact].[Transaction]) AS dwh_fact_transaction_rows,
    (SELECT COUNT_BIG(1) FROM [ODS].[dbo].[customer])     AS ods_customer_rows,
    (SELECT COUNT_BIG(1) FROM [ODS].[dbo].[account])      AS ods_account_rows,
    (SELECT COUNT_BIG(1) FROM [ODS].[dbo].[transaction])  AS ods_transaction_rows;
