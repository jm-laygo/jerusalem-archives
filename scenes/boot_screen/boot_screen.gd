extends Control

const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu/main_menu.tscn"

@export_group("Timing")
@export var displayDuration: float = 4.0
@export var fadeOutDuration: float = 0.95
@export var fadeInDuration: float = 0.55

@onready var bootTimer: Timer = $BootTimer


# Starts the boot screen music and timer.
func _ready() -> void:
	playMainTheme()
	startBootTimer()


# Plays the main theme if the music manager exists.
func playMainTheme() -> void:
	var musicManager: Node = get_node_or_null("/root/MusicManager")

	if musicManager == null:
		return

	if musicManager.has_method("playMainThemeOnce"):
		musicManager.call("playMainThemeOnce")


# Sets the boot timer duration and starts the countdown.
func startBootTimer() -> void:
	bootTimer.wait_time = displayDuration
	bootTimer.start()


# Moves the player from the boot screen to the main menu.
func goToMainMenu() -> void:
	var transitionManager: Node = get_node_or_null("/root/SceneTransitionManager")

	if transitionManager != null and transitionManager.has_method("changeSceneWithFade"):
		transitionManager.call(
			"changeSceneWithFade",
			MAIN_MENU_SCENE_PATH,
			fadeOutDuration,
			fadeInDuration
		)
		return

	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


# Called when the boot screen timer finishes.
func onBootTimerTimeout() -> void:
	goToMainMenu()