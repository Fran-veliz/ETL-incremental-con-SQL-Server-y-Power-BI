USE AventureWorks_DWH;
GO 

CREATE OR ALTER PROCEDURE DW.sp_Carga_Dim_SalesPerson
AS

BEGIN 
   SET NOCOUNT ON ;
    ---------------------------------------------------------------------------
    ---1. VARIABLES DE CONTROL 
    ---------------------------------------------------------------------------

	DECLARE 
	    @Proceso NVARCHAR(100)= 'DW_DIM_SALESPERSON',
     	@BatchID UNIQUEIDENTIFIER = NEWID(),
    	@RowsAffected INT = 0 ;

    BEGIN TRY 
	  -----------------------------------------------------------------------
	  ----2. REGISTRAR INICIO DE PROCESO (AUDITORIA)
	  -----------------------------------------------------------------------

	  MERGE ETL.Control_Carga AS T 
	  USING (SELECT @Proceso AS  Proceso) AS S
	  ON T.Proceso = S.proceso
	  WHEN MATCHED THEN 
	       UPDATE SET 
		        Estado= 'EN PROCESO',
				FechaInicio = GETDATE() ,
				BatchID = @BatchID,
				MensajeError = NULL
	 WHEN NOT MATCHED  THEN 
	 INSERT (Proceso ,Ultima_Fecha_Modificada,BatchID,Estado,FechaInicio)
	 VALUES(@Proceso,NULL,@BatchID,'EN PROCESO',GETDATE());

	 --------------------------------------------------------------------------
     ---3. CARGA DIMENCIONAL (MERGE :STG -> DW)
	 --------------------------------------------------------------------------
	  MERGE DW.Dim_SalesPerson AS TARGET 
	  USING(
	      SELECT DISTINCT 
		     BusinessEntityID_Source,
			 ISNULL(NombreCompleto,'Sin Nombre ') AS NombreCompleto,
			 ISNULL(Cargo,'Sin carga') AS  Cargo,
			 TerritoryID_Source
	      FROM STG.Vendedor
		  WHERE BachID = (SELECT MAX(BachID) FROM STG.Vendedor)
	  ) AS SOURCE 
	  ON (TARGET.SalesPersonID_Source = SOURCE.BusinessEntityID_Source)

	  --- ACTUALIZAR SI AHY CAMBIOS 
	  WHEN MATCHED AND (
	      TARGET .NombreCompleto <> SOURCE.NombreCompleto OR 
		  TARGET.Cargo           <> SOURCE.Cargo OR
		  TARGET.TerritoryID_Source <> SOURCE.TerritoryID_Source 
	  )THEN 
	     UPDATE SET 
		     TARGET.NombreCompleto = SOURCE.NombreCompleto,
			 TARGET.Cargo          = SOURCE.Cargo,
			 TARGET.TerritoryID_Source = SOURCE.TerritoryID_Source,
			 TARGET.FechaCarga = GETDATE(),
			 TARGET.UsuarioCarga = SYSTEM_USER 

	 ---INSERTAR NUEVOS VENDEDORES 
	  WHEN NOT MATCHED BY TARGET THEN 
	      INSERT (SalesPersonID_Source,NombreCompleto,Cargo,TerritoryID_Source,FechaCarga,UsuarioCarga)
		  VALUES (
		      SOURCE.BusinessEntityID_Source,
			  SOURce.NombreCompleto,
			  SOURCE.Cargo,
			  SOURCE.TerritoryID_Source,
			  GETDATE(),
			  SYSTEM_USER 
	   );

	 SET @RowsAffected = @@ROWCOUNT;

	 --------------------------------------------------------------------------------------
	 ---4. REGISTRAR FIN EXISTO
	 --------------------------------------------------------------------------------------
	 UPDATE ETL.Control_Carga
	 SET 
	    Estado= 'OK',
		FechaFin= GETDATE(),
		MensajeError = 'Filas Procesadas: '+ CAST(@RowsAffected AS VARCHAR)
	WHERE PROCESO =@Proceso;

END TRY  

BEGIN CATCH 
   -------------------------------------------------------------------
   ---5. MANEJO DE ERRORES 
   -------------------------------------------------------------------

   UPDATE ETL.Control_Carga
   SET 
      Estado='ERROR',
	  FechaFin = GETDATE(),
	  MensajeError= ERROR_MESSAGE()
   WHERE Proceso=@Proceso;

  THROW ;

 END CATCH

 END;
 GO 
			 


