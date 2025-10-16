using System.ComponentModel.DataAnnotations;

public class Empleado
{
	public int id { get; set; }
	public int? idPuesto { get; set; } //TO DO
	
	//[Required(ErrorMessage = "No puede ser dejado en blanco")]
	public int ValorDocumentoIdentidad { get; set; }

	//[Required(ErrorMessage = "No puede ser dejado en blanco")]
	//[RegularExpression(@"^[a-zA-Z\s\-]+$", ErrorMessage = "Solo letras y guiones.")]
	public string Nombre { get; set; }
	public string? FechaContratacion { get; set; }
	public int? SaldoVacaciones { get; set; }
	public bool EsActivo { get; set; } = true;
}
