# Downstream: ETL.ODSToDWH.usp_Load_DimCustomer

Start: [[ETL.ODSToDWH.usp_Load_DimCustomer]]

## Hop 1
- [[DWH.dim.Customer]] (write)
- [[DWH.dim.Customer.customer_name]] (write-col)
- [[DWH.dim.Customer.customer_number]] (write-col)
- [[DWH.dim.Customer.effective_from]] (write-col)
- [[DWH.dim.Customer.effective_to]] (write-col)
- [[DWH.dim.Customer.email]] (write-col)
- [[DWH.dim.Customer.is_current]] (write-col)
- [[DWH.dim.Customer.is_deleted]] (write-col)
- [[DWH.dim.Customer.phone]] (write-col)
- [[DWH.dim.Customer.row_hash]] (write-col)

## Hop 2
- [[DWH.dim.Customer.customer_name]] (contains)
- [[DWH.dim.Customer.customer_number]] (contains)
- [[DWH.dim.Customer.customer_sk]] (contains)
- [[DWH.dim.Customer.effective_from]] (contains)
- [[DWH.dim.Customer.effective_to]] (contains)
- [[DWH.dim.Customer.email]] (contains)
- [[DWH.dim.Customer.is_current]] (contains)
- [[DWH.dim.Customer.is_deleted]] (contains)
- [[DWH.dim.Customer.phone]] (contains)
- [[DWH.dim.Customer.row_hash]] (contains)
- [[ETL.ODSToDWH.usp_Load_DimCustomer]] (read)
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

