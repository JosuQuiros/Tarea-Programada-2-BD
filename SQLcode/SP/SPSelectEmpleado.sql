CREATE PROCEDURE sp_EmpleadoSelect
    @Id INT,
    @Result INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT Id, IdPuesto, ValorDocumentoIdentidad, Nombre, FechaContratacion, SaldoVacaciones, EsActivo
        FROM Empleado
        WHERE Id = @Id AND EsActivo = 1;
        SET @Result = 0;
    END TRY
    BEGIN CATCH
        SET @Result = ERROR_NUMBER();
        INSERT INTO DBError (UserName, Number, State, Severity, Line, Procedure, Message, DateTime)
        VALUES (SUSER_NAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE(), GETDATE());
    END CATCH
END;