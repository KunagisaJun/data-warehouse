# Upstream: ETL.StageToODS.usp_StageToODS_Account

Start: [[ETL.StageToODS.usp_StageToODS_Account]]

## Hop 1
- [[ETL.StageToODS.usp_StageToODS_All]] (call)
- [[ODS.dbo.account]] (read)
- [[ODS.dbo.account.account_number]] (read-col)
- [[ODS.dbo.account.account_type]] (read-col)
- [[ODS.dbo.account.customer_number]] (read-col)
- [[ODS.dbo.account.is_current]] (read-col)
- [[ODS.dbo.account.is_deleted]] (read-col)
- [[ODS.dbo.account.opened_date]] (read-col)
- [[ODS.dbo.account.row_hash]] (read-col)
- [[ODS.dbo.account.status]] (read-col)
- [[Staging.dbo.account]] (read)

## Hop 2
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (call)
- [[ETL.StageToODS.usp_StageToODS_Account]] (write)
- [[ETL.StageToODS.usp_StageToODS_Account]] (write-col)
- [[ODS.dbo.account]] (contains)
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (write)
- [[ETL.SourceToStage.usp_Load_Account_FromXml]] (write)

## Hop 3
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (call)
- [[Staging.dbo.account]] (read)

