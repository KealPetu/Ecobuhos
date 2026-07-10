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
