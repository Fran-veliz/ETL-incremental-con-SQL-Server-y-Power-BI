USE AventureWorks_DWH;
GO

CREATE OR ALTER PROCEDURE DW.sp_carga_Dim_Product
AS
BEGIN 
    SET NOCOUNT ON;
   -----------------------------------------------
   ---1. VARIABLES DE CONTROL
   -----------------------------------------------

   DECLARE 
      @Proceso NVARCHAR(100)='DW_DIM_PRODUCT',
	  @BatchID UNIQUEIDENTIFIER = NEWID(),
	  @RowsAffected INT=0;

   BEGIN TRY 
       ------------------------------------------------------
	   ----2.REGISTRAR INICIO DE PROCESOS (ETL.Cointrol_Carga)
	   -------------------------------------------------------
	   MERGE ETL.Control_Carga AS T
	   USING (SELECT @Proceso AS Proceso)AS S
	   ON T.Proceso = S.Proceso
	   WHEN MATCHED THEN 
	      UPDATE SET 
		        Estado= 'EN PROCESO',
				FechaInicio =GETDATE(),
				BatchID = @BatchID,
				MensajeError= NULL
	   WHEN NOT MATCHED THEN 
	        INSERT (Proceso,Ultima_Fecha_Modificada,BatchID,Estado,FechaInicio)
			VALUES(@Proceso,NULL,@BatchID,'EN PROCESO',GETDATE());
	--------------------------------------------------------
	---3.CARGA DIMENCIONAL DE (MERGE: STG´-> DW)
	--------------------------------------------------------
      MERGE DW.Dim_Product AS TARGET 
	  USING (
	      SELECT DISTINCT 
		       ProductID_Source,
			   NombreProducto,
			   ISNULL(Color,'sin Color') AS Color,
			   Subcategoria,
			   Categoria
			FROM STG.Producto
		  )AS SOURCE 
		  ON (TARGET.ProductID_Source = SOURCE.ProductID_Source)

		  ---A.SI EXISTE ALGO CAMBIO ->ACTUALIZAR (SCD TIPO 1)

		  WHEN MATCHED AND (
		   TARGET.NombreProducto <>  SOURCE.NombreProducto OR 
		   TARGET.Color          <>  SOURCE.Color OR 
		   TARGET.Subcategoria   <>  SOURCE.Subcategoria OR
		   TARGET.Categoria      <>  SOURCE.Categoria
		  
		  ) THEN 
		       UPDATE SET
			        TARGET.NombreProducto = SOURCE.NombreProducto,
		            TARGET.Color          = SOURCE.Color,
		            TARGET.Subcategoria   = SOURCE.Subcategoria,
		            TARGET.Categoria      = SOURCE.Categoria,
		            TARGET.FechaCarga     = GETDATE(),
		            TARGET.UsuarioCarga   = SYSTEM_USER


		  WHEN NOT MATCHED BY TARGET THEN
		      INSERT(ProductID_Source,NombreProducto,Color,Subcategoria,Categoria,FechaCarga,UsuarioCarga)
			  VALUES (
			     SOURCE.ProductID_Source,
				 SOURCE.NombreProducto,
				 SOURCE.Color,
				 SOURCE.Subcategoria,
				 SOURCE.Categoria,
				 GETDATE(),
				 SYSTEM_USER
			  );

			SET @RowsAffected =@@ROWCOUNT;
			----------------------------------------------------
			--4. REGISTRAR FIN EXITOSO
			----------------------------------------------------

			UPDATE  ETL.Control_Carga
			SET 
			   Estado='OK',
			   FechaFin = GETDATE(),
			   MensajeError='Filas Procesadas'+ CAST(@RowsAffected AS VARCHAR)
			WHERE Proceso = @Proceso;

    END TRY 
	BEGIN CATCH
	    ----------------------------------------------------------------------
        ---5. MANEJO DE ERRORES 
		----------------------------------------------------------------------
		UPDATE ETL.Control_Carga
		SET 
		    Estado      = 'ERROR',
			FechaFin    = GETDATE(),
			MensajeError= ERROR_MESSAGE()
	    WHERE Proceso = @Proceso;
		THROW;

	END CATCH 
	END;
	GO