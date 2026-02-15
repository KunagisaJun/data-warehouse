# ETL.SourceToStage.usp_LoadAll_FromVendor

- Schema: [[ETL.SourceToStage]]
- Type: `Proc`

## Reads objects
- _(none detected)_

## Writes objects
- [[Staging.dbo.account]]
- [[Staging.dbo.customer]]
- [[Staging.dbo.transaction]]

## Calls objects
- [[ETL.ODSToDWH.usp_LoadAll_ODSToDWH]]
- [[ETL.SourceToStage.usp_Load_Account_FromXml]]
- [[ETL.SourceToStage.usp_Load_Customer_FromXml]]
- [[ETL.SourceToStage.usp_Load_Transaction_FromXml]]
- [[ETL.StageToODS.usp_StageToODS_All]]

## Reads columns
- _(none detected)_

## Writes columns
- _(none detected)_

