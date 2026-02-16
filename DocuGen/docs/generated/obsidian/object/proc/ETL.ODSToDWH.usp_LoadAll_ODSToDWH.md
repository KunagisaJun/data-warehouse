---
tags: [sql, db/ETL, type/proc]
docugen_key: "ETL.ODSToDWH.usp_LoadAll_ODSToDWH"
docugen_type: "proc"
docugen_db: "ETL"
---

# ETL.ODSToDWH.usp_LoadAll_ODSToDWH

- Schema: [[ETL.ODSToDWH]]
- Type: `Proc`

## Definition
```sql
CREATE PROCEDURE [ODSToDWH].[usp_LoadAll_ODSToDWH]
AS
BEGIN
    SET NOCOUNT ON;
    EXECUTE [ETL].[ODSToDWH].[usp_Load_DimDate] ;
    EXECUTE [ETL].[ODSToDWH].[usp_Load_DimCustomer] ;
    EXECUTE [ETL].[ODSToDWH].[usp_Load_DimAccount] ;
    EXECUTE [ETL].[ODSToDWH].[usp_Load_FactTransaction] ;
END
```

## zc-plugin-parent-node
- [[ETL.ODSToDWH]]
- [[ETL.ODSToDWH.usp_Load_DimAccount]]
- [[ETL.ODSToDWH.usp_Load_DimCustomer]]
- [[ETL.ODSToDWH.usp_Load_DimDate]]
- [[ETL.ODSToDWH.usp_Load_FactTransaction]]

## zc-plugin-parent-node-data

