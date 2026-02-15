# Upstream: Staging.dbo.transaction.rowid

Start: [[Staging.dbo.transaction.rowid]]

## Hop 1
- [[Staging.dbo.transaction]] (contains)

## Hop 2
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (write)
- [[ETL.SourceToStage.usp_Load_Transaction_FromXml]] (write)

## Hop 3
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (call)
- [[Staging.dbo.transaction]] (read)

