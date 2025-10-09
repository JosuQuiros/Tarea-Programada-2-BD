CREATE PROCEDURE sp_EmpleadoUpdate
    @Id INT,
    @IdPuesto INT,
    @ValorDocumentoIdentidad INT,
    @Nombre NVARCHAR(100),
    @FechaContratacion DATE,
    @EsActivo BIT,
    @Result INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM Empleado WHERE (ValorDocumentoIdentidad = @ValorDocumentoIdentidad OR Nombre = @Nombre) AND Id != @Id)
            RAISERROR ('Duplicate entry', 16, 1);
        UPDATE Empleado
        SET IdPuesto = @IdPuesto,
            ValorDocumentoIdentidad = @ValorDocumentoIdentidad,
            Nombre = @Nombre,
            FechaContratacion = @FechaContratacion,
            EsActivo = @EsActivo
        WHERE Id = @Id;
        SET @Result = 0;
    END TRY
    BEGIN CATCH
        SET @Result = ERROR_NUMBER();
        INSERT INTO DBError (UserName, Number, State, Severity, Line, Procedure, Message, DateTime)
        VALUES (SUSER_NAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE(), GETDATE());
    END CATCH
END;