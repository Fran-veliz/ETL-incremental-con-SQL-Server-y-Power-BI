USE AventureWorks_DWH;
GO

IF OBJECT_ID('DW.Fact_Sales','U') IS NOT NULL
    DROP TABLE DW.Fact_Sales;
GO

CREATE TABLE DW.Fact_Sales (
    -- Llaves Foráneas (Relaciones)
    DateKey INT NOT NULL 
        CONSTRAINT FK_FactSales_Date REFERENCES DW.Dim_Tiempo(DateKey),
    
    ProductKey INT NOT NULL 
        CONSTRAINT FK_FactSales_Product REFERENCES DW.Dim_Product(ProductKey),
    
    ClientKey INT NOT NULL 
        CONSTRAINT FK_FactSales_Cliente REFERENCES DW.Dim_Cliente(ClienteKey),
    
    SalesPersonKey INT 
        CONSTRAINT FK_FactSales_SalesPerson REFERENCES DW.Dim_SalesPerson(SalesPersonKey),
    
    TerritoryKey INT 
        CONSTRAINT FK_FactSales_Territory REFERENCES DW.Dim_Territory(TerritoryKey),
    
    PromotionKey INT 
        CONSTRAINT FK_FactSales_Promotion REFERENCES DW.Dim_Promotion(PromotionKey),

    -- Datos de la Fuente y Métricas
    SalesOrderID_Source INT NOT NULL,
    OrderQty INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    UnitPriceDiscount DECIMAL(5,2) NOT NULL,
    LineTotal DECIMAL(12,2) NOT NULL,

    -- Auditoría
    FechaCarga DATETIME DEFAULT GETDATE(),

    -- Llave Primaria Compuesta
    CONSTRAINT PK_Fact_Sales PRIMARY KEY (
        SalesOrderID_Source,
        ProductKey
    )
);
GO