CREATE TABLE [dbo].[account]
(
    [rowid]            BIGINT IDENTITY(1,1) NOT NULL,
    [load_dts]         DATETIME2(3) NOT NULL CONSTRAINT [DF_stg_account_load_dts] DEFAULT (SYSUTCDATETIME()),
    [source_file_name] NVARCHAR(260) NULL,
    [row_hash]         VARBINARY(32) NULL,
    [account_number]   INT NOT NULL,
    [customer_number]  INT NOT NULL,
    [account_type]     NVARCHAR(50) NULL,
    [opened_date]      DATE NULL,
    [status]           NVARCHAR(20) NULL,
    CONSTRAINT [PK_stg_account] PRIMARY KEY CLUSTERED ([account_number] ASC)
);

