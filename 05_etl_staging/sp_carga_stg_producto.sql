USE AventureWorks_DWH;
GO 

CREATE OR ALTER PROCEDURE STG.sp_Carga_Producto
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------------
    -- 1. VARIABLES DE CONTROL
    ------------------------------------------------------------
    
    DECLARE
	@Proceso NVARCHAR(100) = 'STG_PRODUCTO',
    @UltimaFecha DATETIME,
    @NuevaFecha DATETIME,
	@BatchID UNIQUEIDENTIFIER = NEWID();

   BEGIN TRY 
        ------------------------------------------------------------
        -- 2. OBTENER WATERMARK (última fecha procesada)
        ------------------------------------------------------------
		SELECT @UltimaFecha = Ultima_Fecha_Modificada
		FROM ETL.Control_Carga
		WHERE Proceso= @Proceso

        -- Si es la primera vez, arrancamos desde una fecha antigua
		IF @UltimaFecha IS NULL 
		 SET @UltimaFecha= '1900-01-01'

        ------------------------------------------------------------
        -- 3. REGISTRAR INICIO DEL PROCESO
        ------------------------------------------------------------
		MERGE ETL.Control_Carga AS T 
		USING (SELECT @Proceso AS Proceso) AS S
		ON T.Proceso = s.Proceso
		WHEN MATCHED THEN 
		     UPDATE SET 
			  Estado ='EN PROCESO',
			  FechaInicio=GETDATE(),
			  BatchID = @BatchID,
			  MensajeError = Null
		WHEN NOT MATCHED THEN 
		    INSERT (Proceso,Ultima_Fecha_Modificada,BatchID,Estado,FechaInicio)
		    VALUES (@Proceso,@UltimaFecha,@BatchID,'EN PROCESO',GETDATE());


        ------------------------------------------------------------
        -- 4. LIMPIEZA DE STAGING (¡AQUÍ VA EL TRUNCATE!)
        ------------------------------------------------------------
        -- Borramos lo que quedó de la carga anterior para que el 
        -- MERGE posterior en la capa DW sea veloz.
        TRUNCATE TABLE STG.Producto;



        ------------------------------------------------------------
        -- 4. CARGA INCREMENTAL OLTP → STG
        ------------------------------------------------------------

        INSERT INTO STG.Producto (
            ProductID_Source,
            NombreProducto,
            ProductNumber,
            Color,
            Size,
            Weight,
            Subcategoria,
            Categoria,
            StandardCost,
            ListPrice,
            SellStartDate,
            SellEndDate,
            ModifiedDate,
            BatchID
        )
        SELECT
            P.ProductID,
            P.Name,
            P.ProductNumber,
            ISNULL(P.Color, 'N/A'),
            P.Size,
            P.Weight,
            ISNULL(S.Name, 'Sin SubCategoria'),
            ISNULL(C.Name, 'Sin Categoria'),
            P.StandardCost,
            P.ListPrice,
            P.SellStartDate,
            P.SellEndDate,
            P.ModifiedDate,
           @BatchID
       FROM AdventureWorks2019.Production.Product P
       LEFT JOIN AdventureWorks2019.Production.ProductSubcategory S
            ON P.ProductSubcategoryID = S.ProductSubcategoryID
       LEFT JOIN AdventureWorks2019.Production.ProductCategory C
            ON S.ProductCategoryID = C.ProductCategoryID
	   WHERE P.ModifiedDate > @UltimaFecha;

       ------------------------------------------------------------
       -- 5. OBTENER NUEVA FECHA MÁXIMA CARGADA
       ------------------------------------------------------------
   
       SELECT @NuevaFecha = MAX(ModifiedDate)
       FROM STG.Cliente
       WHERE BatchID= @BatchID

       ------------------------------------------------------------
       -- 6. ACTUALIZAR WATERMARK
       ------------------------------------------------------------

       UPDATE ETL.Control_Carga
       SET
          Ultima_Fecha_Modificada= ISNULL(@NuevaFecha,@UltimaFecha),
	      Estado='OK',
	      FechaFin= GETDATE()
       WHERE Proceso= @Proceso;

   END TRY 
   BEGIN CATCH

        ------------------------------------------------------------
        -- 7. MANEJO DE ERRORES
        ------------------------------------------------------------
	    UPDATE ETL.Control_Carga
		SET 
		   Estado='ERROR',
		   FechaFin=GETDATE(),
		   MensajeError=ERROR_MESSAGE()
		WHERE Proceso= @Proceso;

		THROW;


   END CATCH
END;
GO

      

