CREATE TABLE [dbo].[account]
(
    [ods_rowid]        BIGINT IDENTITY(1,1) NOT NULL,
    [effective_from]   DATETIME2(3) NOT NULL,
    [effective_to]     DATETIME2(3) NOT NULL,
    [is_current]       BIT NOT NULL,
    [is_deleted]       BIT NOT NULL,
    [row_hash]         VARBINARY(32) NULL,
    [account_number]   INT NOT NULL,
    [customer_number]  INT NOT NULL,
    [account_type]     NVARCHAR(50) NULL,
    [opened_date]      DATE NULL,
    [status]           NVARCHAR(20) NULL,
    CONSTRAINT [PK_ods_account] PRIMARY KEY CLUSTERED ([ods_rowid] ASC)
);
