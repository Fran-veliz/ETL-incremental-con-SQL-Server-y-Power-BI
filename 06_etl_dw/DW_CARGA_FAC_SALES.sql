USE AventureWorks_DWH;
GO

CREATE OR ALTER PROCEDURE DW.sp_Carga_Fact_Sales
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------------
    -- 1. VARIABLES DE CONTROL
    ------------------------------------------------------------
    DECLARE 
        @Proceso NVARCHAR(100) = 'DW_FACT_SALES',
        @BatchID UNIQUEIDENTIFIER = NEWID(),
        @RowsAffected INT = 0;

    BEGIN TRY
        -- Auditoría inicial
        MERGE ETL.Control_Carga AS T
        USING (SELECT @Proceso AS Proceso) AS S
        ON T.Proceso = S.Proceso
        WHEN MATCHED THEN 
            UPDATE SET Estado = 'EN PROCESO', FechaInicio = GETDATE(), BatchID = @BatchID
        WHEN NOT MATCHED THEN 
            INSERT (Proceso, BatchID, Estado, FechaInicio)
            VALUES (@Proceso, @BatchID, 'EN PROCESO', GETDATE());

        ------------------------------------------------------------
        -- 2. CARGA DE HECHOS (TRANSFORMACIÓN Y BUSQUEDA)
        ------------------------------------------------------------
        -- Nota: Aquí unimos la fuente de ventas con las dimensiones ya cargadas
        INSERT INTO DW.Fact_Sales (
            DateKey, ProductKey, ClientKey, SalesPersonKey, 
            TerritoryKey, PromotionKey, SalesOrderID_Source, 
            OrderQty, UnitPrice, UnitPriceDiscount, LineTotal, FechaCarga
        )
        SELECT 
            T.DateKey,
            P.ProductKey,
            C.ClienteKey, -- Asegúrate que el nombre coincida con tu tabla Dim_Cliente
            ISNULL(S.SalesPersonKey, -1), -- Si no hay vendedor, asignamos -1
            TR.TerritoryKey,
            PR.PromotionKey,
            STG.SalesOrderID,
            STG.OrderQty,
            STG.UnitPrice,
            STG.UnitPriceDiscount,
            STG.LineTotal,
            GETDATE()
        FROM AdventureWorks2019.Sales.SalesOrderDetail STG
        INNER JOIN AdventureWorks2019.Sales.SalesOrderHeader H 
            ON STG.SalesOrderID = H.SalesOrderID
 
        INNER JOIN DW.Dim_Tiempo T ON CAST(FORMAT(H.OrderDate,'yyyyMMdd') AS INT) = T.DateKey
        INNER JOIN DW.Dim_Product P ON STG.ProductID = P.ProductID_Source
        INNER JOIN DW.Dim_Cliente C ON H.CustomerID = C.CustomerID_Source
        LEFT JOIN DW.Dim_SalesPerson S ON H.SalesPersonID = S.SalesPersonID_Source
        INNER JOIN DW.Dim_Territory TR ON H.TerritoryID = TR.TerritoryID_Source
        INNER JOIN DW.Dim_Promotion PR ON STG.SpecialOfferID = PR.PromotionID_Source
        -- Evitar duplicados si volvemos a correr la carga
        WHERE NOT EXISTS (
            SELECT 1 FROM DW.Fact_Sales F 
            WHERE F.SalesOrderID_Source = STG.SalesOrderID 
            AND F.ProductKey = P.ProductKey
        );

        SET @RowsAffected = @@ROWCOUNT;

        -- Auditoría final
        UPDATE ETL.Control_Carga
        SET Estado = 'OK', FechaFin = GETDATE(), MensajeError = 'Ventas cargadas: ' + CAST(@RowsAffected AS VARCHAR)
        WHERE Proceso = @Proceso;

    END TRY
    BEGIN CATCH
        UPDATE ETL.Control_Carga
        SET Estado = 'ERROR', FechaFin = GETDATE(), MensajeError = ERROR_MESSAGE()
        WHERE Proceso = @Proceso;
        THROW;
    END CATCH
END;
GO