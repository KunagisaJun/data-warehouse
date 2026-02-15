# Downstream: DWH.fact.Transaction

Start: [[DWH.fact.Transaction]]

## Hop 1
- [[DWH.fact.Transaction.account_sk]] (contains)
- [[DWH.fact.Transaction.amount]] (contains)
- [[DWH.fact.Transaction.customer_sk]] (contains)
- [[DWH.fact.Transaction.description]] (contains)
- [[DWH.fact.Transaction.row_hash]] (contains)
- [[DWH.fact.Transaction.transaction_date_sk]] (contains)
- [[DWH.fact.Transaction.transaction_number]] (contains)
- [[ETL.ODSToDWH.usp_Load_FactTransaction]] (read)

## Hop 2
- [[ETL.ODSToDWH.usp_Load_FactTransaction]] (read-col)
- [[DWH.fact.Transaction]] (write)
- [[DWH.fact.Transaction.account_sk]] (write-col)
- [[DWH.fact.Transaction.amount]] (write-col)
- [[DWH.fact.Transaction.customer_sk]] (write-col)
- [[DWH.fact.Transaction.description]] (write-col)
- [[DWH.fact.Transaction.row_hash]] (write-col)
- [[DWH.fact.Transaction.transaction_date_sk]] (write-col)
- [[DWH.fact.Transaction.transaction_number]] (write-col)

