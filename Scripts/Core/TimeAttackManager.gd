extends Node

## Manages Time Attack missions

signal mission_complete(score: int, time_bonus: float)
signal mission_failed()

@export var default_time: float = 60.0
@export var target_waste_count: int = 10

var _deposits_this_mission: int = 0
var _correct_deposits: int = 0

func _ready() -> void:
	if GameManager:
		GameManager.waste_deposited.connect(_on_waste_deposited)
		GameManager.time_up.connect(_on_time_up)

func start_mission(waste_target: int, time_limit: float) -> void:
	_deposits_this_mission = 0
	_correct_deposits = 0
	GameManager.start_level(waste_target, time_limit)

func _on_waste_deposited(waste_type: String, correct: bool) -> void:
	_deposits_this_mission += 1
	if correct:
		_correct_deposits += 1
		
	if _deposits_this_mission >= target_waste_count:
		var time_bonus: float = GameManager.time_remaining * 10.0
		mission_complete.emit(GameManager.score, time_bonus)
		GameManager.end_game()

func _on_time_up() -> void:
	mission_failed.emit()

func get_accuracy() -> float:
	if _deposits_this_mission == 0:
		return 0.0
	return float(_correct_deposits) / float(max(1, _deposits_this_mission))
