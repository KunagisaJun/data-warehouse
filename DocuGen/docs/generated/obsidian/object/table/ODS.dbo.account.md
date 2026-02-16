---
tags:
  - sql
  - db/ODS
  - type/table
docugen_key: ODS.dbo.account
docugen_type: table
docugen_db: ODS
---

# ODS.dbo.account

- Schema: [[ODS.dbo]]
- Type: `Table`

## Definition
```sql
CREATE TABLE [dbo].[account] (
    [ods_rowid]       BIGINT         IDENTITY (1, 1) NOT NULL,
    [effective_from]  DATETIME2 (3)  NOT NULL,
    [effective_to]    DATETIME2 (3)  NOT NULL,
    [is_current]      BIT            NOT NULL,
    [is_deleted]      BIT            NOT NULL,
    [row_hash]        VARBINARY (32) NULL,
    [account_number]  INT            NOT NULL,
    [customer_number] INT            NOT NULL,
    [account_type]    NVARCHAR (50)  NULL,
    [opened_date]     DATE           NULL,
    [status]          NVARCHAR (20)  NULL,
    CONSTRAINT [PK_ods_account] PRIMARY KEY CLUSTERED ([ods_rowid] ASC)
)
```

## Columns
- [[ODS.dbo.account.account_number]]
- [[ODS.dbo.account.account_type]]
- [[ODS.dbo.account.customer_number]]
- [[ODS.dbo.account.effective_from]]
- [[ODS.dbo.account.effective_to]]
- [[ODS.dbo.account.is_current]]
- [[ODS.dbo.account.is_deleted]]
- [[ODS.dbo.account.ods_rowid]]
- [[ODS.dbo.account.opened_date]]
- [[ODS.dbo.account.row_hash]]
- [[ODS.dbo.account.status]]

## zc-plugin-parent-node
- [[ODS.dbo]]

