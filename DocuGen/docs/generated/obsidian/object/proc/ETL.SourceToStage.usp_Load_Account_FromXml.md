# ETL.SourceToStage.usp_Load_Account_FromXml

- Schema: [[ETL.SourceToStage]]
- Type: `Proc`

## Reads objects
- [[Staging.dbo.account]]

## Writes objects
- [[Staging.dbo.account]]

## Calls objects
- _(none detected)_

## Reads columns
- _(none detected)_

## Writes columns
- [[Staging.dbo.account.account_number]]
- [[Staging.dbo.account.account_type]]
- [[Staging.dbo.account.customer_number]]
- [[Staging.dbo.account.opened_date]]
- [[Staging.dbo.account.row_hash]]
- [[Staging.dbo.account.source_file_name]]
- [[Staging.dbo.account.status]]

## Views
- [[.views/upstream/ETL.SourceToStage.usp_Load_Account_FromXml|Upstream]]
- [[.views/downstream/ETL.SourceToStage.usp_Load_Account_FromXml|Downstream]]

