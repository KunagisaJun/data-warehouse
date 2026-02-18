---
tags:
  - sql
  - db/ODS
  - type/table
docugen_key: ODS.dbo.transaction
docugen_type: table
docugen_db: ODS
---

# ODS.dbo.transaction

- Schema: [[ODS.dbo]]
- Type: `Table`

## Definition
```sql
CREATE TABLE [dbo].[transaction] (
    [ods_rowid]          BIGINT          IDENTITY (1, 1) NOT NULL,
    [effective_from]     DATETIME2 (3)   NOT NULL,
    [effective_to]       DATETIME2 (3)   NOT NULL,
    [is_current]         BIT             NOT NULL,
    [is_deleted]         BIT             NOT NULL,
    [row_hash]           VARBINARY (32)  NULL,
    [transaction_number] INT             NOT NULL,
    [account_number]     INT             NOT NULL,
    [transaction_date]   DATE            NULL,
    [amount]             DECIMAL (19, 4) NULL,
    [description]        NVARCHAR (400)  NULL,
    CONSTRAINT [PK_ods_transaction] PRIMARY KEY CLUSTERED ([ods_rowid] ASC)
)
```

## Columns
- [[ODS.dbo.transaction.account_number]]
- [[ODS.dbo.transaction.amount]]
- [[ODS.dbo.transaction.description]]
- [[ODS.dbo.transaction.effective_from]]
- [[ODS.dbo.transaction.effective_to]]
- [[ODS.dbo.transaction.is_current]]
- [[ODS.dbo.transaction.is_deleted]]
- [[ODS.dbo.transaction.ods_rowid]]
- [[ODS.dbo.transaction.row_hash]]
- [[ODS.dbo.transaction.transaction_date]]
- [[ODS.dbo.transaction.transaction_number]]

## zc-plugin-parent-node
- [[ODS.dbo]]

## zc-plugin-parent-node-data
- [[ETL.StageToODS.usp_StageToODS_Transaction]]
- [[Staging.dbo.transaction]]

