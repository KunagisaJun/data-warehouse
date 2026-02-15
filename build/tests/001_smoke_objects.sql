/*
001_smoke_objects.sql
Runs against DWH, but we connect to master and USE DWH explicitly.
Fail-fast: raises an error if expected objects are missing.
*/

USE [DWH];
GO

SET NOCOUNT ON;

PRINT '001_smoke_objects: begin';

IF DB_NAME() NOT IN (N'DWH', N'DWH_UAT')
BEGIN
    PRINT 'Warning: expected to run in DWH, but current DB is: ' + COALESCE(DB_NAME(), N'<NULL>');
END;

IF OBJECT_ID(N'[dim].[Customer]', N'U') IS NULL THROW 51001, 'Missing table [dim].[Customer]', 1;
IF OBJECT_ID(N'[dim].[Account]' , N'U') IS NULL THROW 51002, 'Missing table [dim].[Account]',  1;
IF OBJECT_ID(N'[dim].[Date]'    , N'U') IS NULL THROW 51003, 'Missing table [dim].[Date]',     1;
IF OBJECT_ID(N'[fact].[Transaction]', N'U') IS NULL THROW 51004, 'Missing table [fact].[Transaction]', 1;

SELECT
    DB_NAME() AS [db_name],
    (SELECT COUNT_BIG(1) FROM sys.tables)     AS [table_count],
    (SELECT COUNT_BIG(1) FROM sys.procedures) AS [proc_count];

PRINT '001_smoke_objects: ok';
GO
