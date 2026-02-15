# Downstream: ETL.ODSToDWH.usp_Load_DimAccount

Start: [[ETL.ODSToDWH.usp_Load_DimAccount]]

## Hop 1
- [[DWH.dim.Account]] (write)
- [[DWH.dim.Account.account_number]] (write-col)
- [[DWH.dim.Account.account_type]] (write-col)
- [[DWH.dim.Account.customer_number]] (write-col)
- [[DWH.dim.Account.effective_from]] (write-col)
- [[DWH.dim.Account.effective_to]] (write-col)
- [[DWH.dim.Account.is_current]] (write-col)
- [[DWH.dim.Account.is_deleted]] (write-col)
- [[DWH.dim.Account.opened_date]] (write-col)
- [[DWH.dim.Account.row_hash]] (write-col)
- [[DWH.dim.Account.status]] (write-col)

## Hop 2
- [[DWH.dim.Account.account_number]] (contains)
- [[DWH.dim.Account.account_sk]] (contains)
- [[DWH.dim.Account.account_type]] (contains)
- [[DWH.dim.Account.customer_number]] (contains)
- [[DWH.dim.Account.effective_from]] (contains)
- [[DWH.dim.Account.effective_to]] (contains)
- [[DWH.dim.Account.is_current]] (contains)
- [[DWH.dim.Account.is_deleted]] (contains)
- [[DWH.dim.Account.opened_date]] (contains)
- [[DWH.dim.Account.row_hash]] (contains)
- [[DWH.dim.Account.status]] (contains)
- [[ETL.ODSToDWH.usp_Load_DimAccount]] (read)
- [[ETL.ODSToDWH.usp_Load_FactTransaction]] (read)
- [[ETL.ODSToDWH.usp_Load_FactTransaction]] (read-col)

## Hop 3
- [[ETL.ODSToDWH.usp_Load_FactTransaction]] (read-col)
- [[DWH.fact.Transaction]] (write)
- [[DWH.fact.Transaction.account_sk]] (write-col)
- [[DWH.fact.Transaction.amount]] (write-col)
- [[DWH.fact.Transaction.customer_sk]] (write-col)
- [[DWH.fact.Transaction.description]] (write-col)
- [[DWH.fact.Transaction.row_hash]] (write-col)
- [[DWH.fact.Transaction.transaction_date_sk]] (write-col)
- [[DWH.fact.Transaction.transaction_number]] (write-col)

## Hop 4
- [[DWH.fact.Transaction.account_sk]] (contains)
- [[DWH.fact.Transaction.amount]] (contains)
- [[DWH.fact.Transaction.customer_sk]] (contains)
- [[DWH.fact.Transaction.description]] (contains)
- [[DWH.fact.Transaction.row_hash]] (contains)
- [[DWH.fact.Transaction.transaction_date_sk]] (contains)
- [[DWH.fact.Transaction.transaction_number]] (contains)
- [[ETL.ODSToDWH.usp_Load_FactTransaction]] (read)
- [[ETL.ODSToDWH.usp_Load_FactTransaction]] (read-col)

