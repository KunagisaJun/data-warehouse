# Downstream: ETL.ODSToDWH.usp_Load_DimDate

Start: [[ETL.ODSToDWH.usp_Load_DimDate]]

## Hop 1
- [[DWH.dim.Date]] (write)
- [[DWH.dim.Date.date_sk]] (write-col)
- [[DWH.dim.Date.date_value]] (write-col)
- [[DWH.dim.Date.day_name]] (write-col)
- [[DWH.dim.Date.day_number]] (write-col)
- [[DWH.dim.Date.day_of_week]] (write-col)
- [[DWH.dim.Date.is_weekend]] (write-col)
- [[DWH.dim.Date.month_name]] (write-col)
- [[DWH.dim.Date.month_number]] (write-col)
- [[DWH.dim.Date.quarter_number]] (write-col)
- [[DWH.dim.Date.year_number]] (write-col)

## Hop 2
- [[DWH.dim.Date.date_sk]] (contains)
- [[DWH.dim.Date.date_value]] (contains)
- [[DWH.dim.Date.day_name]] (contains)
- [[DWH.dim.Date.day_number]] (contains)
- [[DWH.dim.Date.day_of_week]] (contains)
- [[DWH.dim.Date.is_weekend]] (contains)
- [[DWH.dim.Date.month_name]] (contains)
- [[DWH.dim.Date.month_number]] (contains)
- [[DWH.dim.Date.quarter_number]] (contains)
- [[DWH.dim.Date.year_number]] (contains)
- [[ETL.ODSToDWH.usp_Load_DimDate]] (read)

