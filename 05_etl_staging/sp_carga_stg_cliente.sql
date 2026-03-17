USE AventureWorks_DWH;
GO

CREATE OR ALTER PROCEDURE STG.sp_Carga_Cliente
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------------
    -- 1. VARIABLES DE CONTROL
    ------------------------------------------------------------
    DECLARE 
        @Proceso NVARCHAR(100) = 'STG_CLIENTE',
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
        -- 4. LIMPIEZA DE STAGING (¡AQUÍ VA EL TRUNCATE!)
        ------------------------------------------------------------
        -- Borramos lo que quedó de la carga anterior para que el 
        -- MERGE posterior en la capa DW sea veloz.
        TRUNCATE TABLE STG.Cliente;
        ------------------------------------------------------------
        -- 4. CARGA INCREMENTAL OLTP → STG
        ------------------------------------------------------------
        INSERT INTO STG.Cliente (
            CustomerID_Source,
            PersonID_Source,
            TipoCliente,
            NombreCompleto,
            Email,
            Phone,
            City,
            StateProvince,
            Country,
            ModifiedDate,
            BatchID
        )
        SELECT
            C.CustomerID,
            C.PersonID,
            CASE 
                WHEN C.PersonID IS NOT NULL THEN 'PERSONA'
                ELSE 'EMPRESA'
            END AS TipoCliente,
            CONCAT(P.FirstName, ' ', P.LastName),
            EA.EmailAddress,
            PP.PhoneNumber,
            A.City,
            SP.Name,
            CR.Name,
            C.ModifiedDate,
            @BatchID
        FROM AdventureWorks2019.Sales.Customer C
        LEFT JOIN AdventureWorks2019.Person.Person P
            ON C.PersonID = P.BusinessEntityID
        LEFT JOIN AdventureWorks2019.Person.EmailAddress EA
            ON P.BusinessEntityID = EA.BusinessEntityID
        LEFT JOIN AdventureWorks2019.Person.PersonPhone PP
            ON P.BusinessEntityID = PP.BusinessEntityID
        LEFT JOIN AdventureWorks2019.Person.BusinessEntityAddress BEA
            ON P.BusinessEntityID = BEA.BusinessEntityID
        LEFT JOIN AdventureWorks2019.Person.Address A
            ON BEA.AddressID = A.AddressID
        LEFT JOIN AdventureWorks2019.Person.StateProvince SP
            ON A.StateProvinceID = SP.StateProvinceID
        LEFT JOIN AdventureWorks2019.Person.CountryRegion CR
            ON SP.CountryRegionCode = CR.CountryRegionCode
        WHERE C.ModifiedDate > @UltimaFecha;

        ------------------------------------------------------------
        -- 5. OBTENER NUEVA FECHA MÁXIMA CARGADA
        ------------------------------------------------------------
        SELECT @NuevaFecha = MAX(ModifiedDate)
        FROM STG.Cliente
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
