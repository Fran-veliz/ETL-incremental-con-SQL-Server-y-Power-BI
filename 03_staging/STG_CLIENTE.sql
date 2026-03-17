USE AventureWorks_DWH;
GO 
IF OBJECT_ID('STG.Cliente','U')IS NULL
BEGIN 
   CREATE TABLE STG.Cliente(
         CustomerID_Source INT NOT NULL,
		 PersonID_Source INT NULL,
		 TipoCliente NVARCHAR(50),
		 NombreCompleto NVARCHAR(150),
		 Email NVARCHAR(100),
		 Phone NVARCHAR(25),
		 City NVARCHAR(50),
		 StateProvince NVARCHAR(50),
		 Country NVARCHAR(50),
		 ModifiedDate DATETIME,
		 FechaCarga DATETIME DEFAULT GETDATE(),
		 BatchID UNIQUEIDENTIFIER,

   );
END;
GO 