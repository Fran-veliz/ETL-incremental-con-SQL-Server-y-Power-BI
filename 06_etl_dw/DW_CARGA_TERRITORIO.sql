USE AventureWorks_DWH;
GO

CREATE OR ALTER PROCEDURE DW.sp_Carga_Dim_Territory
AS

BEGIN 
   SET NOCOUNT ON;
    ------------------------------------------------------------------
	---1. VARIABLES DE CONTROL 
	------------------------------------------------------------------

	DECLARE 
	@Proceso NVARCHAR(100)= 'DW_DIM_TERRITORIO',
	@BatchID UNIQUEIDENTIFIER = NEWID(),
	@RowsAffected INT =0 ;

	BEGIN TRY 
	 --------------------------------------------------------------------
	 ---2. AUDITORIA INICIAL 
	 --------------------------------------------------------------------
	  MERGE ETL.Control_Carga AS T 
	  USING (SELECT @Proceso AS Proceso) AS S
	  ON T.Proceso = S.Proceso
	  WHEN MATCHED THEN 
	          UPDATE SET Estado= 'EN PROCESO',FechaInicio = GETDATE(),BatchID=@BatchID,MensajeError=NULL
	  WHEN NOT MATCHED THEN 
	          INSERT (Proceso,Ultima_Fecha_Modificada,BatchID,Estado,FechaInicio)
			  VALUES (@Proceso,NULL,@BatchID,'EN PROCESO',GETDATE());
	--------------------------------------------------------
	--3. MERGE (STG -> DW)
	--------------------------------------------------------
	MERGE DW.Dim_Territory AS TARGET 
	USING (
	     SELECT DISTINCT 
		   TerritoryID_Source,
		   ISNULL(TerritoryName,'Sin Nombre') AS TerritoryName,
		   ISNULL(CountryName ,' Sin Pais')  AS CountryName,
		   ISNULL(GroupName,'Sin Grupo') AS GroupName 
		 FROM STG.Territory
		 ) AS SOURCE
		 ON (TARGET.TerritoryID_Source = SOURCE.TerritoryID_Source)
		 
		 ----A. ACTUALIZAR (Si cambio el nombre ,Pais o Grupo) 
		 WHEN MATCHED AND (
		      TARGET.NombreTerritorio  <>  SOURCE.TerritoryName OR 
		      TARGET.Pais              <>  SOURCE.CountryName OR 
		      TARGET.Grupo             <>  SOURCE.GroupName
		  
		 ) THEN 
		     UPDATE SET 
			      TARGET.NombreTerritorio = SOURCE.TerritoryName,
		          TARGET.Pais             = SOURCE.CountryName,
		          TARGET.Grupo         = SOURCE.GroupName,
		          TARGET.FechaCarga        = GETDATE(),
		          TARGET.UsuarioCarga      = SYSTEM_USER 

		WHEN NOT MATCHED BY  TARGET THEN 
		      INSERT (TerritoryID_Source,NombreTerritorio,Pais,Grupo,FechaCarga,UsuarioCarga)
			  VALUES (
			    SOURCE.TerritoryID_Source,
			    SOURCE.TerritoryName,
		        SOURCE.CountryName,
		        SOURCE.GroupName,
		        GETDATE(),
		        SYSTEM_USER 
			  );
		SET @RowsAffected= @@ROWCOUNT;
		-----------------------------------------
		---4. AUDUTORIA FINAL 
		-----------------------------------------
		UPDATE ETL.Control_Carga
		SET Estado= 'OK',FechaFin= GETDATE(),MensajeError= 'Filas Procesados'+ CAST(@RowsAffected AS VARCHAR)
		WHERE  Proceso = @Proceso;
		
	END TRY 
	BEGIN CATCH 
	   UPDATE ETL.Control_Carga
	   SET Estado= 'ERROR',FechaFin= GETDATE(),MensajeError= ERROR_MESSAGE()
	   WHERE Proceso= @Proceso;
	   THROW;
    END CATCH 
END;
GO 
