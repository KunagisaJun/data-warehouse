# Downstream: ODS.dbo.customer.phone

Start: [[ODS.dbo.customer.phone]]

## Hop 1
- [[ETL.StageToODS.usp_StageToODS_Customer]] (read-col)

## Hop 2
- [[ODS.dbo.customer]] (write)
- [[ODS.dbo.customer.customer_name]] (write-col)
- [[ODS.dbo.customer.customer_number]] (write-col)
- [[ODS.dbo.customer.effective_from]] (write-col)
- [[ODS.dbo.customer.effective_to]] (write-col)
- [[ODS.dbo.customer.email]] (write-col)
- [[ODS.dbo.customer.is_current]] (write-col)
- [[ODS.dbo.customer.is_deleted]] (write-col)
- [[ODS.dbo.customer.phone]] (write-col)
- [[ODS.dbo.customer.row_hash]] (write-col)

## Hop 3
- [[ETL.ODSToDWH.usp_Load_DimCustomer]] (read)
- [[ETL.StageToODS.usp_StageToODS_Customer]] (read)
- [[ODS.dbo.customer.customer_name]] (contains)
- [[ODS.dbo.customer.customer_number]] (contains)
- [[ODS.dbo.customer.effective_from]] (contains)
- [[ODS.dbo.customer.effective_to]] (contains)
- [[ODS.dbo.customer.email]] (contains)
- [[ODS.dbo.customer.is_current]] (contains)
- [[ODS.dbo.customer.is_deleted]] (contains)
- [[ODS.dbo.customer.ods_rowid]] (contains)
- [[ODS.dbo.customer.phone]] (contains)
- [[ODS.dbo.customer.row_hash]] (contains)
- [[ETL.StageToODS.usp_StageToODS_Customer]] (read-col)

## Hop 4
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

## Hop 5
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

## Hop 6
- [[ETL.ODSToDWH.usp_Load_FactTransaction]] (read-col)
- [[DWH.fact.Transaction]] (write)
- [[DWH.fact.Transaction.account_sk]] (write-col)
- [[DWH.fact.Transaction.amount]] (write-col)
- [[DWH.fact.Transaction.customer_sk]] (write-col)
- [[DWH.fact.Transaction.description]] (write-col)
- [[DWH.fact.Transaction.row_hash]] (write-col)
- [[DWH.fact.Transaction.transaction_date_sk]] (write-col)
- [[DWH.fact.Transaction.transaction_number]] (write-col)

