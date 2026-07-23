class_name InputComponent
extends Node

## Isolates raw input reading. Player never touches the Input singleton directly —
## it asks this component instead. Swap this out (e.g. for an AIInputComponent
## exposing the same two methods) to drive the same Player with AI or a replay system.


func get_movement_vector() -> Vector2:
	return Input.get_vector("left", "right", "forward", "backwards")


func is_jump_pressed() -> bool:
	return Input.is_action_just_pressed("jump")


func is_sprint_pressed() -> bool:
	return Input.is_action_pressed("sprint")
