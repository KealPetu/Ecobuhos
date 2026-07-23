class_name MovementComponent
extends Node

## Owns all movement math: gravity, jump, walking/deceleration.
## Doesn't know about input or cameras — it just takes a body and a
## desired direction each frame and moves the body accordingly.
## Doesn't call move_and_slide() itself; the orchestrator (Player) does,
## since that's a decision about *when* in the frame movement should resolve.

@export var speed := 5.0
@export var sprint_speed := 8.0
@export var jump_velocity := 4.5
@export var rotation_speed := 10.0 ## Que tan rápido gira el modelo hacia la dirección de movimiento.

func apply_gravity(body: CharacterBody3D, delta: float) -> void:
	if not body.is_on_floor():
		body.velocity += body.get_gravity() * delta


func apply_jump(body: CharacterBody3D) -> void:
	body.velocity.y = jump_velocity


func apply_horizontal_movement(body: CharacterBody3D, direction: Vector3, is_sprinting: bool = false) -> void:
	if direction:
		var current_speed := sprint_speed if is_sprinting else speed
		body.velocity.x = direction.x * current_speed
		body.velocity.z = direction.z * current_speed
	else:
		body.velocity.x = 0
		body.velocity.z = 0


## Gira suavemente el modelo visual (no el CharacterBody3D) para que mire
## hacia la dirección en la que se está moviendo el jugador.
func rotate_towards(model: Node3D, direction: Vector3, delta: float) -> void:
	if direction.length() < 0.01:
		return
	var target_angle := atan2(-direction.z, direction.x)
	model.rotation.y = lerp_angle(model.rotation.y, target_angle, rotation_speed * delta)
