---
tags:
  - sql
  - db/Staging
  - type/table
  - lineage/data
  - lineage/object
docugen_key: Staging.dbo.customer
docugen_type: table
docugen_db: Staging
---

# Staging.dbo.customer

- Schema: [[Staging.dbo]]
- Type: `Table`

## Definition
```sql
CREATE TABLE [dbo].[customer] (
    [rowid]            BIGINT         IDENTITY (1, 1) NOT NULL,
    [load_dts]         DATETIME2 (3)  CONSTRAINT [DF_stg_customer_load_dts] DEFAULT (SYSUTCDATETIME()) NOT NULL,
    [source_file_name] NVARCHAR (260) NULL,
    [row_hash]         VARBINARY (32) NULL,
    [customer_number]  INT            NOT NULL,
    [customer_name]    NVARCHAR (200) NULL,
    [email]            NVARCHAR (320) NULL,
    [phone]            NVARCHAR (50)  NULL,
    CONSTRAINT [PK_stg_customer] PRIMARY KEY CLUSTERED ([customer_number] ASC)
)
```

## Columns
- [[Staging.dbo.customer.customer_name]]
- [[Staging.dbo.customer.customer_number]]
- [[Staging.dbo.customer.email]]
- [[Staging.dbo.customer.load_dts]]
- [[Staging.dbo.customer.phone]]
- [[Staging.dbo.customer.rowid]]
- [[Staging.dbo.customer.row_hash]]
- [[Staging.dbo.customer.source_file_name]]

## zc-plugin-parent-node
- [[Staging.dbo]]

## zc-plugin-parent-node-data
- [[ETL.SourceToStage.usp_Load_Customer_FromXml]]

