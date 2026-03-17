USE AventureWorks_DWH;
GO 

IF OBJECT_ID('DW.Dim_SalesPerson','U') IS NOT NULL
    DROP TABLE DW.Dim_SalesPerson;
GO

CREATE TABLE DW.Dim_SalesPerson (
    SalesPersonKey INT IDENTITY(1,1) PRIMARY KEY,
    SalesPersonID_Source INT NOT NULL,
    NombreCompleto NVARCHAR(150) NOT NULL,
    Cargo NVARCHAR(50),
    TerritoryID_Source INT,
    FechaCarga DATETIME DEFAULT GETDATE(),
    UsuarioCarga NVARCHAR(50) DEFAULT SYSTEM_USER
);
GO
