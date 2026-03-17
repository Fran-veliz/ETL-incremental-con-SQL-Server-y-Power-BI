USE AventureWorks_DWH;
GO 


CREATE OR ALTER PROCEDURE STG.sp_Carga_Territory
AS

BEGIN 
    SET NOCOUNT ON;

    ------------------------------------------------------------
    -- 1. VARIABLES DE CONTROL
    ------------------------------------------------------------
    DECLARE 
        @Proceso NVARCHAR(100) = 'STG_Territory',
        @UltimaFecha DATETIME,
        @NuevaFecha DATETIME,
        @BatchID UNIQUEIDENTIFIER = NEWID();

    BEGIN TRY

        ------------------------------------------------------------
        -- 2. OBTENER WATERMARK (última fecha procesada)
        ------------------------------------------------------------
        SELECT @UltimaFecha = Ultima_Fecha_Modificada
        FROM ETL.Control_Carga
        WHERE Proceso = @Proceso;

        -- Si es la primera vez, arrancamos desde una fecha antigua
        IF @UltimaFecha IS NULL
            SET @UltimaFecha = '1900-01-01';

        ------------------------------------------------------------
        -- 3. REGISTRAR INICIO DEL PROCESO
        ------------------------------------------------------------
        MERGE ETL.Control_Carga AS T
        USING (SELECT @Proceso AS Proceso) AS S
        ON T.Proceso = S.Proceso
        WHEN MATCHED THEN
            UPDATE SET 
                Estado = 'EN PROCESO',
                FechaInicio = GETDATE(),
                BatchID = @BatchID,
                MensajeError = NULL
        WHEN NOT MATCHED THEN
            INSERT (Proceso, Ultima_Fecha_Modificada, BatchID, Estado, FechaInicio)
            VALUES (@Proceso, @UltimaFecha, @BatchID, 'EN PROCESO', GETDATE());

        ------------------------------------------------------------
		 ------------------------------------------------------------
        -- 4. LIMPIEZA DE STAGING (¡AQUÍ VA EL TRUNCATE!)
        ------------------------------------------------------------
        -- Borramos lo que quedó de la carga anterior para que el 
        -- MERGE posterior en la capa DW sea veloz.
        TRUNCATE TABLE STG.Territory;
	    

	    INSERT INTO STG.Territory(
	        TerritoryID_Source ,
            TerritoryName ,
            CountryRegionCode ,
            CountryName ,
            GroupName,
            ModifiedDate ,
            BatchID 
	    )
	    SELECT 
	        T.TerritoryID,
         	T.Name,
	        T.CountryRegionCode,
	        CR.Name,
	        T.[Group],
	        T.ModifiedDate,
	        @BatchID

	   FROM AdventureWorks2019.Sales.SalesTerritory T
   	   INNER JOIN  AdventureWorks2019.Person.CountryRegion CR
	     ON T.CountryRegionCode = CR.CountryRegionCode
       WHERE T.ModifiedDate > @UltimaFecha;

        ------------------------------------------------------------
        -- 5. OBTENER NUEVA FECHA MÁXIMA CARGADA
        ------------------------------------------------------------
        SELECT @NuevaFecha = MAX(ModifiedDate)
        FROM STG.Territory
        WHERE BatchID = @BatchID;

        ------------------------------------------------------------
        -- 6. ACTUALIZAR WATERMARK
        ------------------------------------------------------------
        UPDATE ETL.Control_Carga
        SET 
            Ultima_Fecha_Modificada = ISNULL(@NuevaFecha, @UltimaFecha),
            Estado = 'OK',
            FechaFin = GETDATE()
        WHERE Proceso = @Proceso;

    END TRY
    BEGIN CATCH

        ------------------------------------------------------------
        -- 7. MANEJO DE ERRORES
        ------------------------------------------------------------
        UPDATE ETL.Control_Carga
        SET 
            Estado = 'ERROR',
            FechaFin = GETDATE(),
            MensajeError = ERROR_MESSAGE()
        WHERE Proceso = @Proceso;

        THROW;
    END CATCH
END;
GO
