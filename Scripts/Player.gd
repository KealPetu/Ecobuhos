extends CharacterBody3D

## Orchestrator: owns movement, input logic, inventory, interaction, and stun effects.

@onready var camera_pivot: Node3D = $CameraPivot
## Nodo visual que se rota hacia la dirección de movimiento (NO el CharacterBody3D,
## para no arrastrar la cámara con él). Normalmente el nodo "Armature".
@onready var character_model: Node3D = $Armature/Skeleton3D/Ecobuho
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export_category("Player Components")
@export var input_component: InputComponent
@export var movement_component: MovementComponent
@export var inventory_component: InventoryComponent
@export var interaction_component: InteractionComponent


var is_stunned: bool = false
var _stun_timer: float = 0.0

var _stun_label: Label3D

func _ready() -> void:
	add_to_group("player")
	if GameManager:
		GameManager.player_stunned.connect(_on_player_stunned)
		
	# Crear indicador visual de stun sobre la cabeza del buho
	_stun_label = Label3D.new()
	_stun_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_stun_label.text = "⚡ ¡CONGELADO! 💫"
	_stun_label.font_size = 40
	_stun_label.outline_size = 10
	_stun_label.outline_modulate = Color(0, 0, 0)
	_stun_label.modulate = Color(1.0, 0.85, 0.1)
	_stun_label.position = Vector3(0, 2.2, 0)
	_stun_label.visible = false
	add_child(_stun_label)

func _process(delta: float) -> void:
	if is_stunned:
		_stun_timer -= delta
		if _stun_label:
			_stun_label.visible = true
			# Animacion flotante y oscilante sobre la cabeza
			var ticks: float = float(Time.get_ticks_msec()) * 0.01
			_stun_label.position.y = 2.2 + sin(ticks) * 0.12
			_stun_label.rotation.z = sin(ticks * 0.8) * 0.15
		if _stun_timer <= 0:
			is_stunned = false
			if _stun_label:
				_stun_label.visible = false

func _on_player_stunned(duration: float, _reason: String) -> void:
	is_stunned = true
	_stun_timer = duration
	velocity = Vector3.ZERO
	if _stun_label:
		_stun_label.visible = true

func _physics_process(delta: float) -> void:
	movement_component.apply_gravity(self, delta)

	# Si el jugador esta congelado por contaminacion cruzada, no puede moverse
	if is_stunned:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	if input_component.is_jump_pressed() and is_on_floor():
		movement_component.apply_jump(self)

	var input_dir := input_component.get_movement_vector()
	var basis := camera_pivot.global_transform.basis if camera_pivot else global_transform.basis
	var direction := (basis * Vector3(input_dir.x, 0, input_dir.y))
	direction.y = 0
	direction = direction.normalized()
	
	var is_moving := direction.length() > 0.01
	var is_sprinting := is_moving and input_component.is_sprint_pressed()
 
	movement_component.apply_horizontal_movement(self, direction, is_sprinting)
 
	if character_model:
		movement_component.rotate_towards(character_model, direction, delta)
 
	_update_animation(is_moving, is_sprinting)
	
	move_and_slide()


func _update_animation(is_moving: bool, is_sprinting: bool) -> void:
	if not animation_player:
		return
		
	var anim_to_play := "idle"
	if not is_on_floor():
		anim_to_play = "on_air"
	elif is_moving:
		anim_to_play = "running" if is_sprinting else "walk"
 
	if animation_player.current_animation != anim_to_play:
		animation_player.play(anim_to_play)
