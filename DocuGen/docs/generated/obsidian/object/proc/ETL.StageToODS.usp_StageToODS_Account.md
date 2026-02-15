# ETL.StageToODS.usp_StageToODS_Account

- Schema: [[ETL.StageToODS]]
- Type: `Proc`

## Reads objects
- [[ODS.dbo.account]]
- [[Staging.dbo.account]]

## Writes objects
- [[ODS.dbo.account]]

## Calls objects
- _(none detected)_

## Reads columns
- [[ODS.dbo.account.account_number]]
- [[ODS.dbo.account.account_type]]
- [[ODS.dbo.account.customer_number]]
- [[ODS.dbo.account.is_current]]
- [[ODS.dbo.account.is_deleted]]
- [[ODS.dbo.account.opened_date]]
- [[ODS.dbo.account.row_hash]]
- [[ODS.dbo.account.status]]

## Writes columns
- [[ODS.dbo.account.account_number]]
- [[ODS.dbo.account.account_type]]
- [[ODS.dbo.account.customer_number]]
- [[ODS.dbo.account.effective_from]]
- [[ODS.dbo.account.effective_to]]
- [[ODS.dbo.account.is_current]]
- [[ODS.dbo.account.is_deleted]]
- [[ODS.dbo.account.opened_date]]
- [[ODS.dbo.account.row_hash]]
- [[ODS.dbo.account.status]]

## Views
- [[.views/upstream/ETL.StageToODS.usp_StageToODS_Account|Upstream]]
- [[.views/downstream/ETL.StageToODS.usp_StageToODS_Account|Downstream]]

