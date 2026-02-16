---
tags:
  - sql
  - db/DWH
  - type/table
docugen_key: DWH.dim.Date
docugen_type: table
docugen_db: DWH
---

# DWH.dim.Date

- Schema: [[DWH.dim]]
- Type: `Table`

## Definition
```sql
CREATE TABLE [dim].[Date] (
    [date_sk]        INT           NOT NULL,
    [date_value]     DATE          NOT NULL,
    [year_number]    INT           NOT NULL,
    [month_number]   INT           NOT NULL,
    [day_number]     INT           NOT NULL,
    [day_of_week]    INT           NOT NULL,
    [day_name]       NVARCHAR (20) NOT NULL,
    [month_name]     NVARCHAR (20) NOT NULL,
    [quarter_number] INT           NOT NULL,
    [is_weekend]     BIT           NOT NULL,
    CONSTRAINT [PK_DWH_dim_Date] PRIMARY KEY CLUSTERED ([date_sk] ASC)
)
```

## Columns
- [[DWH.dim.Date.date_sk]]
- [[DWH.dim.Date.date_value]]
- [[DWH.dim.Date.day_name]]
- [[DWH.dim.Date.day_number]]
- [[DWH.dim.Date.day_of_week]]
- [[DWH.dim.Date.is_weekend]]
- [[DWH.dim.Date.month_name]]
- [[DWH.dim.Date.month_number]]
- [[DWH.dim.Date.quarter_number]]
- [[DWH.dim.Date.year_number]]

## zc-plugin-parent-node
- [[DWH.dim]]

## zc-plugin-parent-node-data

