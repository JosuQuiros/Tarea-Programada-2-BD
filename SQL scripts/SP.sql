CREATE PROCEDURE sp_EmpleadoSelect
    @inFilter NVARCHAR(32),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @inFilter IS NULL OR @inFilter = ''
            SELECT Id
            ,IdPuesto
            ,ValorDocumentoIdentidad
            ,Nombre
            ,FechaContratacion
            ,SaldoVacaciones
            ,EsActivo
            FROM dbo.Empleado AS E
            WHERE E.EsActivo = 1
            ORDER BY E.Nombre ASC;
        ELSE
            SELECT Id
            ,IdPuesto
            ,ValorDocumentoIdentidad
            ,Nombre
            ,FechaContratacion
            ,SaldoVacaciones
            ,EsActivo
            FROM dbo.Empleado AS E
            WHERE E.EsActivo = 1 
            AND E.Nombre LIKE '%' + @inFilter + '%'
            ORDER BY E.Nombre ASC;
        SET @outResultCode = 0;
    END TRY

    BEGIN CATCH
        SET @outResultCode = 50008; --Codigo de "error de base de datos" en el catalogo de errores
        INSERT INTO dbo.DBError (UserName
        ,Number
        ,State
        ,Severity
        ,Line
        ,[Procedure]
        ,Message
        ,DateTime)
        VALUES (USER_NAME()
        ,ERROR_NUMBER()
        ,ERROR_STATE()
        ,ERROR_SEVERITY()
        ,ERROR_LINE()
        ,ERROR_PROCEDURE()
        ,ERROR_MESSAGE()
        ,GETDATE());
    END CATCH
END;
go

CREATE PROCEDURE sp_EmpleadoDelete
    @inId INT,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE E
        SET E.EsActivo = 0
        FROM dbo.Empleado as E
        WHERE E.Id = @inId;
        SET @outResultCode = 0;
    END TRY

    BEGIN CATCH
        SET @outResultCode = 50008; --Codigo de "error de base de datos" en el catalogo de errores
        INSERT INTO dbo.DBError (UserName
        ,Number
        ,State
        ,Severity
        ,Line
        ,[Procedure]
        ,Message
        ,DateTime)
        VALUES (USER_NAME()
        ,ERROR_NUMBER()
        ,ERROR_STATE()
        ,ERROR_SEVERITY()
        ,ERROR_LINE()
        ,ERROR_PROCEDURE()
        ,ERROR_MESSAGE()
        ,GETDATE());
    END CATCH
END;
go

CREATE PROCEDURE sp_EmpleadoUpdate
    @inId INT,
    @inIdPuesto INT,
    @inValorDocumentoIdentidad INT,
    @inNombre VARCHAR(64),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @inValorDocumentoIdentidad = (
            SELECT ValorDocumentoIdentidad 
            FROM dbo.Empleado AS E 
            WHERE E.Id != @inId
            )
            SET @outResultCode = 50006;
            /*Codigo de "Empleado con ValorDocumentoIdentidad ya existe en actualizacion" 
            en el catalogo de errores*/

        ELSE IF @inNombre = (
            SELECT Nombre
            FROM dbo.Empleado AS E 
            WHERE E.Id != @inId
            )
            SET @outResultCode = 5007; 
            /*Codigo de "Empleado con mismo nombre ya existe en actualizacion" 
            en el catalogo de errores*/

        ELSE
            UPDATE E
            SET E.IdPuesto = @inIdPuesto,
                E.ValorDocumentoIdentidad = @inValorDocumentoIdentidad,
                E.Nombre = @inNombre
            FROM dbo.Empleado as E
            WHERE E.Id = @inId;
            SET @outResultCode = 0;

    END TRY
    BEGIN CATCH
        SET @outResultCode = 50008; --Codigo de "error de base de datos" en el catalogo de errores
        INSERT INTO dbo.DBError (UserName
        ,Number
        ,State
        ,Severity
        ,Line
        ,[Procedure]
        ,Message
        ,DateTime)
        VALUES (USER_NAME()
        ,ERROR_NUMBER()
        ,ERROR_STATE()
        ,ERROR_SEVERITY()
        ,ERROR_LINE()
        ,ERROR_PROCEDURE()
        ,ERROR_MESSAGE()
        ,GETDATE());
    END CATCH
END;
go

CREATE PROCEDURE sp_EmpleadoInsert
    @inIdPuesto INT,
    @inValorDocumentoIdentidad INT,
    @inNombre VARCHAR(64),
    @inFechaContratacion DATE,
    @inSaldoVacaciones INT,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF EXISTS(
            SELECT 1
            FROM dbo.Empleado AS E 
            WHERE E.ValorDocumentoIdentidad!= @inValorDocumentoIdentidad
            )
            SET @outResultCode = 5004;
            /*Codigo de ""Empleado con ValorDocumentoIdentidad ya existe en inserción" 
            en el catalogo de errores*/

        ELSE IF EXISTS(
            SELECT 1
            FROM dbo.Empleado AS E 
            WHERE E.Nombre != @inNombre
            )
            SET @outResultCode = 5005;
            /*Codigo de ""Empleado con mismo nombre ya existe en inserción" 
            en el catalogo de errores*/
        ELSE
        INSERT INTO dbo.Empleado (IdPuesto
        ,ValorDocumentoIdentidad
        ,Nombre
        ,FechaContratacion
        ,SaldoVacaciones
        ,EsActivo)
        VALUES (@inIdPuesto
        ,@inValorDocumentoIdentidad
        ,@inNombre
        ,@inFechaContratacion
        ,@inSaldoVacaciones
        ,1);
        SET @outResultCode = 0;

    END TRY
    BEGIN CATCH
        SET @outResultCode = 50008; --Codigo de "error de base de datos" en el catalogo de errores
        INSERT INTO dbo.DBError (
        UserName
        ,Number
        ,State
        ,Severity
        ,Line
        ,[Procedure]
        ,Message
        ,DateTime)
        VALUES (USER_NAME()
        ,ERROR_NUMBER()
        ,ERROR_STATE()
        ,ERROR_SEVERITY()
        ,ERROR_LINE()
        ,ERROR_PROCEDURE()
        ,ERROR_MESSAGE()
        ,GETDATE());
    END CATCH
END
go