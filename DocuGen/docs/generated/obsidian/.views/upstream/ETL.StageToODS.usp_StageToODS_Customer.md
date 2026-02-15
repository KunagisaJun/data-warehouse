# Upstream: ETL.StageToODS.usp_StageToODS_Customer

Start: [[ETL.StageToODS.usp_StageToODS_Customer]]

## Hop 1
- [[ETL.StageToODS.usp_StageToODS_All]] (call)
- [[ODS.dbo.customer]] (read)
- [[ODS.dbo.customer.customer_name]] (read-col)
- [[ODS.dbo.customer.customer_number]] (read-col)
- [[ODS.dbo.customer.email]] (read-col)
- [[ODS.dbo.customer.is_current]] (read-col)
- [[ODS.dbo.customer.is_deleted]] (read-col)
- [[ODS.dbo.customer.phone]] (read-col)
- [[ODS.dbo.customer.row_hash]] (read-col)
- [[Staging.dbo.customer]] (read)

## Hop 2
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (call)
- [[ETL.StageToODS.usp_StageToODS_Customer]] (write)
- [[ETL.StageToODS.usp_StageToODS_Customer]] (write-col)
- [[ODS.dbo.customer]] (contains)
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (write)
- [[ETL.SourceToStage.usp_Load_Customer_FromXml]] (write)

## Hop 3
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (call)
- [[Staging.dbo.customer]] (read)

