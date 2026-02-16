---
tags:
  - sql
  - db/DWH
  - type/table
docugen_key: DWH.fact.Transaction
docugen_type: table
docugen_db: DWH
---

# DWH.fact.Transaction

- Schema: [[DWH.fact]]
- Type: `Table`

## Definition
```sql
CREATE TABLE [fact].[Transaction] (
    [transaction_number]  INT             NOT NULL,
    [transaction_date_sk] INT             NOT NULL,
    [account_sk]          INT             NOT NULL,
    [customer_sk]         INT             NOT NULL,
    [amount]              DECIMAL (19, 4) NULL,
    [description]         NVARCHAR (400)  NULL,
    [row_hash]            VARBINARY (32)  NULL,
    CONSTRAINT [PK_DWH_fact_Transaction] PRIMARY KEY CLUSTERED ([transaction_number] ASC)
)
```

## Columns
- [[DWH.fact.Transaction.account_sk]]
- [[DWH.fact.Transaction.amount]]
- [[DWH.fact.Transaction.customer_sk]]
- [[DWH.fact.Transaction.description]]
- [[DWH.fact.Transaction.row_hash]]
- [[DWH.fact.Transaction.transaction_date_sk]]
- [[DWH.fact.Transaction.transaction_number]]

## zc-plugin-parent-node
- [[DWH.fact]]

