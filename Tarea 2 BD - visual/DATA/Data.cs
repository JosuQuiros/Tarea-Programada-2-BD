using Dapper;
using Microsoft.Data.SqlClient;
using System.Data;
using System.Text;
using static System.Runtime.InteropServices.JavaScript.JSType;

public class EmpleadoRepository
{
	private readonly string _connectionString;

	public EmpleadoRepository(IConfiguration config)
	{
		_connectionString = config.GetConnectionString("DefaultConnection");
	}

	public IEnumerable<Empleado> GetEmpleados()
	{
		using var connection = new SqlConnection(_connectionString);
		var parameters = new { inFilter = "" , outResultCode = 0 };
		return connection.Query<Empleado>("sp_EmpleadoSelect", parameters, commandType: System.Data.CommandType.StoredProcedure);
	}

	public int InsertEmpleado(string _Nombre, int _ValorDocumentoIdentidad)
	{
		using var connection = new SqlConnection(_connectionString);
		var parameters = new DynamicParameters();
		parameters.Add("@inIdPuesto", 1);
		parameters.Add("@inValorDocumentoIdentidad", _ValorDocumentoIdentidad);
		parameters.Add("@inNombre", _Nombre);
		parameters.Add("@outResultCode", dbType: DbType.Int32, direction: ParameterDirection.Output); // Output parameter
		StringBuilder errorMessages = new StringBuilder();
		try
		{
			connection.Execute("sp_EmpleadoInsert", parameters, commandType: System.Data.CommandType.StoredProcedure);
		}
		catch (SqlException ex)
		{
			for (int i = 0; i < ex.Errors.Count; i++)
			{
				errorMessages.Append("Index #" + i + "\n" +
					"Message: " + ex.Errors[i].Message + "\n" +
					"LineNumber: " + ex.Errors[i].LineNumber + "\n" +
					"Source: " + ex.Errors[i].Source + "\n" +
					"Procedure: " + ex.Errors[i].Procedure + "\n");
			}
			Console.WriteLine(errorMessages.ToString());
		}
		int output = parameters.Get<int>("@outResultCode");
		return output;

	}

}
