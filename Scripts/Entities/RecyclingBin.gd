class_name RecyclingBin
extends StaticBody3D

## Colored recycling containers the player deposits waste into

signal waste_received(waste_type: String, was_correct: bool)

@export_enum("organic", "plastic", "glass", "metal", "electronic", "paper") var accepts_type: String = "organic"
@export var bin_color: Color = Color.GREEN

var _is_highlighted: bool = false

@onready var label: Label3D = $Label3D if has_node("Label3D") else null
@onready var area: Area3D = $InteractionArea if has_node("InteractionArea") else null
@onready var model_holder: Node3D = $ModelHolder if has_node("ModelHolder") else null

const BIN_NAMES: Dictionary = {
	"organic":    "♻️ TACHO ORGÁNICO\n(Restos de comida)",
	"plastic":    "♻️ TACHO PLÁSTICO\n(Botellas, envases)",
	"glass":      "♻️ TACHO VIDRIO\n(Frascos, botellas)",
	"metal":      "♻️ TACHO METAL\n(Latas, conservas)",
	"electronic": "♻️ TACHO ELECTRÓNICO\n(Baterías, cables)",
	"paper":      "♻️ TACHO PAPEL\n(Periódicos, cartón)",
}

const BIN_MODEL_PATH: String = "res://Assets/Models/Cafeteria/contenedor/trash_can/scene.gltf"

const BIN_COLORS: Dictionary = {
	"organic":    Color(0.15, 0.68, 0.37),
	"plastic":    Color(0.16, 0.50, 0.72),
	"glass":      Color(0.20, 0.80, 0.90),
	"metal":      Color(0.95, 0.61, 0.07),
	"electronic": Color(0.40, 0.40, 0.45),
	"paper":      Color(0.90, 0.90, 0.90),
}

const BIN_SCALES: Dictionary = {
	"organic":    Vector3(0.6, 0.6, 0.6),
	"plastic":    Vector3(0.6, 0.6, 0.6),
	"glass":      Vector3(0.6, 0.6, 0.6),   
	"metal":      Vector3(0.6, 0.6, 0.6),
	"electronic": Vector3(0.6, 0.6, 0.6),   
	"paper":      Vector3(0.6, 0.6, 0.6),   
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
		var correct: bool = GameManager.deposit_waste(item, accepts_type, global_position)
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
	if model_holder:
		var target_scale: Vector3 = Vector3(1.18, 1.18, 1.18) if on else Vector3(1.0, 1.0, 1.0)
		var tw: Tween = create_tween()
		tw.tween_property(model_holder, "scale", target_scale, 0.12)
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
	if not model_holder:
		return
	for child in model_holder.get_children():
		child.queue_free()

	if not ResourceLoader.exists(BIN_MODEL_PATH):
		push_warning("RecyclingBin: no se encontró el modelo del tacho")
		return

	var packed: PackedScene = load(BIN_MODEL_PATH) as PackedScene
	var instance: Node3D = packed.instantiate() as Node3D if packed else null
	if not instance:
		return

	instance.scale = BIN_SCALES.get(accepts_type, Vector3.ONE)   # <- línea nueva
	model_holder.add_child(instance)
	_apply_tint(instance, BIN_COLORS.get(accepts_type, Color.WHITE))

func _apply_tint(node: Node, tint: Color) -> void:
	if node is MeshInstance3D:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		if mesh_instance.mesh:
			for i in mesh_instance.mesh.get_surface_count():
				var base_mat: Material = mesh_instance.mesh.surface_get_material(i)
				var mat: StandardMaterial3D = base_mat.duplicate() as StandardMaterial3D if base_mat is StandardMaterial3D else StandardMaterial3D.new()
				mat.albedo_color = tint
				mesh_instance.set_surface_override_material(i, mat)
	for child in node.get_children():
		_apply_tint(child, tint)
