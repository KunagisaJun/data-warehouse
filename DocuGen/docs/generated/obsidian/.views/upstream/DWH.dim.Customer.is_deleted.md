# Upstream: DWH.dim.Customer.is_deleted

Start: [[DWH.dim.Customer.is_deleted]]

## Hop 1
- [[DWH.dim.Customer]] (contains)
- [[ETL.ODSToDWH.usp_Load_DimCustomer]] (write-col)

## Hop 2
- [[ETL.ODSToDWH.usp_Load_DimCustomer]] (write)
- [[DWH.dim.Customer]] (read)
- [[ETL.ODSToDWH.usp_LoadAll_ODSToDWH]] (call)
- [[ODS.dbo.customer]] (read)

## Hop 3
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (call)
- [[ETL.StageToODS.usp_StageToODS_Customer]] (write)

## Hop 4
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

## Hop 5
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (call)
- [[ETL.StageToODS.usp_StageToODS_Customer]] (write-col)
- [[ODS.dbo.customer]] (contains)
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (write)
- [[ETL.SourceToStage.usp_Load_Customer_FromXml]] (write)

## Hop 6
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (call)
- [[Staging.dbo.customer]] (read)

