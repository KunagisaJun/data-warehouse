# Downstream: ODS.dbo.account.account_type

Start: [[ODS.dbo.account.account_type]]

## Hop 1
- [[ETL.StageToODS.usp_StageToODS_Account]] (read-col)

## Hop 2
- [[ODS.dbo.account]] (write)
- [[ODS.dbo.account.account_number]] (write-col)
- [[ODS.dbo.account.account_type]] (write-col)
- [[ODS.dbo.account.customer_number]] (write-col)
- [[ODS.dbo.account.effective_from]] (write-col)
- [[ODS.dbo.account.effective_to]] (write-col)
- [[ODS.dbo.account.is_current]] (write-col)
- [[ODS.dbo.account.is_deleted]] (write-col)
- [[ODS.dbo.account.opened_date]] (write-col)
- [[ODS.dbo.account.row_hash]] (write-col)
- [[ODS.dbo.account.status]] (write-col)

## Hop 3
- [[ETL.ODSToDWH.usp_Load_DimAccount]] (read)
- [[ETL.StageToODS.usp_StageToODS_Account]] (read)
- [[ODS.dbo.account.account_number]] (contains)
- [[ODS.dbo.account.account_type]] (contains)
- [[ODS.dbo.account.customer_number]] (contains)
- [[ODS.dbo.account.effective_from]] (contains)
- [[ODS.dbo.account.effective_to]] (contains)
- [[ODS.dbo.account.is_current]] (contains)
- [[ODS.dbo.account.is_deleted]] (contains)
- [[ODS.dbo.account.ods_rowid]] (contains)
- [[ODS.dbo.account.opened_date]] (contains)
- [[ODS.dbo.account.row_hash]] (contains)
- [[ODS.dbo.account.status]] (contains)
- [[ETL.StageToODS.usp_StageToODS_Account]] (read-col)

## Hop 4
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

## Hop 5
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

