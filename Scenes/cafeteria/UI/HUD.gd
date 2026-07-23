extends CanvasLayer

@onready var label_inventario: Label = $PanelContainer/MarginContainer/LabelInventario

# Esta función se llamará cada vez que el inventario cambie
func actualizar_pantalla(inventario: Dictionary) -> void:
	var texto_interfaz: String = "RESIDUOS RECOLECTADOS:\n"
	
	# Recorremos cada tipo de basura en el diccionario
	for tipo in inventario.keys():
		var cantidad: int = inventario[tipo]
		# capitalize() convierte "plastico" en "Plastico" para que se vea más pulido
		texto_interfaz += "• " + tipo.capitalize() + ": " + str(cantidad) + "\n"
	
	label_inventario.text = texto_interfaz
