# Upstream: Staging.dbo.account.opened_date

Start: [[Staging.dbo.account.opened_date]]

## Hop 1
- [[ETL.SourceToStage.usp_Load_Account_FromXml]] (write-col)
- [[Staging.dbo.account]] (contains)

## Hop 2
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (call)
- [[Staging.dbo.account]] (read)
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (write)
- [[ETL.SourceToStage.usp_Load_Account_FromXml]] (write)

