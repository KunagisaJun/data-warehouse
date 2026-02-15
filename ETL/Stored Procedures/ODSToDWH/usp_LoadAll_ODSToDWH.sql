CREATE PROCEDURE [ODSToDWH].[usp_LoadAll_ODSToDWH]
AS
BEGIN
    SET NOCOUNT ON;

    EXEC [ETL].[ODSToDWH].[usp_Load_DimDate];
    EXEC [ETL].[ODSToDWH].[usp_Load_DimCustomer];
    EXEC [ETL].[ODSToDWH].[usp_Load_DimAccount];
    EXEC [ETL].[ODSToDWH].[usp_Load_FactTransaction];
END
GO
