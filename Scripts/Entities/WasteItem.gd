class_name WasteItem
extends RigidBody3D

## Pickable waste objects in the world

signal picked_up(waste_type: String)

@export_enum("organic", "plastic", "glass", "metal", "electronic", "paper") var waste_type: String = "organic"
@export var label_text: String = ""

var _can_pick: bool = true

@onready var label: Label3D = $Label3D if has_node("Label3D") else null

const EMOJI_NAMES: Dictionary = {
	"organic":    "🍌 Orgánico",
	"plastic":    "🥤 Plástico",
	"glass":      "🍾 Vidrio",
	"metal":      "🥫 Metal",
	"electronic": "🔋 Electrónico",
	"paper":      "📰 Papel"
}

func _ready() -> void:
	collision_layer = 4 # Common layer for waste
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
		if label_text != "":
			label.text = label_text
		else:
			label.text = EMOJI_NAMES.get(waste_type, waste_type)
	
	var mesh_node: CSGSphere3D = get_node_or_null("MeshInstance3D") as CSGSphere3D
	if mesh_node:
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		match waste_type:
			"organic":    mat.albedo_color = Color(0.95, 0.70, 0.10) # Naranja/Amarillo
			"plastic":    mat.albedo_color = Color(0.20, 0.55, 0.85) # Azul
			"glass":      mat.albedo_color = Color(0.30, 0.85, 0.95) # Celeste
			"metal":      mat.albedo_color = Color(0.90, 0.30, 0.20) # Rojo/Naranja
			"electronic": mat.albedo_color = Color(0.35, 0.35, 0.40) # Gris
			"paper":      mat.albedo_color = Color(0.95, 0.95, 0.95) # Blanco
		mesh_node.material = mat
