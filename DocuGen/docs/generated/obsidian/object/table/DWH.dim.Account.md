---
tags:
  - sql
  - db/DWH
  - type/table
  - lineage/object
docugen_key: DWH.dim.Account
docugen_type: table
docugen_db: DWH
---

# DWH.dim.Account

- Schema: [[DWH.dim]]
- Type: `Table`

## Definition
```sql
CREATE TABLE [dim].[Account] (
    [account_sk]      INT            IDENTITY (1, 1) NOT NULL,
    [account_number]  INT            NOT NULL,
    [customer_number] INT            NOT NULL,
    [effective_from]  DATETIME2 (3)  NOT NULL,
    [effective_to]    DATETIME2 (3)  NOT NULL,
    [is_current]      BIT            NOT NULL,
    [is_deleted]      BIT            NOT NULL,
    [row_hash]        VARBINARY (32) NULL,
    [account_type]    NVARCHAR (50)  NULL,
    [opened_date]     DATE           NULL,
    [status]          NVARCHAR (20)  NULL,
    CONSTRAINT [PK_DWH_dim_Account] PRIMARY KEY CLUSTERED ([account_sk] ASC)
)
```

## Columns
- [[DWH.dim.Account.account_number]]
- [[DWH.dim.Account.account_sk]]
- [[DWH.dim.Account.account_type]]
- [[DWH.dim.Account.customer_number]]
- [[DWH.dim.Account.effective_from]]
- [[DWH.dim.Account.effective_to]]
- [[DWH.dim.Account.is_current]]
- [[DWH.dim.Account.is_deleted]]
- [[DWH.dim.Account.opened_date]]
- [[DWH.dim.Account.row_hash]]
- [[DWH.dim.Account.status]]

## zc-plugin-parent-node
- [[DWH.dim]]

## zc-plugin-parent-node-data
- [[ETL.ODSToDWH.usp_Load_DimAccount]]
- [[ODS.dbo.account]]

