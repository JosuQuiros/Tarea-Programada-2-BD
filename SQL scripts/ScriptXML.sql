
-- Script de carga de datos usando OPENROWSET + OPENXML
-- Habilitar OPENROWSET 
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO


-- SCRIPT PRINCIPAL DE CARGA-------------------------------------------------------------------------------------------------------------------------------

DECLARE @RutaArchivo VARCHAR(512) = 'C:\Users\josue\descargas\DatosOrdenados.xml';

-- Variables
DECLARE @xml XML;
DECLARE @hdoc INT;

-- Cargar el archivo XML
DECLARE @SQL NVARCHAR(MAX);
SET @SQL = 'SELECT @xml = CAST(BulkColumn AS XML) 
            FROM OPENROWSET(BULK ''' + @RutaArchivo + ''', SINGLE_BLOB) AS x';
EXEC sp_executesql @SQL, N'@xml XML OUTPUT', @xml OUTPUT;


PRINT 'XML cargado exitosamente';

-- Preparar el documento XML para OPENXML
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml;

BEGIN TRY
    -- 1. CARGAR PUESTOS
    PRINT 'Cargando Puestos...';
    
    INSERT INTO Puesto (Nombre, SalarioxHora)
    SELECT 
        Nombre,
        SalarioxHora
    FROM OPENXML(@hdoc, '/Datos/Puestos/Puesto', 2)
    WITH (
        Nombre VARCHAR(128) '@Nombre',
        SalarioxHora DECIMAL(10,2) '@SalarioxHora'
    );
    
    PRINT 'Puestos cargados: ' + CAST(@@ROWCOUNT AS VARCHAR(16));
    PRINT '';
    
    -- 2. CARGAR TIPOS DE EVENTO
    PRINT 'Cargando Tipos de Evento...';
    SET IDENTITY_INSERT TipoEvento ON;
    INSERT INTO TipoEvento (Id, Nombre)
    SELECT 
        Id,
        Nombre
    FROM OPENXML(@hdoc, '/Datos/TiposEvento/TipoEvento', 2)
    WITH (
        Id INT '@Id',
        Nombre VARCHAR(128) '@Nombre'
    );
    SET IDENTITY_INSERT TipoEvento OFF;
    
    PRINT 'Tipos de Evento cargados: ' + CAST(@@ROWCOUNT AS VARCHAR(16));
    PRINT '';

    -- 3. CARGAR TIPOS DE MOVIMIENTO
    PRINT 'Cargando Tipos de Movimiento...';
    SET IDENTITY_INSERT TipoMovimiento ON;
    INSERT INTO TipoMovimiento (Id, Nombre, TipoAccion)
    SELECT 
        Id,
        Nombre,
        TipoAccion
    FROM OPENXML(@hdoc, '/Datos/TiposMovimientos/TipoMovimiento', 2)
    WITH (
        Id INT '@Id',
        Nombre VARCHAR(128) '@Nombre',
        TipoAccion VARCHAR(64) '@TipoAccion'
    );
    
    SET IDENTITY_INSERT TipoMovimiento OFF;
    
    PRINT 'Tipos de Movimiento cargados: ' + CAST(@@ROWCOUNT AS VARCHAR(16));
    PRINT '';
    
    -- 4. CARGAR USUARIOS
    PRINT 'Cargando Usuarios...';
    SET IDENTITY_INSERT Usuario ON;
    INSERT INTO Usuario (Id, Username, Password)
    SELECT 
        Id,
        Nombre,
        Pass
    FROM OPENXML(@hdoc, '/Datos/Usuarios/usuario', 2)
    WITH (
        Id INT '@Id',
        Nombre VARCHAR(128) '@Nombre',
        Pass VARCHAR(128) '@Pass'
    );
    
    SET IDENTITY_INSERT Usuario OFF;
    
    PRINT 'Usuarios cargados: ' + CAST(@@ROWCOUNT AS VARCHAR(16));
    PRINT '';
    

    -- 5. CARGAR CATÁLOGO DE ERRORES
    PRINT 'Cargando Catálogo de Errores...';
    SET IDENTITY_INSERT Error ON;
    INSERT INTO Error (Id, Codigo, Descripcion)
    SELECT 
        Id,
        Codigo,
        Descripcion
    FROM OPENXML(@hdoc, '/Datos/Error/errorCodigo', 2)
    WITH (
        Id INT '@Id',
        Codigo VARCHAR(16) '@Codigo',
        Descripcion VARCHAR(512) '@Descripcion'
    );
    
    SET IDENTITY_INSERT Error OFF;
    
    PRINT 'Errores cargados: ' + CAST(@@ROWCOUNT AS VARCHAR(16));
    PRINT '';
   
    -- 6. CARGAR EMPLEADOS
    PRINT 'Cargando Empleados...';
    INSERT INTO Empleado (IdPuesto, ValorDocumentoIdentidad, Nombre, FechaContratacion, SaldoVacaciones, EsActivo)
    SELECT 
        P.Id,
        E.ValorDocumentoIdentidad,
        E.Nombre,
        E.FechaContratacion,
        0 AS SaldoVacaciones,
        1 AS EsActivo
    FROM OPENXML(@hdoc, '/Datos/Empleados/empleado', 2)
    WITH (
        Puesto VARCHAR(128) '@Puesto',
        ValorDocumentoIdentidad VARCHAR(64) '@ValorDocumentoIdentidad',
        Nombre VARCHAR(256) '@Nombre',
        FechaContratacion DATE '@FechaContratacion'
    ) AS E
    INNER JOIN Puesto P ON P.Nombre = E.Puesto;
    
    PRINT 'Empleados cargados: ' + CAST(@@ROWCOUNT AS VARCHAR(16));
    PRINT '';
    
    -- 7. INFORMACIÓN SOBRE MOVIMIENTOS
    -- Hay que usar el sp insertar movimiento (uno por uno) porque se debe actualizar el saldo
    
END TRY
BEGIN CATCH
    PRINT '';
    PRINT 'ERROR al cargar datos:';
    PRINT 'Mensaje: ' + ERROR_MESSAGE();
    PRINT 'Línea: ' + CAST(ERROR_LINE() AS VARCHAR(16));
    PRINT 'Procedimiento: ' + ISNULL(ERROR_PROCEDURE(), 'Script directo');
END CATCH

-- Liberar el documento XML
EXEC sp_xml_removedocument @hdoc;

PRINT '';
PRINT 'Documento XML liberado de memoria.';
GO


-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- STORED PROCEDURE PARA CARGAR MOVIMIENTOS

CREATE PROCEDURE SP_CargarMovimientosDesdeXML_OPENXML
    @RutaArchivo VARCHAR(512)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @xml XML;
    DECLARE @hdoc INT;
    DECLARE @Contador INT = 0;
    DECLARE @ErrorCount INT = 0;
    
    BEGIN TRY
        -- Cargar el archivo XML
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 'SELECT @xml = CAST(BulkColumn AS XML) 
                    FROM OPENROWSET(BULK ''' + @RutaArchivo + ''', SINGLE_BLOB) AS x';
        EXEC sp_executesql @SQL, N'@xml XML OUTPUT', @xml OUTPUT;
        
        -- Preparar el documento XML
        EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml;
        
        PRINT '========================================';
        PRINT 'Iniciando carga de Movimientos';
        PRINT '========================================';
        
        -- Variables para procesar movimientos
        DECLARE @ValorDocId VARCHAR(64);
        DECLARE @IdTipoMovimiento INT;
        DECLARE @Fecha DATE;
        DECLARE @Monto DECIMAL(10,2);
        DECLARE @PostByUser VARCHAR(128);
        DECLARE @PostInIP VARCHAR(64);
        DECLARE @PostTime DATETIME;
        DECLARE @IdEmpleado INT;
        DECLARE @IdUsuario INT;
        DECLARE @OutResultCode INT;
        
        -- Crear tabla temporal con los movimientos del XML usando OPENXML
        CREATE TABLE #TempMovimientos (
            RowNum INT IDENTITY(1,1) PRIMARY KEY,
            ValorDocId VARCHAR(64),
            IdTipoMovimiento INT,
            Fecha DATE,
            Monto DECIMAL(10,2),
            PostByUser VARCHAR(128),
            PostInIP VARCHAR(64),
            PostTime DATETIME
        );
        -- Insertar movimientos en tabla temporal
        INSERT INTO #TempMovimientos (ValorDocId, IdTipoMovimiento, Fecha, Monto, PostByUser, PostInIP, PostTime)
        SELECT 
            ValorDocId,
            IdTipoMovimiento,
            Fecha,
            Monto,
            PostByUser,
            PostInIP,
            PostTime
        FROM OPENXML(@hdoc, '/Datos/Movimientos/movimiento', 2)
        WITH (
            ValorDocId VARCHAR(64) '@ValorDocId',
            IdTipoMovimiento INT '@IdTipoMovimiento',
            Fecha DATE '@Fecha',
            Monto DECIMAL(10,2) '@Monto',
            PostByUser VARCHAR(128) '@PostByUser',
            PostInIP VARCHAR(64) '@PostInIP',
            PostTime DATETIME '@PostTime'
        );
        
        -- Liberar el documento XML
        EXEC sp_xml_removedocument @hdoc;
        
        DECLARE @TotalMovimientos INT;
        SELECT @TotalMovimientos = COUNT(*) FROM #TempMovimientos;
        PRINT 'Total de movimientos a cargar: ' + CAST(@TotalMovimientos AS VARCHAR(16));
        PRINT '';
        
        -- Procesar movimientos uno por uno
        WHILE EXISTS (SELECT 1 FROM #TempMovimientos)
        BEGIN
            -- Obtener el siguiente movimiento por orden
            SELECT TOP 1
                @ValorDocId = ValorDocId,
                @IdTipoMovimiento = IdTipoMovimiento,
                @Fecha = Fecha,
                @Monto = Monto,
                @PostByUser = PostByUser,
                @PostInIP = PostInIP,
                @PostTime = PostTime
            FROM #TempMovimientos
            ORDER BY RowNum;
            
            SET @Contador = @Contador + 1;
        
            -- Obtener IdEmpleado
            SELECT @IdEmpleado = Id FROM Empleado WHERE ValorDocumentoIdentidad = @ValorDocId;
            
            -- Obtener IdUsuario
            SELECT @IdUsuario = Id FROM Usuario WHERE Username = @PostByUser;
            
            IF @IdEmpleado IS NOT NULL AND @IdUsuario IS NOT NULL
            BEGIN
                -- Llamar al SP de insertar movimiento
                EXEC SP_InsertarMovimiento
                    @IdEmpleado = @IdEmpleado,
                    @IdTipoMovimiento = @IdTipoMovimiento,
                    @Fecha = @Fecha,
                    @Monto = @Monto,
                    @IdPostByUser = @IdUsuario,
                    @PostInIP = @PostInIP,
                    @PostTime = @PostTime,
                    @OutResultCode = @OutResultCode OUTPUT;
                
                IF @OutResultCode = 0
                BEGIN
                    IF @Contador % 10 = 0
                        PRINT 'Procesados: ' + CAST(@Contador AS VARCHAR(16)) + ' de ' + CAST(@TotalMovimientos AS VARCHAR(16));
                END
                ELSE
                BEGIN
                    SET @ErrorCount = @ErrorCount + 1;
                    PRINT 'ERROR en movimiento ' + CAST(@Contador AS VARCHAR(16)) + 
                          ' - ValorDocId: ' + @ValorDocId + 
                          ' - Código Error: ' + CAST(@OutResultCode AS VARCHAR(16));
                END
            END
            ELSE
            BEGIN
                SET @ErrorCount = @ErrorCount + 1;
                PRINT 'ERROR: No se encontró empleado o usuario para movimiento ' + CAST(@Contador AS VARCHAR(16));
            END
            
            -- Eliminar el movimiento procesado
            DELETE TOP (1) FROM #TempMovimientos WHERE ValorDocId = @ValorDocId AND Fecha = @Fecha;
        END
        
        -- Limpiar tabla temporal
        DROP TABLE #TempMovimientos;
        
        PRINT '';
        PRINT '========================================';
        PRINT 'Carga de movimientos completada';
        PRINT 'Total procesados: ' + CAST(@Contador AS VARCHAR(16));
        PRINT 'Exitosos: ' + CAST(@Contador - @ErrorCount AS VARCHAR(16));
        PRINT 'Errores: ' + CAST(@ErrorCount AS VARCHAR(16));
        PRINT '========================================';
        
    END TRY
    BEGIN CATCH
        -- Liberar documento XML si existe
        IF @hdoc IS NOT NULL
            EXEC sp_xml_removedocument @hdoc;
        
        -- Limpiar tabla temporal si existe
        IF OBJECT_ID('tempdb..#TempMovimientos') IS NOT NULL
            DROP TABLE #TempMovimientos;
        
        PRINT 'ERROR CRÍTICO al cargar movimientos:';
        PRINT 'Mensaje: ' + ERROR_MESSAGE();
        PRINT 'Línea: ' + CAST(ERROR_LINE() AS VARCHAR(16));
        
        THROW;
    END CATCH
END;
GO