# Downstream: ODS.dbo.transaction

Start: [[ODS.dbo.transaction]]

## Hop 1
- [[ETL.ODSToDWH.usp_Load_FactTransaction]] (read)
- [[ETL.StageToODS.usp_StageToODS_Transaction]] (read)
- [[ODS.dbo.transaction.account_number]] (contains)
- [[ODS.dbo.transaction.amount]] (contains)
- [[ODS.dbo.transaction.description]] (contains)
- [[ODS.dbo.transaction.effective_from]] (contains)
- [[ODS.dbo.transaction.effective_to]] (contains)
- [[ODS.dbo.transaction.is_current]] (contains)
- [[ODS.dbo.transaction.is_deleted]] (contains)
- [[ODS.dbo.transaction.ods_rowid]] (contains)
- [[ODS.dbo.transaction.row_hash]] (contains)
- [[ODS.dbo.transaction.transaction_date]] (contains)
- [[ODS.dbo.transaction.transaction_number]] (contains)

## Hop 2
- [[DWH.fact.Transaction]] (write)
- [[DWH.fact.Transaction.account_sk]] (write-col)
- [[DWH.fact.Transaction.amount]] (write-col)
- [[DWH.fact.Transaction.customer_sk]] (write-col)
- [[DWH.fact.Transaction.description]] (write-col)
- [[DWH.fact.Transaction.row_hash]] (write-col)
- [[DWH.fact.Transaction.transaction_date_sk]] (write-col)
- [[DWH.fact.Transaction.transaction_number]] (write-col)
- [[ODS.dbo.transaction]] (write)
- [[ODS.dbo.transaction.account_number]] (write-col)
- [[ODS.dbo.transaction.amount]] (write-col)
- [[ODS.dbo.transaction.description]] (write-col)
- [[ODS.dbo.transaction.effective_from]] (write-col)
- [[ODS.dbo.transaction.effective_to]] (write-col)
- [[ODS.dbo.transaction.is_current]] (write-col)
- [[ODS.dbo.transaction.is_deleted]] (write-col)
- [[ODS.dbo.transaction.row_hash]] (write-col)
- [[ODS.dbo.transaction.transaction_date]] (write-col)
- [[ODS.dbo.transaction.transaction_number]] (write-col)
- [[ETL.ODSToDWH.usp_Load_FactTransaction]] (read-col)
- [[ETL.StageToODS.usp_StageToODS_Transaction]] (read-col)

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

