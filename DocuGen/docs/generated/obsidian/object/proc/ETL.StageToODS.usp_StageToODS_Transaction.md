# ETL.StageToODS.usp_StageToODS_Transaction

- Schema: [[ETL.StageToODS]]
- Type: `Proc`

## Reads objects
- [[ODS.dbo.transaction]]
- [[Staging.dbo.transaction]]

## Writes objects
- [[ODS.dbo.transaction]]

## Calls objects
- _(none detected)_

## Reads columns
- [[ODS.dbo.transaction.account_number]]
- [[ODS.dbo.transaction.amount]]
- [[ODS.dbo.transaction.description]]
- [[ODS.dbo.transaction.is_current]]
- [[ODS.dbo.transaction.is_deleted]]
- [[ODS.dbo.transaction.row_hash]]
- [[ODS.dbo.transaction.transaction_date]]
- [[ODS.dbo.transaction.transaction_number]]

## Writes columns
- [[ODS.dbo.transaction.account_number]]
- [[ODS.dbo.transaction.amount]]
- [[ODS.dbo.transaction.description]]
- [[ODS.dbo.transaction.effective_from]]
- [[ODS.dbo.transaction.effective_to]]
- [[ODS.dbo.transaction.is_current]]
- [[ODS.dbo.transaction.is_deleted]]
- [[ODS.dbo.transaction.row_hash]]
- [[ODS.dbo.transaction.transaction_date]]
- [[ODS.dbo.transaction.transaction_number]]

## Views
- [[.views/upstream/ETL.StageToODS.usp_StageToODS_Transaction|Upstream]]
- [[.views/downstream/ETL.StageToODS.usp_StageToODS_Transaction|Downstream]]

