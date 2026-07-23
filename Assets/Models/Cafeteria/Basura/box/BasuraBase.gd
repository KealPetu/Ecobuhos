extends Area3D

@export_enum("plastico", "organico", "vidrio", "papel", "metal") var tipo_basura: String = "plastico"

@export var velocidad_giro: float = 2.0
@export var flotar: bool = true
@export var velocidad_flotacion: float = 4.0
@export var altura_flotacion: float = 0.10

var tiempo_acumulado: float = 0.0
@onready var posicion_inicial_y: float = position.y
@onready var pivot_mesh: Node3D = $PivotMesh if has_node("PivotMesh") else null

func _ready() -> void:
	# Conectamos la señal 'body_entered' por código si no la has conectado desde la interfaz
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if pivot_mesh:
		pivot_mesh.rotate_y(velocidad_giro * delta)
	
	if flotar:
		tiempo_acumulado += delta * velocidad_flotacion
		position.y = posicion_inicial_y + (sin(tiempo_acumulado) * altura_flotacion)

func _on_body_entered(body: Node3D) -> void:
	# Imprime en la consola de Godot qué cuerpo acaba de colisionar
	print("Objeto entró en el área de basura: ", body.name)
	
	# Verificamos si el nodo o cuerpo que tocó la basura es o pertenece al Player
	if body.has_method("agregar_al_inventario"):
		body.agregar_al_inventario(tipo_basura)
		recolectar()
	elif body.get_parent() and body.get_parent().has_method("agregar_al_inventario"):
		body.get_parent().agregar_al_inventario(tipo_basura)
		recolectar()

func recolectar() -> void:
	print("¡Basura eliminada de la escena!")
	queue_free()
