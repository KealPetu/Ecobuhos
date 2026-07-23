extends CharacterBody3D

## Orchestrator: owns no movement or input logic itself.
## Reads intent from InputComponent, hands it to MovementComponent,
## and decides *when* things happen each physics frame.



@export var camera_pivot: Node3D

@export_category("Player Components")
@export var input_component: InputComponent
@export var movement_component: MovementComponent


func _physics_process(delta: float) -> void:
	movement_component.apply_gravity(self, delta)

	if input_component.is_jump_pressed() and is_on_floor():
		movement_component.apply_jump(self)

	var input_dir := input_component.get_movement_vector()
	var basis := camera_pivot.global_transform.basis if camera_pivot else global_transform.basis
	var direction := (basis * Vector3(input_dir.x, 0, input_dir.y))
	direction.y = 0
	direction = direction.normalized()

	movement_component.apply_horizontal_movement(self, direction, delta)

	move_and_slide()


func _on_area_3d_body_entered(body: Node3D) -> void:
	pass # Replace with function body.


# Declaramos la señal que enviará el diccionario del inventario
signal inventario_cambiado(inventario: Dictionary)

var inventario: Dictionary = {
	"plastico": 0,
	"organico": 0,
	"papel": 0,
	"vidrio": 0,
	"metal": 0
}

func _ready() -> void:
	# Emitimos la señal al iniciar para que la interfaz se dibuje con los valores en 0
	inventario_cambiado.emit(inventario)
	if has_node("HUD"):
		inventario_cambiado.connect($HUD.actualizar_pantalla)
	
	# Emitimos el estado inicial
	inventario_cambiado.emit(inventario)

func agregar_al_inventario(tipo: String) -> void:
	if inventario.has(tipo):
		inventario[tipo] += 1
		# Notificamos a la interfaz que el inventario cambió
		inventario_cambiado.emit(inventario)
	else:
		print("Tipo de basura no registrado: ", tipo)

# También la emitimos si tiras o entregas basura al contenedor
func remover_del_inventario(tipo: String, cantidad: int = 1) -> bool:
	if inventario.has(tipo) and inventario[tipo] >= cantidad:
		inventario[tipo] -= cantidad
		inventario_cambiado.emit(inventario)
		return true
	return false
