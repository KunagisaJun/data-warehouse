CREATE TABLE [fact].[Transaction]
(
    [transaction_number]  INT NOT NULL,
    [transaction_date_sk] INT NOT NULL,
    [account_sk]          INT NOT NULL,
    [customer_sk]         INT NOT NULL,
    [amount]              DECIMAL(19,4) NULL,
    [description]         NVARCHAR(400) NULL,
    [row_hash]            VARBINARY(32) NULL,
    CONSTRAINT [PK_DWH_fact_Transaction] PRIMARY KEY CLUSTERED ([transaction_number] ASC)
);
