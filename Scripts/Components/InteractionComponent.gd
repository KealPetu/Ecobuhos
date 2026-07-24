class_name InteractionComponent
extends Node

## Handles Jimmy's ability to pick up waste and deposit into bins.
## Uses spatial distance scanning, explicit debouncing, and diagnostic logs.

signal interaction_attempted(success: bool, message: String)

@export var reach_distance: float = 2.5
@export var inventory: InventoryComponent
@export var input: InputComponent

var _current_target_bin: RecyclingBin = null
var _cooldown_timer: float = 0.0

func _ready() -> void:
	_ensure_inventory()

func _ensure_inventory() -> void:
	if not inventory:
		var parent = get_parent()
		if parent:
			if parent.get("inventory_component") and parent.inventory_component:
				inventory = parent.inventory_component
			elif parent.has_node("InventoryComponent"):
				inventory = parent.get_node("InventoryComponent")

func _process(delta: float) -> void:
	if _cooldown_timer > 0:
		_cooldown_timer -= delta

	var player: Node3D = get_parent() as Node3D
	if not player or not player.is_inside_tree():
		return
		
	if player.get("is_stunned") and player.is_stunned:
		if _current_target_bin:
			_current_target_bin.set_highlight(false)
			_current_target_bin = null
		return
		
	var p_pos: Vector3 = player.global_position
	var nearest_bin: RecyclingBin = _find_nearest_bin(p_pos)

	if nearest_bin != _current_target_bin:
		if _current_target_bin:
			_current_target_bin.set_highlight(false)
		_current_target_bin = nearest_bin
		if _current_target_bin:
			_current_target_bin.set_highlight(true)

func _input(event: InputEvent) -> void:
	var player: Node3D = get_parent() as Node3D
	if player and player.get("is_stunned") and player.is_stunned:
		return

	if _cooldown_timer > 0:
		return
		
	if event.is_echo():
		return

	if input.is_interact_pressed():
		_cooldown_timer = 0.25 # 250ms debouncing
		get_viewport().set_input_as_handled()
		try_interact()

func try_interact() -> void:
	var player: Node3D = get_parent() as Node3D
	if not player:
		return
		
	if player.get("is_stunned") and player.is_stunned:
		print("[INTERACTION] Jugador congelado por contaminacion cruzada. No se puede interactuar.")
		return
		
	_ensure_inventory()
	var p_pos: Vector3 = player.global_position
	print("[INTERACTION] Intento de interaccion desde posicion: ", p_pos)

	# 1. Si el mapache está dentro de su área de interacción -> derribarlo
	var nearby_mapache: MapacheInvasor = _find_defeatable_mapache()
	if nearby_mapache:
		if nearby_mapache.try_defeat():
			print("[INTERACTION] Mapache derribado")
			interaction_attempted.emit(true, "Mapache derribado")
			return

	# 2. Si estamos cerca de un tacho y tenemos basura en la mochila -> depositar
	if inventory and inventory.get_count() > 0:
		var nearest_bin: RecyclingBin = _find_nearest_bin(p_pos)
		if nearest_bin:
			var item: String = inventory.peek_first()
			print("[INTERACTION] Tacho encontrado: ", nearest_bin.accepts_type, " | Intentando depositar: ", item)
			var success: bool = nearest_bin.try_deposit(inventory)
			if success:
				interaction_attempted.emit(true, "Depositado 1 objeto en tacho")
				return
		else:
			print("[INTERACTION] Mochila tiene ", inventory.get_count(), " objetos pero no hay tacho dentro de ", reach_distance, "m")

	# 3. Si estamos cerca de basura y tenemos espacio -> recoger 1 objeto
	if inventory and not inventory.is_full():
		var nearest_waste: WasteItem = _find_nearest_waste(p_pos)
		if nearest_waste:
			var type: String = nearest_waste.pick()
			if type != "":
				inventory.add_item(type)
				var audio_mgr = get_node_or_null("/root/AudioManager")
				if audio_mgr and audio_mgr.has_method("play_sound"):
					audio_mgr.play_sound("pickup")
				print("[INTERACTION] Objeto recolectado: ", type, " | Mochila ahora tiene: ", inventory.get_count())
				interaction_attempted.emit(true, "Recolectado: " + type)
				return
		else:
			print("[INTERACTION] No hay basura cercana dentro de ", reach_distance, "m")

	interaction_attempted.emit(false, "Nada cerca para interactuar")

func _find_defeatable_mapache() -> MapacheInvasor:
	for node in get_tree().get_nodes_in_group("mapache"):
		if node is MapacheInvasor:
			return node as MapacheInvasor
	return null

func _find_nearest_waste(from_pos: Vector3) -> WasteItem:
	var waste_nodes = get_tree().get_nodes_in_group("waste_items")
	var nearest: WasteItem = null
	var min_dist_sq: float = reach_distance * reach_distance

	for node in waste_nodes:
		if node is WasteItem and node.visible and node._can_pick:
			var dist_sq: float = from_pos.distance_squared_to(node.global_position)
			if dist_sq <= min_dist_sq:
				min_dist_sq = dist_sq
				nearest = node
				
	return nearest

func _find_nearest_bin(from_pos: Vector3) -> RecyclingBin:
	var bins = get_tree().get_nodes_in_group("recycling_bins")
	if bins.is_empty():
		bins = _find_bins_recursive(get_tree().root)

	var nearest: RecyclingBin = null
	var min_dist_sq: float = reach_distance * reach_distance

	for node in bins:
		if node is RecyclingBin:
			var dist_sq: float = from_pos.distance_squared_to(node.global_position)
			if dist_sq <= min_dist_sq:
				min_dist_sq = dist_sq
				nearest = node

	return nearest

func _find_bins_recursive(node: Node) -> Array:
	var result: Array = []
	if node is RecyclingBin:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_bins_recursive(child))
	return result
