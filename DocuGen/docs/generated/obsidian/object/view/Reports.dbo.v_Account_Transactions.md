---
tags:
  - sql
  - db/Reports
  - type/view
  - lineage/object
docugen_key: Reports.dbo.v_Account_Transactions
docugen_type: view
docugen_db: Reports
---

# Reports.dbo.v_Account_Transactions

- Schema: [[Reports.dbo]]
- Type: `View`

## Definition
```sql
CREATE VIEW [dbo].[v_Account_Transactions]
AS
SELECT [dwh_dim_account].[account_sk] AS [dwh_dim_account_account_sk],
       [dwh_dim_account].[account_number] AS [dwh_dim_account_account_number],
       [dwh_dim_account].[customer_number] AS [dwh_dim_account_customer_number],
       [dwh_dim_account].[effective_from] AS [dwh_dim_account_effective_from],
       [dwh_dim_account].[effective_to] AS [dwh_dim_account_effective_to],
       [dwh_dim_account].[is_current] AS [dwh_dim_account_is_current],
       [dwh_dim_account].[is_deleted] AS [dwh_dim_account_is_deleted],
       [dwh_dim_account].[row_hash] AS [dwh_dim_account_row_hash],
       [dwh_dim_account].[account_type] AS [dwh_dim_account_account_type],
       [dwh_dim_account].[opened_date] AS [dwh_dim_account_opened_date],
       [dwh_dim_account].[status] AS [dwh_dim_account_status],
       [dwh_fact_transaction].[transaction_number] AS [dwh_fact_transaction_transaction_number],
       [dwh_fact_transaction].[transaction_date_sk] AS [dwh_fact_transaction_transaction_date_sk],
       [dwh_fact_transaction].[account_sk] AS [dwh_fact_transaction_account_sk],
       [dwh_fact_transaction].[customer_sk] AS [dwh_fact_transaction_customer_sk],
       [dwh_fact_transaction].[amount] AS [dwh_fact_transaction_amount],
       [dwh_fact_transaction].[description] AS [dwh_fact_transaction_description],
       [dwh_fact_transaction].[row_hash] AS [dwh_fact_transaction_row_hash],
       [dwh_dim_date].[date_sk] AS [dwh_dim_date_date_sk],
       [dwh_dim_date].[date_value] AS [dwh_dim_date_date_value],
       [dwh_dim_date].[year_number] AS [dwh_dim_date_year_number],
       [dwh_dim_date].[month_number] AS [dwh_dim_date_month_number],
       [dwh_dim_date].[day_number] AS [dwh_dim_date_day_number],
       [dwh_dim_date].[day_of_week] AS [dwh_dim_date_day_of_week],
       [dwh_dim_date].[day_name] AS [dwh_dim_date_day_name],
       [dwh_dim_date].[month_name] AS [dwh_dim_date_month_name],
       [dwh_dim_date].[quarter_number] AS [dwh_dim_date_quarter_number],
       [dwh_dim_date].[is_weekend] AS [dwh_dim_date_is_weekend]
FROM   [$(DWH)].[dim].[Account] AS [dwh_dim_account]
       LEFT OUTER JOIN
       [$(DWH)].[fact].[Transaction] AS [dwh_fact_transaction]
       ON [dwh_dim_account].[account_sk] = [dwh_fact_transaction].[account_sk]
       LEFT OUTER JOIN
       [$(DWH)].[dim].[Date] AS [dwh_dim_date]
       ON [dwh_fact_transaction].[transaction_date_sk] = [dwh_dim_date].[date_sk]
```

## zc-plugin-parent-node
- [[DWH.dim.Account]]
- [[DWH.dim.Date]]
- [[DWH.fact.Transaction]]
- [[Reports.dbo]]

## zc-plugin-parent-node-data
- [[DWH.dim.Account]]
- [[DWH.dim.Account.account_number]]
- [[DWH.dim.Account.account_sk]]
- [[DWH.dim.Account.account_type]]
- [[DWH.dim.Account.customer_number]]
- [[DWH.dim.Account.effective_from]]
- [[DWH.dim.Account.effective_to]]
- [[DWH.dim.Account.is_current]]
- [[DWH.dim.Account.is_deleted]]
- [[DWH.dim.Account.opened_date]]
- [[DWH.dim.Account.row_hash]]
- [[DWH.dim.Account.status]]
- [[DWH.dim.Date]]
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
- [[DWH.fact.Transaction]]
- [[DWH.fact.Transaction.account_sk]]
- [[DWH.fact.Transaction.amount]]
- [[DWH.fact.Transaction.customer_sk]]
- [[DWH.fact.Transaction.description]]
- [[DWH.fact.Transaction.row_hash]]
- [[DWH.fact.Transaction.transaction_date_sk]]
- [[DWH.fact.Transaction.transaction_number]]

