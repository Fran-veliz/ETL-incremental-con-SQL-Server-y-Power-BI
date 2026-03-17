USE AventureWorks_DWH;
GO 

IF OBJECT_ID('STG.Producto','U') IS NULL
BEGIN
    CREATE TABLE STG.Producto (
        ProductID_Source INT NOT NULL,
        NombreProducto NVARCHAR(100),
        ProductNumber NVARCHAR(50),
        Color NVARCHAR(30),
        Size NVARCHAR(10),
        Weight DECIMAL(8,2),
        Subcategoria NVARCHAR(50),
        Categoria NVARCHAR(50),
        StandardCost DECIMAL(10,2),
        ListPrice DECIMAL(10,2),
        SellStartDate DATE,
        SellEndDate DATE,
        ModifiedDate DATETIME,
        FechaCarga DATETIME DEFAULT GETDATE(),
        BatchID UNIQUEIDENTIFIER
    );
END;
GO
