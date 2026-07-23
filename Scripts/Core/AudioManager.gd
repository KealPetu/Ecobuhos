extends Node

## Autoload / Global Audio Manager for EcoBuhos
## Generates procedural chiptune sound effects for pickups, deposits, stuns, and level results.

var _player: AudioStreamPlayer

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)
	
	if GameManager:
		GameManager.waste_deposited.connect(_on_waste_deposited)
		GameManager.player_stunned.connect(func(_d, _r): play_sound("error"))
		GameManager.level_completed.connect(func(_s, _a, _tb, _st, _bd): play_sound("victory"))
		GameManager.level_failed.connect(func(_s, _t): play_sound("defeat"))

func _on_waste_deposited(_waste: String, _bin: String, correct: bool) -> void:
	if correct:
		play_sound("correct")
	else:
		play_sound("error")

func play_sound(type: String) -> void:
	var stream: AudioStreamWAV = _generate_sound(type)
	if stream:
		var asp = AudioStreamPlayer.new()
		add_child(asp)
		asp.stream = stream
		asp.volume_db = -6.0
		asp.play()
		asp.finished.connect(asp.queue_free)

func _generate_sound(type: String) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	
	var duration: float = 0.2
	if type == "victory":
		duration = 0.6
	elif type == "defeat":
		duration = 0.5
	elif type == "error":
		duration = 0.35

	var num_samples: int = int(wav.mix_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples)

	for i in range(num_samples):
		var t: float = float(i) / float(wav.mix_rate)
		var val: float = 0.0

		match type:
			"pickup":
				# Sweep de tono ascendente alegre
				var freq: float = 350.0 + t * 1200.0
				val = sin(t * freq * TAU)
			"correct":
				# Acorde arpegiado (Do - Mi - Sol)
				var freq: float = 523.25
				if t > 0.07: freq = 659.25
				if t > 0.14: freq = 783.99
				val = sin(t * freq * TAU)
			"error":
				# Zumbido grave de error (onda cuadrada)
				var freq: float = 120.0 - t * 80.0
				val = 0.8 if sin(t * freq * TAU) > 0 else -0.8
			"victory":
				# Fanfarria triunfal
				var freq: float = 523.25
				if t > 0.15: freq = 659.25
				if t > 0.30: freq = 783.99
				if t > 0.45: freq = 1046.50
				val = sin(t * freq * TAU)
			"defeat":
				# Tono descendente triste
				var freq: float = 400.0 - t * 500.0
				val = sin(t * max(60.0, freq) * TAU)

		# Convertir muestra (-1.0 a 1.0) a byte unsigned (0 a 255)
		var byte_val: int = int(clamp((val * 0.4 + 0.5) * 255.0, 0.0, 255.0))
		data[i] = byte_val

	wav.data = data
	return wav
