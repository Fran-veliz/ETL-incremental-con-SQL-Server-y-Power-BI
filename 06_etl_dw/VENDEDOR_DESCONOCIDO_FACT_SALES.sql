USE AventureWorks_DWH;
GO

-- Esto permite insertar el número -1 manualmente aunque sea una columna automática
SET IDENTITY_INSERT DW.Dim_SalesPerson ON;

INSERT INTO DW.Dim_SalesPerson (SalesPersonKey, SalesPersonID_Source, NombreCompleto, Cargo, FechaCarga, UsuarioCarga)
VALUES (-1, -1, 'VENTA POR INTERNET / SIN VENDEDOR', 'N/A', GETDATE(), 'SISTEMA');

SET IDENTITY_INSERT DW.Dim_SalesPerson OFF;
GO