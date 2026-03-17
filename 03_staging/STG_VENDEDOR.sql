USE AventureWorks_DWH;
GO 

IF OBJECT_ID('STG.Vendedor','U') IS NULL
BEGIN 
    CREATE TABLE STG.Vendedor(
	BusinessEntityID_Source INT NOT NULL,
	NombreCompleto NVARCHAR (150),
	Cargo NVARCHAR(50),
	FechaContratacion DATE,
	TerritoryID_Source INT ,
	TerritoryName NVARCHAR,
	SalesQuota MONEY,
	Bonus MONEY,
	CommissionsPct DECIMAL(5,2),
	ModifiedDate DATETIME ,

	FechaCarga DATETIME DEFAULT GETDATE(),
	BachID UNIQUEIDENTIFIER

	
	);
END;
GO 