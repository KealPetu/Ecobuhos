extends Control

## HUD overlay showing score, combo, time, inventory, level objectives, and win/loss feedback modals

@onready var score_label: Label = $Panel/HBoxContainer/ScoreLabel if has_node("Panel/HBoxContainer/ScoreLabel") else null
@onready var time_label: Label = $Panel/HBoxContainer/TimeLabel if has_node("Panel/HBoxContainer/TimeLabel") else null
@onready var combo_label: Label = $Panel/HBoxContainer/ComboLabel if has_node("Panel/HBoxContainer/ComboLabel") else null
@onready var objective_label: Label = $Panel/HBoxContainer/ObjectiveLabel if has_node("Panel/HBoxContainer/ObjectiveLabel") else null
@onready var inventory_bar: Container = $Panel/HBoxContainer/InventoryBar if has_node("Panel/HBoxContainer/InventoryBar") else null
@onready var msg_label: Label = $FeedbackLabel if has_node("FeedbackLabel") else null
@onready var back_btn: Button = $Panel/HBoxContainer/BackBtn if has_node("Panel/HBoxContainer/BackBtn") else null

# Modales
@onready var victory_modal: Control = $VictoryModal if has_node("VictoryModal") else null
@onready var victory_details: Label = $VictoryModal/VBox/Details if has_node("VictoryModal/VBox/Details") else null
@onready var victory_map_btn: Button = $VictoryModal/VBox/VictoryMapBtn if has_node("VictoryModal/VBox/VictoryMapBtn") else null

@onready var defeat_modal: Control = $DefeatModal if has_node("DefeatModal") else null
@onready var defeat_tip: Label = $DefeatModal/VBox/Tip if has_node("DefeatModal/VBox/Tip") else null
@onready var retry_btn: Button = $DefeatModal/VBox/HBoxButtons/RetryBtn if has_node("DefeatModal/VBox/HBoxButtons/RetryBtn") else null
@onready var defeat_map_btn: Button = $DefeatModal/VBox/HBoxButtons/DefeatMapBtn if has_node("DefeatModal/VBox/HBoxButtons/DefeatMapBtn") else null

var _msg_timer: float = 0.0

const ITEM_INFO: Dictionary = {
	"organic":    {"name": "🍌 Orgánico",    "color": Color(0.15, 0.65, 0.35)},
	"plastic":    {"name": "🥤 Plástico",    "color": Color(0.15, 0.50, 0.80)},
	"glass":      {"name": "🍾 Vidrio",      "color": Color(0.20, 0.75, 0.85)},
	"metal":      {"name": "🥫 Metal",       "color": Color(0.90, 0.60, 0.10)},
	"electronic": {"name": "🔋 Electrónico", "color": Color(0.40, 0.40, 0.45)},
	"paper":      {"name": "📰 Papel",       "color": Color(0.85, 0.85, 0.85)},
}

const BIN_NAMES: Dictionary = {
	"organic": "Orgánico",
	"plastic": "Plástico",
	"glass": "Vidrio",
	"metal": "Metal",
	"electronic": "Electrónico",
	"paper": "Papel"
}

func _ready() -> void:
	if GameManager:
		GameManager.score_changed.connect(_on_score_changed)
		GameManager.combo_changed.connect(_on_combo_changed)
		GameManager.waste_deposited.connect(_on_waste_deposited)
		GameManager.level_failed.connect(_on_level_failed)
		GameManager.level_completed.connect(_on_level_completed)
		GameManager.mapache_activated.connect(_on_mapache_activated)
		GameManager.level_target_changed.connect(_on_level_target_changed)
		var current_scene: Node = get_tree().current_scene
		if current_scene:
			GameManager.set_current_level_from_scene_path(current_scene.scene_file_path)
		GameManager.start_level(GameManager.get_current_level_waste_target(5), 90.0)
		_update_objective()

	if msg_label:
		msg_label.hide()
	if victory_modal:
		victory_modal.hide()
	if defeat_modal:
		defeat_modal.hide()

	# Conexiones de botones
	if back_btn:
		back_btn.pressed.connect(_go_to_map)
	if victory_map_btn:
		victory_map_btn.pressed.connect(_go_to_map)
	if defeat_map_btn:
		defeat_map_btn.pressed.connect(_go_to_map)
	if retry_btn:
		retry_btn.pressed.connect(func() -> void:
			get_tree().reload_current_scene()
		)
	
	# Buscar el jugador y conectar inventario
	get_tree().node_added.connect(_check_player_inventory)
	_find_and_connect_player()

func _go_to_map() -> void:
	get_tree().change_scene_to_file("res://Scenes/LevelSelect.tscn")

func _find_and_connect_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		var p = players[0]
		if p.get("inventory_component") and p.inventory_component:
			var inv: InventoryComponent = p.inventory_component
			inv.item_added.connect(func(_type, _count): update_inventory_display(inv.items))
			inv.item_removed.connect(func(_type): update_inventory_display(inv.items))
			inv.inventory_full.connect(func(): show_message("🎒 ¡MOCHILA LLENA!", Color.ORANGE))
			update_inventory_display(inv.items)

func _check_player_inventory(node: Node) -> void:
	if node.is_in_group("player"):
		_find_and_connect_player()

func _process(delta: float) -> void:
	if time_label and GameManager:
		time_label.text = "TIEMPO: " + str(int(GameManager.time_remaining)) + "s"
	
	if _msg_timer > 0:
		_msg_timer -= delta
		if _msg_timer <= 0:
			if msg_label:
				msg_label.hide()

func _on_score_changed(score: int) -> void:
	if score_label:
		score_label.text = "PUNTOS: " + str(score)

func _on_combo_changed(multiplier: float) -> void:
	if combo_label:
		combo_label.text = "COMBO: x" + str(multiplier)
		if multiplier > 1.0:
			combo_label.modulate = Color(1.0, 0.85, 0.1)
		else:
			combo_label.modulate = Color(1.0, 1.0, 1.0)

func _on_waste_deposited(waste_type: String, bin_type: String, correct: bool) -> void:
	_update_objective()
	var item_name: String = ITEM_INFO.get(waste_type, {}).get("name", waste_type)
	var b_name: String = BIN_NAMES.get(bin_type, bin_type)
	
	if correct:
		show_message("¡CORRECTO!  " + item_name + " depositado en Tacho " + b_name + " (+100)", Color(0.2, 0.95, 0.4), 2.5)
	else:
		show_message("❌ CONTAMINACIÓN CRUZADA:  " + item_name + " NO va en Tacho " + b_name + " (-50)", Color(1.0, 0.25, 0.25), 3.0)

func _update_objective() -> void:
	if objective_label and GameManager:
		objective_label.text = "🎯 ASIGNADOS: " + str(GameManager.total_deposits) + "/" + str(GameManager.level_target)


func _on_level_target_changed(_new_target: int) -> void:
	_update_objective()

func _on_level_completed(final_score: int, accuracy: float, time_bonus: int, stars: int, badge: String) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if victory_modal:
		if victory_details:
			victory_details.text = "¡Excelente trabajo Guardián EPN!\n\n• Asignados: " + str(GameManager.total_deposits) + "/" + str(GameManager.level_target) + " Residuos\n• Puntaje Final: " + str(final_score) + " pts\n• Precisión: " + str(int(accuracy)) + "%\n• Bonus de Tiempo: +" + str(time_bonus) + " pts\n• Insignia: " + badge + "\n\nHas purificado con éxito la zona."
		victory_modal.show()

func _on_level_failed(final_score: int, tip: String) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if defeat_modal:
		if defeat_tip:
			defeat_tip.text = "No lograste reciclar " + str(GameManager.level_target) + " residuos a tiempo.\n\nPuntaje alcanzado: " + str(final_score) + " pts\n\n💡 RETROALIMENTACIÓN PEDAGÓGICA:\n" + tip
		defeat_modal.show()
func _on_mapache_activated(_spawn_position: Vector3 = Vector3.ZERO) -> void:
	show_message("🦝 ¡ALERTA! EL DESORDENADOR (MAPACHE INVASOR) HA ATACADO Y ESTÁ TIRANDO BASURA 🦝", Color(1.0, 0.2, 0.2), 6.0)


func update_inventory_display(items: Array) -> void:
	if not inventory_bar:
		return
		
	for child in inventory_bar.get_children():
		child.queue_free()

	if items.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Mochila: [ Vacía ]"
		empty_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		inventory_bar.add_child(empty_lbl)
		return

	var tag = Label.new()
	tag.text = "Mochila: "
	tag.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	inventory_bar.add_child(tag)

	for i in range(items.size()):
		var type_str: String = str(items[i])
		var info: Dictionary = ITEM_INFO.get(type_str, {"name": type_str, "color": Color.GRAY})
		
		var panel = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = info["color"]
		style.corner_radius_top_left = 5
		style.corner_radius_top_right = 5
		style.corner_radius_bottom_right = 5
		style.corner_radius_bottom_left = 5
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 3
		style.content_margin_bottom = 3
		panel.add_theme_stylebox_override("panel", style)

		var lbl = Label.new()
		if i == 0:
			lbl.text = "► " + str(info["name"]) + " (Siguiente)"
			lbl.add_theme_color_override("font_color", Color.YELLOW)
		else:
			lbl.text = str(info["name"])
			lbl.add_theme_color_override("font_color", Color.WHITE)
			
		lbl.add_theme_font_size_override("font_size", 13)
		panel.add_child(lbl)
		inventory_bar.add_child(panel)

func show_message(text: String, color: Color, duration: float = 2.5) -> void:
	if msg_label:
		# Si hay un mensaje de alerta del Mapache mostrandose, no sobreescribirlo a menos que sea otra alerta
		if _msg_timer > 0 and msg_label.text.begins_with("🦝") and not text.begins_with("🦝"):
			return
		
		msg_label.text = text
		msg_label.modulate = color
		msg_label.show()
		_msg_timer = duration
