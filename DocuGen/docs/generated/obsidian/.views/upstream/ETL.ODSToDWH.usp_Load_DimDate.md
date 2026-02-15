# Upstream: ETL.ODSToDWH.usp_Load_DimDate

Start: [[ETL.ODSToDWH.usp_Load_DimDate]]

## Hop 1
- [[DWH.dim.Date]] (read)
- [[ETL.ODSToDWH.usp_LoadAll_ODSToDWH]] (call)

## Hop 2
- [[ETL.ODSToDWH.usp_Load_DimDate]] (write)
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (call)

