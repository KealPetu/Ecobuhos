class_name MapacheInvasor
extends CharacterBody3D

## Antagonista: El Desordenador (Mapache Invasor)
## Se activa cuando el jugador comete errores o desde el inicio para probar la mecanica.

@export var move_speed: float = 2.5
@export var waste_prefab: PackedScene
@export var throw_sound: AudioStream
@export var max_trash_per_activation: int = 5

var is_active: bool = false
var _target_pos: Vector3 = Vector3.ZERO
var _wander_timer: float = 0.0
var _throw_timer: float = 0.0
var _spawned_trash_this_activation: int = 0

@onready var label: Label3D = $Label3D if has_node("Label3D") else null
@onready var sfx: AudioStreamPlayer3D = $SfxPlayer if has_node("SfxPlayer") else null
@onready var collision_area: Area3D = $CollisionArea if has_node("CollisionArea") else null
@onready var collision_shape: CollisionShape3D = $CollisionArea/CollisionShape if has_node("CollisionArea/CollisionShape") else null

func _ready() -> void:
	add_to_group("mapache")
	# Escala removida de aquí para no romper las físicas de CharacterBody3D
	
	if GameManager:
		GameManager.mapache_activated.connect(_on_mapache_activated)
	
	# Inicia oculto, se activa con 2 errores
	visible = false
	is_active = false
	_update_label(false)
	if label:
		label.visible = false

func _get_player_node() -> Node3D:
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		return players[0] as Node3D
	
	var scene = get_tree().current_scene
	if scene:
		var p_node = scene.find_child("Player", true, false)
		if p_node and p_node is Node3D: return p_node as Node3D
		p_node = scene.find_child("Max", true, false)
		if p_node and p_node is Node3D: return p_node as Node3D
		
		for child in scene.get_children():
			if child is CharacterBody3D and child != self:
				return child as Node3D
	return null

func _on_mapache_activated(spawn_position: Vector3 = Vector3.ZERO) -> void:
	if is_active: return
	is_active = true
	visible = true
	_set_hitbox_hidden(false)
	_spawned_trash_this_activation = 0
	_throw_timer = 0.0
	if GameManager:
		GameManager.error_count = 0
	_update_label(true)
	if label:
		label.visible = true
	if spawn_position != Vector3.ZERO:
		global_position = spawn_position + Vector3(0, 2.0, 0)
	else:
		var p = _get_player_node()
		if p:
			var forward = -p.global_transform.basis.z.normalized()
			if forward.length() < 0.1:
				forward = Vector3(0, 0, -1)
			global_position = p.global_position + (forward * 3.5) + Vector3(0, 0.5, 0)
		else:
			var cam = get_viewport().get_camera_3d()
			if cam:
				global_position = cam.global_position - cam.global_transform.basis.z * 4.0
				global_position.y = max(0.5, global_position.y)
			else:
				global_position = Vector3(0, 1.0, 0)
		
	_pick_new_wander_target()

func _physics_process(delta: float) -> void:
	if not is_active:
		return

	_wander_timer -= delta
	if _wander_timer <= 0:
		_pick_new_wander_target()

	_throw_timer -= delta
	if _throw_timer <= 0:
		_spawn_extra_trash()
		_spawned_trash_this_activation += 1
		if _spawned_trash_this_activation >= max_trash_per_activation:
			_hide_and_wait()
			return
		_throw_timer = randf_range(2.5, 4.0)

	velocity.y = 0

	var dir: Vector3 = (_target_pos - global_position)
	dir.y = 0
	if dir.length() > 0.5:
		dir = dir.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		look_at(Vector3(_target_pos.x, global_position.y, _target_pos.z), Vector3.UP)
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

func _pick_new_wander_target() -> void:
	_wander_timer = randf_range(2.0, 4.0)
	var p = _get_player_node()
	if p:
		_target_pos = p.global_position + Vector3(randf_range(-3.0, 3.0), 0, randf_range(-3.0, 3.0))
	else:
		_target_pos = global_position + Vector3(randf_range(-5.0, 5.0), 0, randf_range(-5.0, 5.0))

func _spawn_extra_trash() -> void:
	if not waste_prefab:
		waste_prefab = load("res://Scenes/Prefabs/WasteItem.tscn")
	if waste_prefab and get_parent():
		var new_waste = waste_prefab.instantiate() as WasteItem
		if new_waste:
			var types = ["organic", "plastic", "glass", "metal", "paper"]
			var random_type = types[randi() % types.size()]
			new_waste.waste_type = random_type
			get_parent().add_child(new_waste)
			if GameManager:
				GameManager.add_level_waste(1)
			var random_offset = Vector3(randf_range(-0.3, 0.3), 1.2, randf_range(-0.3, 0.3))
			new_waste.global_position = global_position + random_offset
			
			var throw_dir: Vector3 = -global_transform.basis.z + Vector3(0, 1.8, 0)
			throw_dir = throw_dir.normalized()
			var throw_force: float = randf_range(4.5, 6.5)
			new_waste.apply_central_impulse(throw_dir * throw_force)
			
			if sfx and throw_sound:
				sfx.stream = throw_sound
				sfx.play()

func _hide_and_wait() -> void:
	is_active = false
	visible = false
	_set_hitbox_hidden(true)
	_throw_timer = 0.0
	_wander_timer = 0.0
	velocity = Vector3.ZERO
	_update_label(false)
	if label:
		label.visible = false

func _set_hitbox_hidden(hidden: bool) -> void:
	if collision_area:
		if hidden:
			collision_area.global_position = Vector3(0, 20, 0)
			collision_area.monitoring = false
			collision_area.monitorable = false
		else:
			collision_area.monitoring = true
			collision_area.monitorable = true
			collision_area.global_position = global_position
	if collision_shape:
		collision_shape.disabled = hidden

func _update_label(active: bool) -> void:
	if not label:
		label = Label3D.new()
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.font_size = 56
		label.pixel_size = 0.008
		label.outline_size = 12
		label.outline_modulate = Color(0, 0, 0)
		label.position = Vector3(0, 1.8, 0)
		add_child(label)
		
	if has_node("DebugBox"):
		get_node("DebugBox").visible = active

	if active:
		label.text = "🦝 ¡EL DESORDENADOR ATACA!"
		label.modulate = Color(1.0, 0.2, 0.2)
		label.visible = true
	else:
		label.text = "🦝 Mapache Invasor (Acechando...)"
		label.modulate = Color(0.85, 0.85, 0.85)
		label.visible = false
