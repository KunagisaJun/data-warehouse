---
tags:
  - sql
  - db/ETL
  - type/proc
docugen_key: ETL.ODSToDWH.usp_Load_DimCustomer
docugen_type: proc
docugen_db: ETL
---

# ETL.ODSToDWH.usp_Load_DimCustomer

- Schema: [[ETL.ODSToDWH]]
- Type: `Proc`

## Definition
```sql
CREATE PROCEDURE [ODSToDWH].[usp_Load_DimCustomer]
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [$(DWH)].[dim].[Customer] ([customer_number], [effective_from], [effective_to], [is_current], [is_deleted], [row_hash], [customer_name], [email], [phone])
    SELECT [ods_customer].[customer_number],
           [ods_customer].[effective_from],
           [ods_customer].[effective_to],
           [ods_customer].[is_current],
           [ods_customer].[is_deleted],
           [ods_customer].[row_hash],
           [ods_customer].[customer_name],
           [ods_customer].[email],
           [ods_customer].[phone]
    FROM   [$(ODS)].[dbo].[customer] AS [ods_customer]
           LEFT OUTER JOIN
           [$(DWH)].[dim].[Customer] AS [dwh_dim_customer]
           ON [dwh_dim_customer].[customer_number] = [ods_customer].[customer_number]
              AND [dwh_dim_customer].[effective_from] = [ods_customer].[effective_from]
    WHERE  [dwh_dim_customer].[customer_sk] IS NULL;
END
```

## zc-plugin-parent-node
- [[DWH.dim.Customer]]
- [[DWH.dim.Customer.customer_name]]
- [[DWH.dim.Customer.customer_number]]
- [[DWH.dim.Customer.effective_from]]
- [[DWH.dim.Customer.effective_to]]
- [[DWH.dim.Customer.email]]
- [[DWH.dim.Customer.is_current]]
- [[DWH.dim.Customer.is_deleted]]
- [[DWH.dim.Customer.phone]]
- [[DWH.dim.Customer.row_hash]]
- [[ETL.ODSToDWH]]
- [[ODS.dbo.customer]]

