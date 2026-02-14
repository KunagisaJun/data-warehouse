CREATE TABLE [dbo].[transaction]
(
    [rowid]              BIGINT IDENTITY(1,1) NOT NULL,
    [load_dts]           DATETIME2(3) NOT NULL CONSTRAINT [DF_stg_transaction_load_dts] DEFAULT (SYSUTCDATETIME()),
    [source_file_name]   NVARCHAR(260) NULL,
    [row_hash]           VARBINARY(32) NULL,
    [transaction_number] INT NOT NULL,
    [account_number]     INT NOT NULL,
    [transaction_date]   DATE NULL,
    [amount]             DECIMAL(19,4) NULL,
    [description]        NVARCHAR(400) NULL,
    CONSTRAINT [PK_stg_transaction] PRIMARY KEY CLUSTERED ([transaction_number] ASC),
    CONSTRAINT [FK_stg_transaction_account] FOREIGN KEY ([account_number]) REFERENCES [Staging].[dbo].[account]([account_number])
);
