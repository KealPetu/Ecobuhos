extends Node3D

## Attach this to the CameraPivot node.
## Owns all camera concerns: mouse-look, yaw/pitch, spring arm collision.
## Knows nothing about player movement.

@export var mouse_sensitivity := 0.002
@export var min_pitch := -PI / 2.0   # how far down you can look
@export var max_pitch := PI / 2.0    # how far up you can look
@export var spring_length := 4.0
@export var collision_mask := 1

@export_group("FOV")
@export var change_fov_on_sprint := false
@export var normal_fov := 75.0
@export var sprint_fov := 90.0
const FOV_BLEND := 0.05

@onready var spring_arm: SpringArm3D = $SpringArm
@onready var camera: Camera3D = $SpringArm/Camera
@onready var player_body: CharacterBody3D = get_parent()

var pitch := 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	spring_arm.spring_length = spring_length
	spring_arm.collision_mask = collision_mask

	# Sin esto, el SpringArm detecta la propia cápsula de colisión del jugador
	# (porque el rayo nace dentro de ella) y colapsa su longitud casi a cero,
	# dando ese efecto de cámara en primera persona.
	if player_body:
		spring_arm.add_excluded_object(player_body.get_rid())

	camera.fov = normal_fov


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Yaw: rotate the whole pivot left/right.
		rotate_y(-event.relative.x * mouse_sensitivity)

		# Pitch: rotate only the spring arm up/down.
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, min_pitch, max_pitch)
		spring_arm.rotation.x = pitch

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = (
			Input.MOUSE_MODE_VISIBLE
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)


func _physics_process(_delta: float) -> void:
	if not change_fov_on_sprint:
		return

	var is_sprinting := player_body.is_on_floor() and Input.is_action_pressed("sprint")
	var target_fov := sprint_fov if is_sprinting else normal_fov
	camera.fov = lerp(camera.fov, target_fov, FOV_BLEND)
