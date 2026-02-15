# Upstream: Staging.dbo.customer.load_dts

Start: [[Staging.dbo.customer.load_dts]]

## Hop 1
- [[Staging.dbo.customer]] (contains)

## Hop 2
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (write)
- [[ETL.SourceToStage.usp_Load_Customer_FromXml]] (write)

## Hop 3
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (call)
- [[Staging.dbo.customer]] (read)

