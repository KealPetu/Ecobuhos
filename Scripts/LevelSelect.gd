extends Node2D

# =====================================================================
# EcoBuhos - LevelSelect.gd
# Solo logica de juego. Todos los nodos visuales estan en LevelSelect.tscn
# =====================================================================

# --- Datos de Niveles ---
const LEVELS: Array = [
	{
		"id":        "mecanica",
		"full_name": "Facultad de Mecanica",
		"desc":      "Domina el mundo de engranajes, maquinas e ingenieria industrial de la EPN.",
		"scene":     "res://Scenes/MapaEPN.tscn",
		"locked":    false,
		"number":    1,
	},
	{
		"id":        "sistemas",
		"full_name": "Facultad de Sistemas",
		"desc":      "Explora el mundo digital de la ingenieria informatica y el software.",
		"scene":     "res://Scenes/levels/Z1_Sistemas.tscn",
		"locked":    true,
		"number":    2,
	},
	{
		"id":        "quimica",
		"full_name": "Facultad de Quimica",
		"desc":      "Descubre los secretos de la quimica y el cuidado del medio ambiente.",
		"scene":     "res://Scenes/levels/Z2_Quimica.tscn",
		"locked":    true,
		"number":    3,
	},
	{
		"id":        "comedor",
		"full_name": "Comedor Central EPN",
		"desc":      "El corazon social del campus politecnico, donde se alimenta la comunidad EPN.",
		"scene":     "res://Scenes/levels/Z3_Comedor.tscn",
		"locked":    true,
		"number":    4,
	},
	{
		"id":        "agroindustria",
		"full_name": "Facultad de Agroindustria",
		"desc":      "Aprende sobre sostenibilidad, cultivos y la industria alimentaria del Ecuador.",
		"scene":     "res://Scenes/Levels/Z4_Agroindustria.tscn",
		"locked":    true,
		"number":    5,
	},
]

const PATHS: Array = [[0, 1], [1, 2], [2, 3], [3, 4]]

# --- Referencias a nodos (definidos en la escena) ---
@onready var _background:    TextureRect = $Background
@onready var _paths_node:    Node2D      = $Paths
@onready var _level_parent:  Node2D      = $LevelNodes
@onready var _player:        Node2D      = $PlayerMarker
@onready var _owl_sprite:    Sprite2D    = $PlayerMarker/OwlSprite
@onready var _fade:          ColorRect   = $UI/FadeOverlay
@onready var _info_panel:    Panel       = $UI/InfoPanel
@onready var _name_label:    Label       = $UI/InfoPanel/LvNameLabel
@onready var _desc_label:    Label       = $UI/InfoPanel/LvDescLabel
@onready var _enter_btn:     Button      = $UI/InfoPanel/EnterBtn
@onready var _reset_btn:     Button      = $UI/TitleBar/ResetProgressBtn if has_node("UI/TitleBar/ResetProgressBtn") else null
@onready var _reset_dialog:  ConfirmationDialog = $UI/ResetProgressDialog if has_node("UI/ResetProgressDialog") else null

# --- Estado ---
var _level_nodes:   Array[Control] = []
var _selected:      int   = 0
var _target_pos:    Vector2 = Vector2.ZERO
var _transitioning: bool   = false
var _bounce_t:      float  = 0.0


func _is_level_locked(idx: int) -> bool:
	if GameManager:
		return not GameManager.is_level_unlocked(idx)
	return bool(LEVELS[idx]["locked"])


func _refresh_level_node(idx: int) -> void:
	if idx < 0 or idx >= _level_nodes.size():
		return
	var nc: Control = _level_nodes[idx]
	var lock_icon: Label = nc.get_node_or_null("LockIcon") as Label
	if lock_icon:
		lock_icon.visible = _is_level_locked(idx)


# ─────────────────────────────────────────────────────────────────────
# _ready
# ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Cargar el mapa de fondo (puede no estar importado correctamente)

	var map_tex: Texture2D = _load_tex("res://Assets/Textures/campus_map.png")
	if map_tex:
		_background.texture = map_tex

	# Leer los nodos de nivel del arbol de escena
	for child: Node in _level_parent.get_children():
		if child is Control:
			_level_nodes.append(child as Control)

	# Cargar iconos de edificios y conectar botones de clic
	for i: int in _level_nodes.size():
		_init_level_node(i)
		_refresh_level_node(i)

	# Caminos
	_paths_node.draw.connect(_draw_paths)
	_paths_node.queue_redraw()

	# Boton ENTRAR
	_enter_btn.pressed.connect(_on_enter_pressed)
	if _reset_btn:
		_reset_btn.pressed.connect(_confirm_reset_progress)
	if _reset_dialog:
		_reset_dialog.confirmed.connect(_reset_progress_and_refresh)

	# Boton SALIR DEL JUEGO
	var quit_btn: Button = get_node_or_null("UI/TitleBar/QuitBtn") as Button
	if quit_btn:
		quit_btn.pressed.connect(func() -> void:
			get_tree().quit()
		)

	# Boton RANKING / LEADERBOARD
	var rank_btn: Button = get_node_or_null("UI/TitleBar/RankBtn") as Button
	if rank_btn:
		rank_btn.pressed.connect(_show_leaderboard_popup)



	# Estado inicial: ir al primer nivel desbloqueado
	for i: int in LEVELS.size():
		if not _is_level_locked(i):
			_selected = i
			break

	_target_pos = _center_of(_selected)
	_player.position = _target_pos
	for i: int in _level_nodes.size():
		_set_glow(i, i == _selected)
	_update_info(_selected)
	_set_glow(_selected, true)

	# Fade-in de entrada
	_fade.color.a = 1.0
	var tw: Tween = create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 1.0)


func _init_level_node(idx: int) -> void:
	var nc: Control = _level_nodes[idx]

	# Conectar boton de clic
	var btn: Button = nc.get_node_or_null("ClickArea") as Button
	if btn:
		btn.pressed.connect(_on_pin_clicked.bind(idx))
		btn.mouse_entered.connect(_on_pin_hovered.bind(idx))


# ─────────────────────────────────────────────────────────────────────
# _process  (animaciones)
# ─────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	# Mover el buho hacia el nivel seleccionado
	var dist: float = _player.position.distance_to(_target_pos)
	if dist > 2.0:
		var speed: float = clampf(dist * 4.0, 60.0, 500.0)
		_player.position = _player.position.move_toward(_target_pos, speed * delta)

	# Animacion de rebote del buho
	_bounce_t += delta * 3.8
	_owl_sprite.position.y = -38.0 + sin(_bounce_t) * 5.0

	# Pulsacion suave de los pines
	for i: int in _level_nodes.size():
		var nc: Control = _level_nodes[i]
		var target_scale: float = 1.12 if i == _selected else 1.0
		var pulse: float = sin(_bounce_t * 0.7 + float(i) * 1.5) * 0.015
		var s: float = target_scale + pulse
		nc.scale = nc.scale.lerp(Vector2(s, s), delta * 12.0)


# ─────────────────────────────────────────────────────────────────────
# Input
# ─────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if _transitioning:
		return
	if event.is_action_pressed("ui_left"):
		_navigate(-1)
	elif event.is_action_pressed("ui_right"):
		_navigate(1)
	elif event.is_action_pressed("ui_accept"):
		_try_enter(_selected)


# ─────────────────────────────────────────────────────────────────────
# Navegacion
# ─────────────────────────────────────────────────────────────────────
func _navigate(dir: int) -> void:
	var new_idx: int = clampi(_selected + dir, 0, LEVELS.size() - 1)
	if new_idx == _selected:
		return
	_set_glow(_selected, false)
	_selected   = new_idx
	_target_pos = _center_of(_selected)
	_set_glow(_selected, true)
	_update_info(_selected)
	_pulse_pin(_selected)


func _on_pin_clicked(idx: int) -> void:
	if idx == _selected and not _is_level_locked(idx):
		_try_enter(idx)
	else:
		_set_glow(_selected, false)
		_selected   = idx
		_target_pos = _center_of(idx)
		_set_glow(idx, true)
		_update_info(idx)
		_pulse_pin(idx)


func _on_pin_hovered(idx: int) -> void:
	_update_info(idx)


func _on_enter_pressed() -> void:
	_try_enter(_selected)


func _confirm_reset_progress() -> void:
	if _reset_dialog:
		_reset_dialog.popup_centered()
		return
	_reset_progress_and_refresh()


func _reset_progress_and_refresh() -> void:
	if GameManager:
		GameManager.reset_level_progress()
	for i: int in _level_nodes.size():
		_refresh_level_node(i)
	_set_glow(_selected, false)
	_selected = 0
	_target_pos = _center_of(_selected)
	_player.position = _target_pos
	_set_glow(_selected, true)
	_update_info(_selected)
	_paths_node.queue_redraw()


func _try_enter(idx: int) -> void:
	if _transitioning:
		return
	if _is_level_locked(idx):
		_shake_pin(idx)
		return
	_transitioning = true
	var tw: Tween = create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.55).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(func() -> void:
		var path: String = str(LEVELS[idx]["scene"])
		if ResourceLoader.exists(path):
			get_tree().change_scene_to_file(path)
		else:
			_transitioning = false
			var tw2: Tween = create_tween()
			tw2.tween_property(_fade, "color:a", 0.0, 0.4)
	)


# ─────────────────────────────────────────────────────────────────────
# Actualizacion del panel de informacion
# ─────────────────────────────────────────────────────────────────────
func _update_info(idx: int) -> void:
	var lv: Dictionary = LEVELS[idx]
	_name_label.text = str(lv["number"]) + ".  " + str(lv["full_name"])
	_desc_label.text = str(lv["desc"])

	var locked: bool = _is_level_locked(idx)
	_enter_btn.text     = ">> ENTRAR" if not locked else "[BLOQUEADO]"
	_enter_btn.disabled = locked

	# Animacion de entrada del panel
	var tw: Tween = create_tween()
	tw.tween_property(_info_panel, "scale", Vector2(0.97, 0.97), 0.07).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_info_panel, "scale", Vector2(1.0,  1.0),  0.13).set_trans(Tween.TRANS_BACK)


# ─────────────────────────────────────────────────────────────────────
# Dibujo de caminos entre pines (hecho en _draw del nodo Paths)
# ─────────────────────────────────────────────────────────────────────
func _draw_paths() -> void:
	for pair: Array in PATHS:
		var i: int = int(pair[0])
		var j: int = int(pair[1])
		var a: Vector2 = _center_of(i)
		var b: Vector2 = _center_of(j)
		var locked: bool = _is_level_locked(j)
		var col: Color   = Color(0.83, 0.73, 0.42, 0.75) if not locked else Color(0.45, 0.45, 0.45, 0.4)

		# Sombra del camino
		_paths_node.draw_line(a, b, Color(0, 0, 0, 0.35), 10.0)
		# Camino principal
		_paths_node.draw_line(a, b, col, 6.0)
		# Puntos sobre el camino
		for s: int in range(1, 9):
			var t: float  = float(s) / 9.0
			var pt: Vector2 = a.lerp(b, t)
			var dot_col: Color = Color(1.0, 0.95, 0.7, 0.85) if not locked else Color(0.5, 0.5, 0.5, 0.3)
			_paths_node.draw_circle(pt, 2.5, dot_col)


# ─────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────
func _center_of(idx: int) -> Vector2:
	if idx < 0 or idx >= _level_nodes.size():
		return Vector2.ZERO
	var nc: Control = _level_nodes[idx]
	return nc.position + nc.size * 0.5


func _set_glow(idx: int, on: bool) -> void:
	if idx < 0 or idx >= _level_nodes.size():
		return
	var glow: Panel = _level_nodes[idx].get_node_or_null("GlowRing") as Panel
	if glow:
		glow.visible = on


func _pulse_pin(idx: int) -> void:
	if idx < 0 or idx >= _level_nodes.size():
		return
	var nc: Control = _level_nodes[idx]
	var tw: Tween = create_tween()
	tw.tween_property(nc, "modulate", Color(1.5, 1.4, 0.9, 1), 0.07)
	tw.tween_property(nc, "modulate", Color(1.0, 1.0, 1.0, 1), 0.2)


func _shake_pin(idx: int) -> void:
	if idx < 0 or idx >= _level_nodes.size():
		return
	var nc: Control = _level_nodes[idx]
	var orig_x: float = nc.position.x
	var tw: Tween = create_tween()
	tw.tween_property(nc, "position:x", orig_x + 10.0, 0.06)
	tw.tween_property(nc, "position:x", orig_x - 10.0, 0.06)
	tw.tween_property(nc, "position:x", orig_x +  5.0, 0.05)
	tw.tween_property(nc, "position:x", orig_x,        0.05)


func _load_tex(res_path: String) -> Texture2D:
	if ResourceLoader.exists(res_path):
		var t = load(res_path)
		if t is Texture2D:
			return t
	var abs_path: String = ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_path):
		var img: Image = Image.load_from_file(abs_path)
		if img and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null


func _show_leaderboard_popup() -> void:
	var ui: Node = get_node_or_null("UI")
	if not ui:
		return

	var existing = ui.get_node_or_null("LeaderboardOverlay")
	if existing:
		existing.queue_free()

	var overlay = ColorRect.new()
	overlay.name = "LeaderboardOverlay"
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(650, 480)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.position = Vector2(315, 120)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.2, 0.96)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.784, 0.647, 0.278, 1)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)

	var title = Label.new()
	title.text = "🏆 TABLERO DE PUNTUACIÓN - CAMPUS EPN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.784, 0.647, 0.278, 1))
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	var xp_lbl = Label.new()
	xp_lbl.text = "Perfil: " + str(GameManager.player_name) + "  |  XP Acumulada: " + str(GameManager.player_xp) + " XP"
	xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5, 1))
	xp_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(xp_lbl)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600, 260)
	var list_vbox = VBoxContainer.new()

	var leaderboard = GameManager.get_leaderboard()
	for i in range(leaderboard.size()):
		var entry = leaderboard[i]
		var stars_str: String = ""
		for s in range(int(entry.get("stars", 1))):
			stars_str += "⭐"

		var row = Label.new()
		row.text = str(i + 1) + ". " + str(entry.get("name", "Jugador")) + " - " + str(entry.get("score", 0)) + " pts  [" + stars_str + "]\n   " + str(entry.get("badge", ""))
		row.add_theme_font_size_override("font_size", 14)
		if i == 0:
			row.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
		else:
			row.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		list_vbox.add_child(row)

	scroll.add_child(list_vbox)
	vbox.add_child(scroll)

	var close_btn = Button.new()
	close_btn.text = "✖ CERRAR"
	close_btn.custom_minimum_size = Vector2(160, 40)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func(): overlay.queue_free())
	vbox.add_child(close_btn)

	panel.add_child(vbox)
	overlay.add_child(panel)
	ui.add_child(overlay)
