USE AventureWorks_DWH;
GO 
IF OBJECT_ID('DW.Dim_Promotion','U') IS NOT NULL
    DROP TABLE DW.Dim_Promotion;
GO

CREATE TABLE DW.Dim_Promotion (
    PromotionKey INT IDENTITY(1,1) PRIMARY KEY,
    PromotionID_Source INT NOT NULL,
    NombrePromocion NVARCHAR(100),
    TipoPromocion NVARCHAR(50),
    DescuentoPct DECIMAL(5,2),
    FechaInicio DATE,
    FechaFin DATE,
    FechaCarga DATETIME DEFAULT GETDATE()
);
GO
