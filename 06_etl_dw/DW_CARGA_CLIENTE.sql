USE AventureWorks_DWH;
GO

CREATE OR ALTER PROCEDURE DW.sp_Carga_Dim_Cliente
AS
BEGIN 
    SET NOCOUNT ON;

    -----------------------------------------------
    --- 1. VARIABLES DE CONTROL
    -----------------------------------------------
    DECLARE 
        @Proceso NVARCHAR(100) = 'DW_DIM_CLIENTE',
        @BatchID UNIQUEIDENTIFIER = NEWID(),
        @RowsAffected INT = 0;

    BEGIN TRY 
        ------------------------------------------------------
        ---- 2. REGISTRAR INICIO DE PROCESO (Auditoría)
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
        --- 3. CARGA DIMENSIONAL (MERGE: STG -> DW) - SCD TIPO 1
        --------------------------------------------------------
        MERGE DW.Dim_Cliente AS TARGET 
        USING (
            SELECT DISTINCT 
                CustomerID_Source,
                NombreCompleto,
                Email,
                TipoCliente,
                -- Se asume que TerritoryID viene de la lógica de negocio o STG
                NULL AS TerritoryID_Source 
            FROM STG.Cliente
        ) AS SOURCE 
        ON (TARGET.CustomerID_Source = SOURCE.CustomerID_Source)

        --- A. SI EXISTE Y ALGO CAMBIÓ -> ACTUALIZAR (Sin guardar historial)
        WHEN MATCHED AND (
            TARGET.NombreCompleto <> SOURCE.NombreCompleto OR 
            TARGET.Email          <> SOURCE.Email OR 
            TARGET.TipoCliente    <> SOURCE.TipoCliente
        ) THEN 
            UPDATE SET
                TARGET.NombreCompleto = SOURCE.NombreCompleto,
                TARGET.Email          = SOURCE.Email,
                TARGET.TipoCliente    = SOURCE.TipoCliente,
                TARGET.FechaCarga     = GETDATE(),
                TARGET.UsuarioCarga   = SYSTEM_USER

        --- B. SI NO EXISTE -> INSERTAR
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (CustomerID_Source, NombreCompleto, Email, TipoCliente, FechaCarga, UsuarioCarga)
            VALUES (
                SOURCE.CustomerID_Source,
                SOURCE.NombreCompleto,
                SOURCE.Email,
                SOURCE.TipoCliente,
                GETDATE(),
                SYSTEM_USER
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
        ----------------------------------------------------------------------
        --- 5. MANEJO DE ERRORES 
        ----------------------------------------------------------------------
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