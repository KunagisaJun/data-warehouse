# Upstream: Staging.dbo.transaction.transaction_date

Start: [[Staging.dbo.transaction.transaction_date]]

## Hop 1
- [[ETL.SourceToStage.usp_Load_Transaction_FromXml]] (write-col)
- [[Staging.dbo.transaction]] (contains)

## Hop 2
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (call)
- [[Staging.dbo.transaction]] (read)
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (write)
- [[ETL.SourceToStage.usp_Load_Transaction_FromXml]] (write)

