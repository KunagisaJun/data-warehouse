---
tags: [sql, db/Staging, type/table]
docugen_key: "Staging.dbo.transaction"
docugen_type: "table"
docugen_db: "Staging"
---

# Staging.dbo.transaction

- Schema: [[Staging.dbo]]
- Type: `Table`

## Definition
```sql
CREATE TABLE [dbo].[transaction] (
    [rowid]              BIGINT          IDENTITY (1, 1) NOT NULL,
    [load_dts]           DATETIME2 (3)   CONSTRAINT [DF_stg_transaction_load_dts] DEFAULT (SYSUTCDATETIME()) NOT NULL,
    [source_file_name]   NVARCHAR (260)  NULL,
    [row_hash]           VARBINARY (32)  NULL,
    [transaction_number] INT             NOT NULL,
    [account_number]     INT             NOT NULL,
    [transaction_date]   DATE            NULL,
    [amount]             DECIMAL (19, 4) NULL,
    [description]        NVARCHAR (400)  NULL,
    CONSTRAINT [PK_stg_transaction] PRIMARY KEY CLUSTERED ([transaction_number] ASC)
)
```

## Columns
- [[Staging.dbo.transaction.account_number]]
- [[Staging.dbo.transaction.amount]]
- [[Staging.dbo.transaction.description]]
- [[Staging.dbo.transaction.load_dts]]
- [[Staging.dbo.transaction.rowid]]
- [[Staging.dbo.transaction.row_hash]]
- [[Staging.dbo.transaction.source_file_name]]
- [[Staging.dbo.transaction.transaction_date]]
- [[Staging.dbo.transaction.transaction_number]]

## zc-plugin-parent-node
- [[Staging.dbo]]

## zc-plugin-parent-node-data
- [[ETL.SourceToStage.usp_Load_Transaction_FromXml]]

