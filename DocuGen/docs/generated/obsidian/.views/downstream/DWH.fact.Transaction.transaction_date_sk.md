# Downstream: DWH.fact.Transaction.transaction_date_sk

Start: [[DWH.fact.Transaction.transaction_date_sk]]

## Hop 1
- [[ETL.ODSToDWH.usp_Load_FactTransaction]] (read-col)

## Hop 2
- [[DWH.fact.Transaction]] (write)
- [[DWH.fact.Transaction.account_sk]] (write-col)
- [[DWH.fact.Transaction.amount]] (write-col)
- [[DWH.fact.Transaction.customer_sk]] (write-col)
- [[DWH.fact.Transaction.description]] (write-col)
- [[DWH.fact.Transaction.row_hash]] (write-col)
- [[DWH.fact.Transaction.transaction_date_sk]] (write-col)
- [[DWH.fact.Transaction.transaction_number]] (write-col)

## Hop 3
- [[DWH.fact.Transaction.account_sk]] (contains)
- [[DWH.fact.Transaction.amount]] (contains)
- [[DWH.fact.Transaction.customer_sk]] (contains)
- [[DWH.fact.Transaction.description]] (contains)
- [[DWH.fact.Transaction.row_hash]] (contains)
- [[DWH.fact.Transaction.transaction_date_sk]] (contains)
- [[DWH.fact.Transaction.transaction_number]] (contains)
- [[ETL.ODSToDWH.usp_Load_FactTransaction]] (read)
- [[ETL.ODSToDWH.usp_Load_FactTransaction]] (read-col)

