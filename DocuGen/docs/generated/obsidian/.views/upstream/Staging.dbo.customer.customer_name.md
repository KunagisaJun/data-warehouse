# Upstream: Staging.dbo.customer.customer_name

Start: [[Staging.dbo.customer.customer_name]]

## Hop 1
- [[ETL.SourceToStage.usp_Load_Customer_FromXml]] (write-col)
- [[Staging.dbo.customer]] (contains)

## Hop 2
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (call)
- [[Staging.dbo.customer]] (read)
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (write)
- [[ETL.SourceToStage.usp_Load_Customer_FromXml]] (write)

