USE AventureWorks_DWH;
GO 
IF OBJECT_ID('DW.Dim_Product','U') IS NOT NULL
    DROP TABLE DW.Dim_Product;
GO

CREATE TABLE DW.Dim_Product (
    ProductKey INT IDENTITY(1,1) PRIMARY KEY,
    ProductID_Source INT NOT NULL,
    NombreProducto NVARCHAR(100) NOT NULL,
    Color NVARCHAR(20),
    Subcategoria NVARCHAR(100),
    Categoria NVARCHAR(100),
    FechaCarga DATETIME DEFAULT GETDATE(),
    UsuarioCarga NVARCHAR(50) DEFAULT SYSTEM_USER
);
GO
