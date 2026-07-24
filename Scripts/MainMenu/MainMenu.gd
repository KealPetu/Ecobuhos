extends Control

# Ajusta estas rutas a tus escenas reales
const SCENE_ONBOARDING := "res://scenes/Onboarding/OnboardingScene.tscn"
const SCENE_GAME := "res://scenes/LevelSelect.tscn"
const SCENE_SETTINGS := "res://scenes/UI/Settings.tscn"
const SCENE_CREDITS := "res://scenes/UI/Credits.tscn"

@onready var onboarding_popup: ConfirmationDialog = $OnboardingPopup

func _ready() -> void:
	$CenterContainer/MenuContainer/PlayButton.pressed.connect(_on_play_pressed)
	$CenterContainer/MenuContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$CenterContainer/MenuContainer/CreditsButton.pressed.connect(_on_credits_pressed)
	$CenterContainer/MenuContainer/QuitButton.pressed.connect(_on_quit_pressed)

	onboarding_popup.confirmed.connect(_on_onboarding_confirmed)
	onboarding_popup.canceled.connect(_on_onboarding_declined)
	# Renombra el botón "Cancel" a algo más claro
	onboarding_popup.get_cancel_button().text = "No, ya s\u00e9 jugar"

func _on_play_pressed() -> void:
	onboarding_popup.popup_centered()

func _on_onboarding_confirmed() -> void:
	get_tree().change_scene_to_file(SCENE_ONBOARDING)

func _on_onboarding_declined() -> void:
	get_tree().change_scene_to_file(SCENE_GAME)

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file(SCENE_SETTINGS)

func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file(SCENE_CREDITS)

func _on_quit_pressed() -> void:
	get_tree().quit()
