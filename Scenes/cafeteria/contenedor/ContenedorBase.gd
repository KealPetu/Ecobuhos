extends Node3D

# Categorías disponibles que coinciden con tu inventario
@export_enum("plastico", "metal", "vidrio", "papel", "organico") var tipo_permitido: String = "plastico"

@onready var area_deteccion: Area3D = $AreaDeteccion

func _ready() -> void:
	# Conectamos la señal para detectar cuándo entra el jugador
	if area_deteccion:
		area_deteccion.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	# Identificamos si el cuerpo es el Player (o si su nodo padre lo es)
	var jugador = null
	if body.has_method("remover_del_inventario"):
		jugador = body
	elif body.get_parent() and body.get_parent().has_method("remover_del_inventario"):
		jugador = body.get_parent()

	if jugador:
		depositar_basura(jugador)

func depositar_basura(jugador) -> void:
	# Intentamos quitar 1 unidad del tipo que acepta este contenedor
	if jugador.remover_del_inventario(tipo_permitido, 1):
		print("¡Éxito! Depositaste 1 de ", tipo_permitido, " en el contenedor.")
		reproducir_efecto_exito()
	else:
		print("No tienes ", tipo_permitido, " en tu inventario.")

func reproducir_efecto_exito() -> void:
	# Aquí puedes agregar un sonido (AudioStreamPlayer3D), partículas, etc.
	pass
