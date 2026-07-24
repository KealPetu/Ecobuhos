class_name WasteItem
extends RigidBody3D

signal picked_up(waste_type: String)

@export_enum("organic", "plastic", "glass", "metal", "electronic", "paper") var waste_type: String = "organic"
@export var label_text: String = ""

var _can_pick: bool = true

@onready var label: Label3D = $Label3D if has_node("Label3D") else null
@onready var model_holder: Node3D = $ModelHolder if has_node("ModelHolder") else null

const EMOJI_NAMES: Dictionary = {
	"organic":    "🍌 Orgánico",
	"plastic":    "🥤 Plástico",
	"glass":      "🍾 Vidrio",
	"metal":      "🥫 Metal",
	"electronic": "🔋 Electrónico",
	"paper":      "📰 Papel"
}

# Cada tipo tiene una o varias rutas -> se elige una al azar al instanciar
const WASTE_MODELS: Dictionary = {
	"organic": [
		{"scene": "res://Assets/Models/Cafeteria/Basura/food_1/scene.gltf", "scale": Vector3(0.003, 0.003, 0.003)},
		{"scene": "res://Assets/Models/Cafeteria/Basura/food_2/scene.gltf", "scale": Vector3(0.003, 0.003, 0.003)},
	],
	"plastic": [
		{"scene": "res://Assets/Models/Cafeteria/Basura/plastic_bottle/scene.gltf", "scale": Vector3(17.0, 17.0, 17.0)},
	],
	"glass": [
		{"scene": "res://Assets/Models/Cafeteria/Basura/glass_bottle_1/scene.gltf", "scale": Vector3(0.08, 0.08, 0.08)},
		{"scene": "res://Assets/Models/Cafeteria/Basura/glass_bottle_2/scene.gltf", "scale": Vector3(0.25, 0.25, 0.25)},
	],
	"metal": [
		{"scene": "res://Assets/Models/Cafeteria/Basura/can_1/scene.gltf", "scale": Vector3(3.0, 3.0, 3.0)},
		{"scene": "res://Assets/Models/Cafeteria/Basura/can_2/scene.gltf", "scale": Vector3(0.002, 0.002, 0.002)},
	],
	"paper": [
		{"scene": "res://Assets/Models/Cafeteria/Basura/paper/scene.gltf", "scale": Vector3(3.0, 3.0, 3.0)},
		{"scene": "res://Assets/Models/Cafeteria/Basura/box/scene.gltf", "scale": Vector3(0.18, 0.18, 0.18)},
	],
	"electronic": [{"scene": "res://Assets/Models/Cafeteria/Basura/wire_1/bunch_of_electric_wires.glb", "scale": Vector3(0.05, 0.05, 0.05)}]
}

func _ready() -> void:
	collision_layer = 4
	add_to_group("waste_items")
	_update_visuals()

func pick() -> String:
	if _can_pick:
		_can_pick = false
		set_deferred("freeze", true)
		hide()
		picked_up.emit(waste_type)
		return waste_type
	return ""

func respawn_at(pos: Vector3) -> void:
	global_position = pos
	set_deferred("freeze", false)
	show()
	_can_pick = true

func _update_visuals() -> void:
	if label:
		label.text = label_text if label_text != "" else EMOJI_NAMES.get(waste_type, waste_type)
	_update_model()

func _update_model() -> void:
	if not model_holder:
		return

	for child in model_holder.get_children():
		child.queue_free()

	var options: Array = WASTE_MODELS.get(waste_type, [])
	if options.is_empty():
		return

	var entry: Dictionary = options.pick_random()
	var path: String = entry.get("scene", "")
	if not ResourceLoader.exists(path):
		push_warning("WasteItem: no se encontró el modelo %s" % path)
		return

	var packed: PackedScene = load(path) as PackedScene
	if packed:
		var instance: Node3D = packed.instantiate() as Node3D
		if instance:
			instance.scale = entry.get("scale", Vector3.ONE)
			model_holder.add_child(instance)
