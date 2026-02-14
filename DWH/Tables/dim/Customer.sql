CREATE TABLE [dim].[Customer]
(
    [customer_sk]     INT IDENTITY(1,1) NOT NULL,
    [customer_number] INT NOT NULL,
    [effective_from]  DATETIME2(3) NOT NULL,
    [effective_to]    DATETIME2(3) NOT NULL,
    [is_current]      BIT NOT NULL,
    [is_deleted]      BIT NOT NULL,
    [row_hash]        VARBINARY(32) NULL,
    [customer_name]   NVARCHAR(200) NULL,
    [email]           NVARCHAR(320) NULL,
    [phone]           NVARCHAR(50) NULL,
    CONSTRAINT [PK_DWH_dim_Customer] PRIMARY KEY CLUSTERED ([customer_sk] ASC)
);
