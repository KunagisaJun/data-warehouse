# Upstream: DWH.dim.Date.date_value

Start: [[DWH.dim.Date.date_value]]

## Hop 1
- [[DWH.dim.Date]] (contains)
- [[ETL.ODSToDWH.usp_Load_DimDate]] (write-col)

## Hop 2
- [[ETL.ODSToDWH.usp_Load_DimDate]] (write)
- [[DWH.dim.Date]] (read)
- [[ETL.ODSToDWH.usp_LoadAll_ODSToDWH]] (call)

## Hop 3
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (call)

