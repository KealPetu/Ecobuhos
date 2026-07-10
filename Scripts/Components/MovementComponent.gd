class_name MovementComponent
extends Node

## Owns all movement math: gravity, jump, walking/deceleration.
## Doesn't know about input or cameras — it just takes a body and a
## desired direction each frame and moves the body accordingly.
## Doesn't call move_and_slide() itself; the orchestrator (Player) does,
## since that's a decision about *when* in the frame movement should resolve.

@export var speed := 5.0
@export var jump_velocity := 4.5


func apply_gravity(body: CharacterBody3D, delta: float) -> void:
	if not body.is_on_floor():
		body.velocity += body.get_gravity() * delta


func apply_jump(body: CharacterBody3D) -> void:
	body.velocity.y = jump_velocity


func apply_horizontal_movement(body: CharacterBody3D, direction: Vector3, delta: float) -> void:
	if direction:
		body.velocity.x = direction.x * speed
		body.velocity.z = direction.z * speed
	else:
		body.velocity.x = move_toward(body.velocity.x, 0, speed * delta)
		body.velocity.z = move_toward(body.velocity.z, 0, speed * delta)
