# ETL.ODSToDWH.usp_Load_DimDate

- Schema: [[ETL.ODSToDWH]]
- Type: `Proc`

## Reads objects
- [[DWH.dim.Date]]

## Writes objects
- [[DWH.dim.Date]]

## Calls objects
- _(none detected)_

## Reads columns
- _(none detected)_

## Writes columns
- [[DWH.dim.Date.date_sk]]
- [[DWH.dim.Date.date_value]]
- [[DWH.dim.Date.day_name]]
- [[DWH.dim.Date.day_number]]
- [[DWH.dim.Date.day_of_week]]
- [[DWH.dim.Date.is_weekend]]
- [[DWH.dim.Date.month_name]]
- [[DWH.dim.Date.month_number]]
- [[DWH.dim.Date.quarter_number]]
- [[DWH.dim.Date.year_number]]

## Views
- [[.views/upstream/ETL.ODSToDWH.usp_Load_DimDate|Upstream]]
- [[.views/downstream/ETL.ODSToDWH.usp_Load_DimDate|Downstream]]

