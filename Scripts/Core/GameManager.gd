extends Node

## Autoload singleton that manages global game state, XP persistence, leaderboards, star ratings, and operant conditioning

signal score_changed(new_score: int)
signal combo_changed(multiplier: float)
signal xp_changed(total_xp: int)
signal time_up()
signal waste_deposited(waste_type: String, bin_type: String, correct: bool)
signal player_stunned(duration: float, reason: String)
signal mapache_activated()
signal level_completed(final_score: int, accuracy: float, time_bonus: int, stars: int, badge: String)
signal level_failed(final_score: int, tip: String)
signal game_over(final_score: int)

var score: int = 0
var combo_count: int = 0
var combo_multiplier: float = 1.0
var time_remaining: float = 0.0
var is_playing: bool = false

var level_target: int = 5         # Objetivo: reciclar 5 residuos correctamente
var total_deposits: int = 0       # Total de intentos de deposito
var correct_deposits: int = 0     # Depositos correctos
var error_count: int = 0          # Conteo de errores en el nivel actual
var initial_time_limit: float = 90.0

# Perfil del jugador (Persistente)
var player_xp: int = 0
var player_name: String = "Estudiante EPN"

const SAVE_PATH: String = "user://player_profile.json"
const LEADERBOARD_PATH: String = "user://leaderboard.json"

const BADGES: Dictionary = {
	5: "🏆 Guardián Legendario EPN",
	4: "⭐ Reciclador Maestro",
	3: "🏅 EcoBúho Avanzado",
	2: "🌱 Aprendiz Verde",
	1: "🧹 Voluntario Campus"
}

func _ready() -> void:
	load_profile()

func start_level(target_waste_count: int = 5, time_limit: float = 90.0) -> void:
	level_target = target_waste_count
	initial_time_limit = time_limit
	time_remaining = time_limit
	score = 0
	combo_count = 0
	combo_multiplier = 1.0
	total_deposits = 0
	correct_deposits = 0
	error_count = 0
	is_playing = true
	score_changed.emit(score)
	combo_changed.emit(combo_multiplier)
	xp_changed.emit(player_xp)

func deposit_waste(waste_type: String, bin_type: String) -> bool:
	if not is_playing:
		return false
		
	total_deposits += 1
	var correct: bool = (waste_type == bin_type)
	
	if correct:
		correct_deposits += 1
		var pts: int = int(100 * combo_multiplier)
		score += pts
		combo_count += 1
		combo_multiplier = min(4.0, 1.0 + float(combo_count) * 0.5)
		
		# Refuerzo Positivo: Otorga XP persistente (+25 XP por acierto)
		add_xp(25)
	else:
		error_count += 1
		reset_combo()
		score -= 50
		score = max(0, score)
		
		# Refuerzo Negativo 1: Congelamiento temporal por contaminacion cruzada (Stun 2.0s)
		player_stunned.emit(2.0, "⚡ ¡CONGELADO 2s POR CONTAMINACIÓN CRUZADA!")
		
		# Refuerzo Negativo 2: Si comete 2 o mas errores, se activa el Desordenador (Mapache)
		if error_count >= 2:
			_spawn_mapache_if_needed()
			mapache_activated.emit()
	
	score_changed.emit(score)
	combo_changed.emit(combo_multiplier)
	waste_deposited.emit(waste_type, bin_type, correct)

	# Verificacion de Victoria (Objetivo cumplido)
	if correct_deposits >= level_target:
		_trigger_victory()

	return correct

func _process(delta: float) -> void:
	if is_playing and time_remaining > 0:
		time_remaining -= delta
		if time_remaining <= 0:
			time_remaining = 0
			_trigger_defeat()

func _trigger_victory() -> void:
	is_playing = false
	var time_bonus: int = int(time_remaining * 10.0)
	score += time_bonus
	
	# XP extra por victoria
	add_xp(100)
	score_changed.emit(score)
	
	var accuracy: float = 100.0
	if total_deposits > 0:
		accuracy = (float(correct_deposits) / float(total_deposits)) * 100.0
		
	var stars: int = calculate_stars(score, accuracy, time_remaining, initial_time_limit)
	var badge: String = BADGES.get(stars, "🧹 Voluntario Campus")
	
	save_leaderboard_entry(player_name, score, stars, badge)
	level_completed.emit(score, accuracy, time_bonus, stars, badge)

func _trigger_defeat() -> void:
	is_playing = false
	time_up.emit()
	var tip: String = "CONSEJO PEDAGÓGICO:\nLos residuos orgánicos van en el tacho verde y los plásticos en el azul. ¡Sepáralos correctamente para mantener tus combos!"
	level_failed.emit(score, tip)

func calculate_stars(final_score: int, accuracy: float, time_left: float, total_time: float) -> int:
	var time_ratio: float = time_left / max(1.0, total_time)
	if accuracy >= 100.0 and time_ratio >= 0.4:
		return 5
	elif accuracy >= 80.0 and time_ratio >= 0.2:
		return 4
	elif accuracy >= 60.0:
		return 3
	elif accuracy >= 40.0:
		return 2
	else:
		return 1

func reset_combo() -> void:
	combo_count = 0
	combo_multiplier = 1.0
	combo_changed.emit(combo_multiplier)

func add_xp(amount: int) -> void:
	player_xp += amount
	xp_changed.emit(player_xp)
	save_profile()

func end_game() -> void:
	is_playing = false
	game_over.emit(score)

# ─────────────────────────────────────────────────────────────────────
# PERSISTENCIA (Profile & Leaderboard JSON)
# ─────────────────────────────────────────────────────────────────────
func save_profile() -> void:
	var data: Dictionary = {
		"player_name": player_name,
		"player_xp": player_xp
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_profile() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var text = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(text) == OK:
				var data = json.data
				player_name = data.get("player_name", "Estudiante EPN")
				player_xp = int(data.get("player_xp", 0))

func get_leaderboard() -> Array:
	if FileAccess.file_exists(LEADERBOARD_PATH):
		var file = FileAccess.open(LEADERBOARD_PATH, FileAccess.READ)
		if file:
			var text = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(text) == OK:
				return json.data
	
	# Retornar ranking por defecto si no existe archivo
	return [
		{"name": "CARLOS EPN", "score": 1250, "stars": 5, "badge": "🏆 Guardián Legendario EPN"},
		{"name": "DANIEL M.", "score": 980, "stars": 4, "badge": "⭐ Reciclador Maestro"},
		{"name": "MARIA S.", "score": 720, "stars": 3, "badge": "🏅 EcoBúho Avanzado"},
		{"name": "KEVIN P.", "score": 550, "stars": 2, "badge": "🌱 Aprendiz Verde"},
		{"name": "JIMMY (TÚ)", "score": 450, "stars": 2, "badge": "🌱 Aprendiz Verde"}
	]

func save_leaderboard_entry(p_name: String, p_score: int, p_stars: int, p_badge: String) -> void:
	var list = get_leaderboard()
	list.append({
		"name": p_name,
		"score": p_score,
		"stars": p_stars,
		"badge": p_badge
	})
	
	# Ordenar por puntaje descendente
	list.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))
	
	# Mantener los mejores 8
	if list.size() > 8:
		list = list.slice(0, 8)
		
	var file = FileAccess.open(LEADERBOARD_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(list))
		file.close()

func _spawn_mapache_if_needed() -> void:
	var existing = get_tree().get_nodes_in_group("mapache")
	if existing.size() > 0:
		return
	var mapache_prefab = load("res://Scenes/Characters/NPCs/MapacheInvasor.tscn")
	if mapache_prefab and get_tree().current_scene:
		var mapache = mapache_prefab.instantiate()
		get_tree().current_scene.add_child(mapache)
