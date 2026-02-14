CREATE TABLE [dbo].[customer]
(
    [rowid]            BIGINT IDENTITY(1,1) NOT NULL,
    [load_dts]         DATETIME2(3) NOT NULL CONSTRAINT [DF_stg_customer_load_dts] DEFAULT (SYSUTCDATETIME()),
    [source_file_name] NVARCHAR(260) NULL,
    [row_hash]         VARBINARY(32) NULL,
    [customer_number]  INT NOT NULL,
    [customer_name]    NVARCHAR(200) NULL,
    [email]            NVARCHAR(320) NULL,
    [phone]            NVARCHAR(50) NULL,
    CONSTRAINT [PK_stg_customer] PRIMARY KEY CLUSTERED ([customer_number] ASC)
);
