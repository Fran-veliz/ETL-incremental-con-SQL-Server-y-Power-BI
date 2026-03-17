USE AventureWorks_DWH;
GO 
CREATE TABLE DW.Dim_Cliente (
    ClienteKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID_Source INT,
    NombreCompleto NVARCHAR(150),
    Email NVARCHAR(100),
    TipoCliente NVARCHAR(20),
    TerritoryID_Source INT,
    FechaCarga DATETIME DEFAULT GETDATE(),
    UsuarioCarga NVARCHAR(50) DEFAULT SYSTEM_USER
);
