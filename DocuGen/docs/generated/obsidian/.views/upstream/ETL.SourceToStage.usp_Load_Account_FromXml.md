# Upstream: ETL.SourceToStage.usp_Load_Account_FromXml

Start: [[ETL.SourceToStage.usp_Load_Account_FromXml]]

## Hop 1
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (call)
- [[Staging.dbo.account]] (read)

## Hop 2
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (write)
- [[ETL.SourceToStage.usp_Load_Account_FromXml]] (write)

