USE AventureWorks_DWH
GO 

CREATE TABLE ETL.Control_Carga (
    Proceso NVARCHAR(100) PRIMARY KEY,
    Ultima_Fecha_Modificada DATETIME,
    BatchID UNIQUEIDENTIFIER,
    Estado NVARCHAR(20),
    FechaInicio DATETIME,
    FechaFin DATETIME,
    MensajeError NVARCHAR(MAX)
);
