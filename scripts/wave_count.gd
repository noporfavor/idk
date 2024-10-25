extends Label

var current_wave = 0

func update_wave_counter():
	current_wave += 1
	# Actualiza el texto con el formato deseado
	text = "OLEADA " + ordinal(current_wave)
	
# Función para convertir el número a su forma ordinal
func ordinal(number: int) -> String:
	match number:
		1: return "UNO"
		2: return "DOS"
		3: return "TRES"
		4: return "CUATRO"
		5: return "CINCO"
		6: return "SEIS"
		7: return "SIETE"
		8: return "OCHO"
		9: return "NUEVE"
		10: return "DIEZ"
		# Agrega más según sea necesario
		_ : return str(number)  # Para números mayores a 10
