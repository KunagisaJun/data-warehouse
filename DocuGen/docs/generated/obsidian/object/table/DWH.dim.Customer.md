---
tags:
  - sql
  - db/DWH
  - type/table
docugen_key: DWH.dim.Customer
docugen_type: table
docugen_db: DWH
---

# DWH.dim.Customer

- Schema: [[DWH.dim]]
- Type: `Table`

## Definition
```sql
CREATE TABLE [dim].[Customer] (
    [customer_sk]     INT            IDENTITY (1, 1) NOT NULL,
    [customer_number] INT            NOT NULL,
    [effective_from]  DATETIME2 (3)  NOT NULL,
    [effective_to]    DATETIME2 (3)  NOT NULL,
    [is_current]      BIT            NOT NULL,
    [is_deleted]      BIT            NOT NULL,
    [row_hash]        VARBINARY (32) NULL,
    [customer_name]   NVARCHAR (200) NULL,
    [email]           NVARCHAR (320) NULL,
    [phone]           NVARCHAR (50)  NULL,
    CONSTRAINT [PK_DWH_dim_Customer] PRIMARY KEY CLUSTERED ([customer_sk] ASC)
)
```

## Columns
- [[DWH.dim.Customer.customer_name]]
- [[DWH.dim.Customer.customer_number]]
- [[DWH.dim.Customer.customer_sk]]
- [[DWH.dim.Customer.effective_from]]
- [[DWH.dim.Customer.effective_to]]
- [[DWH.dim.Customer.email]]
- [[DWH.dim.Customer.is_current]]
- [[DWH.dim.Customer.is_deleted]]
- [[DWH.dim.Customer.phone]]
- [[DWH.dim.Customer.row_hash]]

## zc-plugin-parent-node
- [[DWH.dim]]

