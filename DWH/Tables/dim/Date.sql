CREATE TABLE [dim].[Date]
(
    [date_sk]        INT NOT NULL,
    [date_value]     DATE NOT NULL,
    [year_number]    INT NOT NULL,
    [month_number]   INT NOT NULL,
    [day_number]     INT NOT NULL,
    [day_of_week]    INT NOT NULL,
    [day_name]       NVARCHAR(20) NOT NULL,
    [month_name]     NVARCHAR(20) NOT NULL,
    [quarter_number] INT NOT NULL,
    [is_weekend]     BIT NOT NULL,
    CONSTRAINT [PK_DWH_dim_Date] PRIMARY KEY CLUSTERED ([date_sk] ASC)
);
