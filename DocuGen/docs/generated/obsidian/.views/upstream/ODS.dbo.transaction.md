# Upstream: ODS.dbo.transaction

Start: [[ODS.dbo.transaction]]

## Hop 1
- [[ETL.StageToODS.usp_StageToODS_Transaction]] (write)

## Hop 2
- [[ETL.StageToODS.usp_StageToODS_All]] (call)
- [[ODS.dbo.transaction]] (read)
- [[ODS.dbo.transaction.account_number]] (read-col)
- [[ODS.dbo.transaction.amount]] (read-col)
- [[ODS.dbo.transaction.description]] (read-col)
- [[ODS.dbo.transaction.is_current]] (read-col)
- [[ODS.dbo.transaction.is_deleted]] (read-col)
- [[ODS.dbo.transaction.row_hash]] (read-col)
- [[ODS.dbo.transaction.transaction_date]] (read-col)
- [[ODS.dbo.transaction.transaction_number]] (read-col)
- [[Staging.dbo.transaction]] (read)

## Hop 3
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (call)
- [[ETL.StageToODS.usp_StageToODS_Transaction]] (write-col)
- [[ODS.dbo.transaction]] (contains)
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (write)
- [[ETL.SourceToStage.usp_Load_Transaction_FromXml]] (write)

## Hop 4
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (call)
- [[Staging.dbo.transaction]] (read)

