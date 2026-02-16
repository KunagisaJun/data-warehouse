---
tags:
  - sql
  - db/ETL
  - type/proc
docugen_key: ETL.ODSToDWH.usp_Load_DimAccount
docugen_type: proc
docugen_db: ETL
---

# ETL.ODSToDWH.usp_Load_DimAccount

- Schema: [[ETL.ODSToDWH]]
- Type: `Proc`

## Definition
```sql
CREATE PROCEDURE [ODSToDWH].[usp_Load_DimAccount]
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO [$(DWH)].[dim].[Account] ([account_number], [customer_number], [effective_from], [effective_to], [is_current], [is_deleted], [row_hash], [account_type], [opened_date], [status])
    SELECT [ods_account].[account_number],
           [ods_account].[customer_number],
           [ods_account].[effective_from],
           [ods_account].[effective_to],
           [ods_account].[is_current],
           [ods_account].[is_deleted],
           [ods_account].[row_hash],
           [ods_account].[account_type],
           [ods_account].[opened_date],
           [ods_account].[status]
    FROM   [$(ODS)].[dbo].[account] AS [ods_account]
           LEFT OUTER JOIN
           [$(DWH)].[dim].[Account] AS [dwh_dim_account]
           ON [dwh_dim_account].[account_number] = [ods_account].[account_number]
              AND [dwh_dim_account].[effective_from] = [ods_account].[effective_from]
    WHERE  [dwh_dim_account].[account_sk] IS NULL;
END
```

## zc-plugin-parent-node
- [[DWH.dim.Account]]
- [[DWH.dim.Account.account_number]]
- [[DWH.dim.Account.account_type]]
- [[DWH.dim.Account.customer_number]]
- [[DWH.dim.Account.effective_from]]
- [[DWH.dim.Account.effective_to]]
- [[DWH.dim.Account.is_current]]
- [[DWH.dim.Account.is_deleted]]
- [[DWH.dim.Account.opened_date]]
- [[DWH.dim.Account.row_hash]]
- [[DWH.dim.Account.status]]
- [[ETL.ODSToDWH]]
- [[ODS.dbo.account]]

