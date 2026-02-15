# ETL.ODSToDWH.usp_Load_FactTransaction

- Schema: [[ETL.ODSToDWH]]
- Type: `Proc`

## Reads objects
- [[DWH.dim.Account]]
- [[DWH.dim.Customer]]
- [[DWH.fact.Transaction]]
- [[ODS.dbo.transaction]]

## Writes objects
- [[DWH.fact.Transaction]]

## Calls objects
- _(none detected)_

## Reads columns
- [[DWH.dim.Account.account_number]]
- [[DWH.dim.Account.account_sk]]
- [[DWH.dim.Account.customer_number]]
- [[DWH.dim.Account.effective_from]]
- [[DWH.dim.Account.effective_to]]
- [[DWH.dim.Customer.customer_number]]
- [[DWH.dim.Customer.customer_sk]]
- [[DWH.dim.Customer.effective_from]]
- [[DWH.dim.Customer.effective_to]]
- [[DWH.fact.Transaction.account_sk]]
- [[DWH.fact.Transaction.amount]]
- [[DWH.fact.Transaction.customer_sk]]
- [[DWH.fact.Transaction.description]]
- [[DWH.fact.Transaction.row_hash]]
- [[DWH.fact.Transaction.transaction_date_sk]]
- [[DWH.fact.Transaction.transaction_number]]
- [[ODS.dbo.transaction.account_number]]
- [[ODS.dbo.transaction.amount]]
- [[ODS.dbo.transaction.description]]
- [[ODS.dbo.transaction.row_hash]]
- [[ODS.dbo.transaction.transaction_date]]
- [[ODS.dbo.transaction.transaction_number]]

## Writes columns
- [[DWH.fact.Transaction.account_sk]]
- [[DWH.fact.Transaction.amount]]
- [[DWH.fact.Transaction.customer_sk]]
- [[DWH.fact.Transaction.description]]
- [[DWH.fact.Transaction.row_hash]]
- [[DWH.fact.Transaction.transaction_date_sk]]
- [[DWH.fact.Transaction.transaction_number]]

