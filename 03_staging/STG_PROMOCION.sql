USE AventureWorks_DWH;
GO 

IF OBJECT_ID('STG.PROMOCION','U') IS NULL

BEGIN 
CREATE TABLE STG.Promocion(
        SpecialOfferID_Source INT NOT NULL,
        Descripcion NVARCHAR(255),
        DiscountPct DECIMAL(5,4),
        TipoPromocion NVARCHAR(50),
        Categoria NVARCHAR(50),
        FechaInicio DATE,
        FechaFin DATE,
        MinQty INT,
        MaxQty INT,
        ModifiedDate DATETIME,
		FechaCarga DATETIME DEFAULT GETDATE(),
		BatchID UNIQUEIDENTIFIER
)
END;
GO


