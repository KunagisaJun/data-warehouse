---
tags:
  - sql
  - db/Staging
  - type/table
docugen_key: Staging.dbo.account
docugen_type: table
docugen_db: Staging
---

# Staging.dbo.account

- Schema: [[Staging.dbo]]
- Type: `Table`

## Definition
```sql
CREATE TABLE [dbo].[account] (
    [rowid]            BIGINT         IDENTITY (1, 1) NOT NULL,
    [load_dts]         DATETIME2 (3)  CONSTRAINT [DF_stg_account_load_dts] DEFAULT (SYSUTCDATETIME()) NOT NULL,
    [source_file_name] NVARCHAR (260) NULL,
    [row_hash]         VARBINARY (32) NULL,
    [account_number]   INT            NOT NULL,
    [customer_number]  INT            NOT NULL,
    [account_type]     NVARCHAR (50)  NULL,
    [opened_date]      DATE           NULL,
    [status]           NVARCHAR (20)  NULL,
    CONSTRAINT [PK_stg_account] PRIMARY KEY CLUSTERED ([account_number] ASC),
    CONSTRAINT [FK_stg_account_customer] FOREIGN KEY ([customer_number]) REFERENCES [dbo].[customer] ([customer_number])
)
```

## Columns
- [[Staging.dbo.account.account_number]]
- [[Staging.dbo.account.account_type]]
- [[Staging.dbo.account.customer_number]]
- [[Staging.dbo.account.load_dts]]
- [[Staging.dbo.account.opened_date]]
- [[Staging.dbo.account.rowid]]
- [[Staging.dbo.account.row_hash]]
- [[Staging.dbo.account.source_file_name]]
- [[Staging.dbo.account.status]]

## zc-plugin-parent-node
- [[Staging.dbo]]

