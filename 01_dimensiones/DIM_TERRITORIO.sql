USE AventureWorks_DWH;
GO 

IF OBJECT_ID('DW.Dim_Territory','U') IS NOT NULL
    DROP TABLE DW.Dim_Territory;
GO

CREATE TABLE DW.Dim_Territory (
    TerritoryKey INT IDENTITY(1,1) PRIMARY KEY,
    TerritoryID_Source INT NOT NULL,
    NombreTerritorio NVARCHAR(100) NOT NULL,
    Pais NVARCHAR(100) NOT NULL,
    Grupo NVARCHAR(50),
    FechaCarga DATETIME DEFAULT GETDATE(),
    UsuarioCarga NVARCHAR(50) DEFAULT SYSTEM_USER
);
GO
