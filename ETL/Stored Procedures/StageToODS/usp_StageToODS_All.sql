CREATE PROCEDURE [StageToODS].[usp_StageToODS_All]
AS
BEGIN
    SET NOCOUNT ON;

    -- order is still sensible: account first for lineage clarity
    EXEC [ETL].[StageToODS].[usp_StageToODS_Account];
    EXEC [ETL].[StageToODS].[usp_StageToODS_Customer];
    EXEC [ETL].[StageToODS].[usp_StageToODS_Transaction];
END
