CREATE TABLE [dim].[Account]
(
    [account_sk]      INT IDENTITY(1,1) NOT NULL,
    [account_number]  INT NOT NULL,
    [customer_number] INT NOT NULL,
    [effective_from]  DATETIME2(3) NOT NULL,
    [effective_to]    DATETIME2(3) NOT NULL,
    [is_current]      BIT NOT NULL,
    [is_deleted]      BIT NOT NULL,
    [row_hash]        VARBINARY(32) NULL,
    [account_type]    NVARCHAR(50) NULL,
    [opened_date]     DATE NULL,
    [status]          NVARCHAR(20) NULL,
    CONSTRAINT [PK_DWH_dim_Account] PRIMARY KEY CLUSTERED ([account_sk] ASC)
);
