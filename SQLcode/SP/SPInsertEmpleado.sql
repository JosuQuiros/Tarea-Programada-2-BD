CREATE PROCEDURE sp_EmpleadoInsert
    @IdPuesto INT,
    @ValorDocumentoIdentidad INT,
    @Nombre NVARCHAR(100),
    @FechaContratacion DATE,
    @SaldoVacaciones DECIMAL(10,2),
    @EsActivo BIT,
    @Result INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM Empleado WHERE ValorDocumentoIdentidad = @ValorDocumentoIdentidad OR Nombre = @Nombre)
            RAISERROR ('Duplicate entry', 16, 1);
        INSERT INTO Empleado (IdPuesto, ValorDocumentoIdentidad, Nombre, FechaContratacion, SaldoVacaciones, EsActivo)
        VALUES (@IdPuesto, @ValorDocumentoIdentidad, @Nombre, @FechaContratacion, @SaldoVacaciones, @EsActivo);
        SET @Result = 0;
    END TRY
    BEGIN CATCH
        SET @Result = ERROR_NUMBER();
        INSERT INTO DBError (UserName, Number, State, Severity, Line, Procedure, Message, DateTime)
        VALUES (SUSER_NAME(), ERROR_NUMBER(), ERROR_STATE(), ERROR_SEVERITY(), ERROR_LINE(), ERROR_PROCEDURE(), ERROR_MESSAGE(), GETDATE());
    END CATCH
END;