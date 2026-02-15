# Upstream: Staging.dbo.transaction

Start: [[Staging.dbo.transaction]]

## Hop 1
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (write)
- [[ETL.SourceToStage.usp_Load_Transaction_FromXml]] (write)

## Hop 2
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (call)
- [[Staging.dbo.transaction]] (read)

