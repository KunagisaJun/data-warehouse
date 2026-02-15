# Upstream: Staging.dbo.account.load_dts

Start: [[Staging.dbo.account.load_dts]]

## Hop 1
- [[Staging.dbo.account]] (contains)

## Hop 2
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (write)
- [[ETL.SourceToStage.usp_Load_Account_FromXml]] (write)

## Hop 3
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (call)
- [[Staging.dbo.account]] (read)

