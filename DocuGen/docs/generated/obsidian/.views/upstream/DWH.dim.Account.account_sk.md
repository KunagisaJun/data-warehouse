# Upstream: DWH.dim.Account.account_sk

Start: [[DWH.dim.Account.account_sk]]

## Hop 1
- [[DWH.dim.Account]] (contains)

## Hop 2
- [[ETL.ODSToDWH.usp_Load_DimAccount]] (write)

## Hop 3
- [[DWH.dim.Account]] (read)
- [[ETL.ODSToDWH.usp_LoadAll_ODSToDWH]] (call)
- [[ODS.dbo.account]] (read)

## Hop 4
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (call)
- [[ETL.StageToODS.usp_StageToODS_Account]] (write)

## Hop 5
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

## Hop 6
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (call)
- [[ETL.StageToODS.usp_StageToODS_Account]] (write-col)
- [[ODS.dbo.account]] (contains)
- [[ETL.SourceToStage.usp_LoadAll_FromVendor]] (write)
- [[ETL.SourceToStage.usp_Load_Account_FromXml]] (write)

