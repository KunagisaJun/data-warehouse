# ETL.SourceToStage.usp_Load_Customer_FromXml

- Schema: [[ETL.SourceToStage]]
- Type: `Proc`

## Reads objects
- [[Staging.dbo.customer]]

## Writes objects
- [[Staging.dbo.customer]]

## Calls objects
- _(none detected)_

## Reads columns
- _(none detected)_

## Writes columns
- [[Staging.dbo.customer.customer_name]]
- [[Staging.dbo.customer.customer_number]]
- [[Staging.dbo.customer.email]]
- [[Staging.dbo.customer.phone]]
- [[Staging.dbo.customer.row_hash]]
- [[Staging.dbo.customer.source_file_name]]

## Views
- [[.views/upstream/ETL.SourceToStage.usp_Load_Customer_FromXml|Upstream]]
- [[.views/downstream/ETL.SourceToStage.usp_Load_Customer_FromXml|Downstream]]

