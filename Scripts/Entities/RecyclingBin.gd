class_name RecyclingBin
extends StaticBody3D

## Colored recycling containers the player deposits waste into

signal waste_received(waste_type: String, was_correct: bool)

@export_enum("organic", "plastic", "glass", "metal", "electronic", "paper") var accepts_type: String = "organic"
@export var bin_color: Color = Color.GREEN

var _is_highlighted: bool = false

@onready var label: Label3D = $Label3D if has_node("Label3D") else null
@onready var area: Area3D = $InteractionArea if has_node("InteractionArea") else null

const BIN_NAMES: Dictionary = {
	"organic":    "♻️ TACHO ORGÁNICO\n(Restos de comida)",
	"plastic":    "♻️ TACHO PLÁSTICO\n(Botellas, envases)",
	"glass":      "♻️ TACHO VIDRIO\n(Frascos, botellas)",
	"metal":      "♻️ TACHO METAL\n(Latas, conservas)",
	"electronic": "♻️ TACHO ELECTRÓNICO\n(Baterías, cables)",
	"paper":      "♻️ TACHO PAPEL\n(Periódicos, cartón)",
}

func _ready() -> void:
	add_to_group("recycling_bins")
	_update_label()
	_update_color()
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)

func try_deposit(inventory: InventoryComponent) -> bool:
	if inventory.get_count() > 0:
		var item: String = inventory.peek_first()
		var correct: bool = GameManager.deposit_waste(item, accepts_type)
		inventory.remove_item(item)
		waste_received.emit(item, correct)
		return true
	return false

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		set_highlight(true)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		set_highlight(false)

func set_highlight(on: bool) -> void:
	_is_highlighted = on
	var mesh_node: Node3D = get_node_or_null("MeshInstance3D") as Node3D
	if mesh_node:
		var target_scale: Vector3 = Vector3(1.18, 1.18, 1.18) if on else Vector3(1.0, 1.0, 1.0)
		var tw: Tween = create_tween()
		tw.tween_property(mesh_node, "scale", target_scale, 0.12)
	_update_label()

func _update_label() -> void:
	if not label:
		return
	var base_title: String = BIN_NAMES.get(accepts_type, accepts_type.capitalize())
	if _is_highlighted:
		label.text = "🎯 [E] DEPOSITAR AQUÍ\n" + base_title
		label.modulate = Color(1.0, 0.9, 0.2)
	else:
		label.text = base_title
		label.modulate = Color(1.0, 1.0, 1.0)

func _update_color() -> void:
	var mesh_node: CSGCylinder3D = get_node_or_null("MeshInstance3D") as CSGCylinder3D
	if mesh_node:
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		match accepts_type:
			"organic":    mat.albedo_color = Color(0.15, 0.68, 0.37) # Verde
			"plastic":    mat.albedo_color = Color(0.16, 0.50, 0.72) # Azul
			"glass":      mat.albedo_color = Color(0.20, 0.80, 0.90) # Celeste
			"metal":      mat.albedo_color = Color(0.95, 0.61, 0.07) # Naranja/Amarillo
			"electronic": mat.albedo_color = Color(0.40, 0.40, 0.45) # Gris
			"paper":      mat.albedo_color = Color(0.90, 0.90, 0.90) # Blanco
		mesh_node.material = mat
