# Upstream: DWH.dim.Date

Start: [[DWH.dim.Date]]

## Hop 1
- [[ETL.ODSToDWH.usp_Load_DimDate]] (write)

## Hop 2
- [[DWH.dim.Date]] (read)
- [[ETL.ODSToDWH.usp_LoadAll_ODSToDWH]] (call)

## Hop 3
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (call)

