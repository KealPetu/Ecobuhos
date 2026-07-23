class_name WasteSpawner
extends Node3D

## Spawns WasteItem nodes at marked positions with escalating difficulty

@export var waste_scene: PackedScene
@export var spawn_points: Array[Node3D] = []
@export var initial_count: int = 8
@export var wave_interval: float = 20.0
@export var waste_types: Array[String] = ["organic", "plastic", "glass", "metal"]

var _active_waste: Array[WasteItem] = []
var _wave_timer: float = 0.0
var _wave_number: int = 0

func _ready() -> void:
	spawn_wave()

func _process(delta: float) -> void:
	_wave_timer += delta
	if _wave_timer >= wave_interval:
		_wave_timer = 0.0
		spawn_wave()

func spawn_wave() -> void:
	_wave_number += 1
	var to_spawn = initial_count
	
	for i in range(to_spawn):
		if waste_scene and spawn_points.size() > 0:
			var point = spawn_points.pick_random()
			var instance: WasteItem = waste_scene.instantiate() as WasteItem
			if instance:
				var wtype: String = waste_types.pick_random()
				instance.waste_type = wtype
				instance.label_text = get_waste_label(wtype)
				
				instance.global_position = point.global_position
				add_child(instance)
				_active_waste.append(instance)
				
				instance.picked_up.connect(_on_waste_picked_up.bind(instance))

func _on_waste_picked_up(waste_type: String, waste_item: WasteItem) -> void:
	if _active_waste.has(waste_item):
		_active_waste.erase(waste_item)
	
	if _active_waste.size() < initial_count / 2.0:
		get_tree().create_timer(5.0).timeout.connect(_respawn_waste.bind(waste_item))

func _respawn_waste(waste_item: WasteItem) -> void:
	if is_instance_valid(waste_item) and spawn_points.size() > 0:
		var point = spawn_points.pick_random()
		waste_item.respawn_at(point.global_position)
		_active_waste.append(waste_item)

func get_waste_label(type: String) -> String:
	match type:
		"organic": return "Cascara"
		"plastic": return "Botella"
		"glass": return "Vidrio"
		"metal": return "Lata"
		"electronic": return "Bateria"
		"paper": return "Papel"
	return "Basura"
