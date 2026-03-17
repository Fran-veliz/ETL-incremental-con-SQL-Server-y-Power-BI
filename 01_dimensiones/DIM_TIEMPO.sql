USE AventureWorks_DWH;
GO 

IF OBJECT_ID('DW.Dim_Tiempo','U') IS NOT NULL
    DROP TABLE DW.Dim_Tiempo;
GO

CREATE TABLE DW.Dim_Tiempo (
    DateKey INT NOT NULL PRIMARY KEY,      -- yyyymmdd
    Fecha DATE NOT NULL,
    Dia INT,
    DiaSemana INT,
    NombreDia NVARCHAR(20),

    Mes INT,
    NombreMes NVARCHAR(20),
    MesNumero INT,

    Trimestre INT,
    Año INT,

    SemanaAño INT,
    EsFinSemana BIT,

    AñoFiscal INT,
    MesFiscal INT,
    TrimestreFiscal INT,

    FechaCarga DATETIME DEFAULT GETDATE()
);
GO
