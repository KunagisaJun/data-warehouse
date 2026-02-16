---
tags:
  - sql
  - db/ODS
  - type/table
docugen_key: ODS.dbo.customer
docugen_type: table
docugen_db: ODS
---

# ODS.dbo.customer

- Schema: [[ODS.dbo]]
- Type: `Table`

## Definition
```sql
CREATE TABLE [dbo].[customer] (
    [ods_rowid]       BIGINT         IDENTITY (1, 1) NOT NULL,
    [effective_from]  DATETIME2 (3)  NOT NULL,
    [effective_to]    DATETIME2 (3)  NOT NULL,
    [is_current]      BIT            NOT NULL,
    [is_deleted]      BIT            NOT NULL,
    [row_hash]        VARBINARY (32) NULL,
    [customer_number] INT            NOT NULL,
    [customer_name]   NVARCHAR (200) NULL,
    [email]           NVARCHAR (320) NULL,
    [phone]           NVARCHAR (50)  NULL,
    CONSTRAINT [PK_ods_customer] PRIMARY KEY CLUSTERED ([ods_rowid] ASC)
)
```

## Columns
- [[ODS.dbo.customer.customer_name]]
- [[ODS.dbo.customer.customer_number]]
- [[ODS.dbo.customer.effective_from]]
- [[ODS.dbo.customer.effective_to]]
- [[ODS.dbo.customer.email]]
- [[ODS.dbo.customer.is_current]]
- [[ODS.dbo.customer.is_deleted]]
- [[ODS.dbo.customer.ods_rowid]]
- [[ODS.dbo.customer.phone]]
- [[ODS.dbo.customer.row_hash]]

## zc-plugin-parent-node
- [[ODS.dbo]]

