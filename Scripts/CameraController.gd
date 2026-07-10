extends Node3D

## Attach this to the CameraPivot node.
## Owns all camera concerns: mouse-look, yaw/pitch, spring arm collision.
## Knows nothing about player movement.

@export var mouse_sensitivity := 0.002
@export var min_pitch := -PI / 3.0   # how far down you can look
@export var max_pitch := PI / 2.0    # how far up you can look
@export var spring_length := 4.0
@export var collision_mask := 1

@onready var spring_arm: SpringArm3D = $SpringArm

var pitch := 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	spring_arm.spring_length = spring_length
	spring_arm.collision_mask = collision_mask


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
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
