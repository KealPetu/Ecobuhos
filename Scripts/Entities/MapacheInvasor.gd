class_name MapacheInvasor
extends CharacterBody3D

## Antagonista: El Desordenador (Mapache Invasor)
## Se activa cuando el jugador comete errores o desde el inicio para probar la mecanica.

@export var movement_component: MovementComponent
@export var animation_player: AnimationPlayer
@export var waste_prefab: PackedScene
@export var throw_sound: AudioStream
@export var max_trash_per_activation: int = 5

var is_active: bool = false
var _is_defeated: bool = false
var _player_in_range: bool = false
var _target_pos: Vector3 = Vector3.ZERO
var _wander_timer: float = 0.0
var _throw_timer: float = 0.0
var _spawned_trash_this_activation: int = 0

@onready var label: Label3D = $Label3D if has_node("Label3D") else null
@onready var sfx: AudioStreamPlayer3D = $SfxPlayer if has_node("SfxPlayer") else null
@onready var interaction_area: Area3D = $InteractionArea if has_node("InteractionArea") else null

func _ready() -> void:
	add_to_group("mapache")
	# Escala removida de aquí para no romper las físicas de CharacterBody3D

	if not movement_component:
		push_warning("MapacheInvasor: 'movement_component' no está asignado en el inspector. El mapache no podrá moverse.")

	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_body_entered)
		interaction_area.body_exited.connect(_on_interaction_area_body_exited)
	else:
		push_warning("MapacheInvasor: no se encontró el nodo 'InteractionArea'. No se podrá derribar al mapache.")

	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)

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
	_is_defeated = false
	visible = true
	_spawned_trash_this_activation = 0
	_throw_timer = 0.0
	if animation_player:
		animation_player.play("chaos")
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

	if _is_defeated:
		# Detenido mientras se reproduce la animación "defeated"; no camina ni tira basura.
		if movement_component:
			movement_component.apply_gravity(self, delta)
			movement_component.apply_horizontal_movement(self, Vector3.ZERO)
			move_and_slide()
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

	if not movement_component:
		return

	movement_component.apply_gravity(self, delta)

	var dir: Vector3 = (_target_pos - global_position)
	dir.y = 0
	if dir.length() > 0.5:
		dir = dir.normalized()
		movement_component.apply_horizontal_movement(self, dir)
		movement_component.rotate_towards(self, dir, delta)
	else:
		movement_component.apply_horizontal_movement(self, Vector3.ZERO)

	move_and_slide()

func _on_interaction_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true

func _on_interaction_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false

## Llamado desde InteractionComponent cuando el jugador presiona "interact".
## Devuelve true si el mapache fue derribado en este intento.
func try_defeat() -> bool:
	if not is_active or _is_defeated or not _player_in_range:
		return false

	_is_defeated = true
	velocity = Vector3.ZERO
	_update_label(false)
	if label:
		label.visible = false

	if animation_player and animation_player.has_animation("defeated"):
		animation_player.play("defeated")
	else:
		# Sin animación disponible, ocultarlo directamente.
		_hide_and_wait()

	return true

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "defeated":
		_hide_and_wait()

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
	_is_defeated = false
	_player_in_range = false
	visible = false
	_throw_timer = 0.0
	_wander_timer = 0.0
	velocity = Vector3.ZERO
	_update_label(false)
	if label:
		label.visible = false

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

	if active:
		label.text = "🦝 ¡EL DESORDENADOR ATACA!"
		label.modulate = Color(1.0, 0.2, 0.2)
		label.visible = true
	else:
		label.text = "🦝 Mapache Invasor (Acechando...)"
		label.modulate = Color(0.85, 0.85, 0.85)
		label.visible = false
