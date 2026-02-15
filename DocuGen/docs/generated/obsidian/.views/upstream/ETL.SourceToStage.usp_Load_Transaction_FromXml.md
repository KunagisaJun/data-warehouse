# Upstream: ETL.SourceToStage.usp_Load_Transaction_FromXml

Start: [[ETL.SourceToStage.usp_Load_Transaction_FromXml]]

## Hop 1
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (call)
- [[Staging.dbo.transaction]] (read)

## Hop 2
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (write)
- [[ETL.SourceToStage.usp_Load_Transaction_FromXml]] (write)

