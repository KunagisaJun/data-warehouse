# ETL.StageToODS.usp_StageToODS_Customer

- Schema: [[ETL.StageToODS]]
- Type: `Proc`

## Reads objects
- [[ODS.dbo.customer]]
- [[Staging.dbo.customer]]

## Writes objects
- [[ODS.dbo.customer]]

## Calls objects
- _(none detected)_

## Reads columns
- [[ODS.dbo.customer.customer_name]]
- [[ODS.dbo.customer.customer_number]]
- [[ODS.dbo.customer.email]]
- [[ODS.dbo.customer.is_current]]
- [[ODS.dbo.customer.is_deleted]]
- [[ODS.dbo.customer.phone]]
- [[ODS.dbo.customer.row_hash]]

## Writes columns
- [[ODS.dbo.customer.customer_name]]
- [[ODS.dbo.customer.customer_number]]
- [[ODS.dbo.customer.effective_from]]
- [[ODS.dbo.customer.effective_to]]
- [[ODS.dbo.customer.email]]
- [[ODS.dbo.customer.is_current]]
- [[ODS.dbo.customer.is_deleted]]
- [[ODS.dbo.customer.phone]]
- [[ODS.dbo.customer.row_hash]]

## Views
- [[.views/upstream/ETL.StageToODS.usp_StageToODS_Customer|Upstream]]
- [[.views/downstream/ETL.StageToODS.usp_StageToODS_Customer|Downstream]]

