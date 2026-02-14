CREATE TABLE [dbo].[transaction]
(
    [ods_rowid]          BIGINT IDENTITY(1,1) NOT NULL,
    [effective_from]     DATETIME2(3) NOT NULL,
    [effective_to]       DATETIME2(3) NOT NULL,
    [is_current]         BIT NOT NULL,
    [is_deleted]         BIT NOT NULL,

    [row_hash]           VARBINARY(32) NULL,

    [transaction_number] INT NOT NULL,
    [account_number]     INT NOT NULL,
    [transaction_date]   DATE NULL,
    [amount]             DECIMAL(19,4) NULL,
    [description]        NVARCHAR(400) NULL,

    CONSTRAINT [PK_ods_transaction] PRIMARY KEY CLUSTERED ([ods_rowid] ASC)
);
