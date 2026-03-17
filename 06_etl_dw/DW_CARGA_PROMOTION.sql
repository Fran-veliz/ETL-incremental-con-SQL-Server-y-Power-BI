USE AventureWorks_DWH;
GO

CREATE OR ALTER PROCEDURE DW.sp_Carga_Dim_Promotion
AS
BEGIN 
    SET NOCOUNT ON;

    -----------------------------------------------
    --- 1. VARIABLES DE CONTROL
    -----------------------------------------------
    DECLARE 
        @Proceso NVARCHAR(100) = 'DW_DIM_PROMOTION',
        @BatchID UNIQUEIDENTIFIER = NEWID(),
        @RowsAffected INT = 0;

    BEGIN TRY 
        ------------------------------------------------------
        ---- 2. REGISTRAR INICIO DE PROCESO
        -------------------------------------------------------
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
            VALUES (@Proceso, NULL, @BatchID, 'EN PROCESO', GETDATE());

        --------------------------------------------------------
        --- 3. CARGA DIMENSIONAL (MERGE: STG -> DW)
        --------------------------------------------------------
        MERGE DW.Dim_Promotion AS TARGET 
        USING (
            SELECT DISTINCT 
                SpecialOfferID_Source,
                ISNULL(Descripcion, 'Sin Descripción') AS NombrePromocion,
                ISNULL(TipoPromocion, 'Sin Tipo') AS TipoPromocion,
                ISNULL(DiscountPct, 0) AS DescuentoPct,
                FechaInicio,
                FechaFin
            FROM STG.Promocion
            WHERE BatchID = (SELECT MAX(BatchID) FROM STG.Promocion)
        ) AS SOURCE 
        ON (TARGET.PromotionID_Source = SOURCE.SpecialOfferID_Source)

        --- A. ACTUALIZAR SI CAMBIÓ EL DESCUENTO O EL NOMBRE
        WHEN MATCHED AND (
            TARGET.NombrePromocion <> SOURCE.NombrePromocion OR 
            TARGET.DescuentoPct    <> SOURCE.DescuentoPct OR
            TARGET.FechaFin        <> SOURCE.FechaFin
        ) THEN 
            UPDATE SET
                TARGET.NombrePromocion = SOURCE.NombrePromocion,
                TARGET.DescuentoPct    = SOURCE.DescuentoPct,
                TARGET.FechaFin        = SOURCE.FechaFin,
                TARGET.FechaCarga      = GETDATE()

        --- B. INSERTAR NUEVA PROMOCIÓN
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (PromotionID_Source, NombrePromocion, TipoPromocion, DescuentoPct, FechaInicio, FechaFin, FechaCarga)
            VALUES (
                SOURCE.SpecialOfferID_Source,
                SOURCE.NombrePromocion,
                SOURCE.TipoPromocion,
                SOURCE.DescuentoPct,
                SOURCE.FechaInicio,
                SOURCE.FechaFin,
                GETDATE()
            );

        SET @RowsAffected = @@ROWCOUNT;

        ----------------------------------------------------
        -- 4. REGISTRAR FIN EXITOSO
        ----------------------------------------------------
        UPDATE ETL.Control_Carga
        SET 
            Estado = 'OK',
            FechaFin = GETDATE(),
            MensajeError = 'Filas Procesadas: ' + CAST(@RowsAffected AS VARCHAR)
        WHERE Proceso = @Proceso;

    END TRY 
    BEGIN CATCH
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