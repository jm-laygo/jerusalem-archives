extends Control

const CLICK_SOUND: AudioStream = preload("res://assets/sounds/ui/ui_generic_select.wav")
const START_GAME_SOUND: AudioStream = preload("res://assets/sounds/ui/ui_main_menu_start_game.wav")
const CONTAINER_SHOW_SOUND: AudioStream = preload("res://assets/sounds/ui/ui_main_menu_container_show.wav")

const START_GAME_SCENE_PATH := "res://scenes/start_game/start_game.tscn"

const MENU_SLIDE_OFFSET := Vector2(0, -220)
const MENU_INTRO_TIME := 0.28
const MENU_OUTRO_TIME := 0.36
const MENU_INTRO_FADE_TIME := 0.28
const MENU_OUTRO_FADE_TIME := 0.26

const START_GAME_DELAY := 0.04
const EXIT_GAME_DELAY := 0.08

const START_GAME_FADE_OUT_TIME := 0.50
const START_GAME_FADE_IN_TIME := 0.30

@onready var menuContent: Control = $MenuContent
@onready var mainMenuButtons: Control = $MenuContent/MainMenuButtons
@onready var mainMenuFooter: Control = $MenuContent/MainMenuFooter

var clickPlayer: AudioStreamPlayer
var startGamePlayer: AudioStreamPlayer
var containerShowPlayer: AudioStreamPlayer

var menuContentOriginalPosition := Vector2.ZERO
var menuTween: Tween
var isLeavingPage := false


# Prepares audio, connects components, and plays the main menu intro.
func _ready() -> void:
	setupAudioPlayers()
	connectComponentSignals()

	await get_tree().process_frame

	menuContentOriginalPosition = menuContent.position
	playMenuContentIntro()


# Creates the audio players used by the main menu.
func setupAudioPlayers() -> void:
	clickPlayer = createAudioPlayer(CLICK_SOUND)
	startGamePlayer = createAudioPlayer(START_GAME_SOUND)
	containerShowPlayer = createAudioPlayer(CONTAINER_SHOW_SOUND)


# Creates one audio player and attaches it to this scene.
func createAudioPlayer(stream: AudioStream) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Master"
	add_child(player)
	return player


# Connects child component signals to this screen controller.
func connectComponentSignals() -> void:
	if mainMenuButtons != null:
		connectSignalIfAvailable(mainMenuButtons, "startGamePressed", Callable(self, "onStartGamePressed"))
		connectSignalIfAvailable(mainMenuButtons, "profilePressed", Callable(self, "onProfilePressed"))
		connectSignalIfAvailable(mainMenuButtons, "settingsPressed", Callable(self, "onSettingsPressed"))
		connectSignalIfAvailable(mainMenuButtons, "exitGamePressed", Callable(self, "onExitGamePressed"))

	if mainMenuFooter != null:
		connectSignalIfAvailable(mainMenuFooter, "creditsPressed", Callable(self, "onCreditsPressed"))
		connectSignalIfAvailable(mainMenuFooter, "rankingPressed", Callable(self, "onRankingPressed"))
		connectSignalIfAvailable(mainMenuFooter, "achievementsPressed", Callable(self, "onAchievementsPressed"))


# Connects a signal only when the target has it and it is not already connected.
func connectSignalIfAvailable(target: Object, signalName: String, callback: Callable) -> void:
	if target == null:
		return

	if not target.has_signal(signalName):
		return

	if not target.is_connected(signalName, callback):
		target.connect(signalName, callback)


# Stops the current menu animation before starting another one.
func killMenuTween() -> void:
	if menuTween != null and menuTween.is_valid():
		menuTween.kill()


# Slides and fades the main menu content into view.
func playMenuContentIntro() -> void:
	if menuContent == null:
		return

	killMenuTween()

	menuContent.position = menuContentOriginalPosition + MENU_SLIDE_OFFSET
	menuContent.modulate = Color(1, 1, 1, 0)

	playSound(containerShowPlayer)

	menuTween = create_tween()
	menuTween.set_parallel(true)

	menuTween.tween_property(
		menuContent,
		"position",
		menuContentOriginalPosition,
		MENU_INTRO_TIME
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	menuTween.tween_property(
		menuContent,
		"modulate",
		Color(1, 1, 1, 1),
		MENU_INTRO_FADE_TIME
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# Slides and fades the main menu content out of view.
func playMenuContentOutro() -> void:
	if menuContent == null:
		return

	killMenuTween()

	menuContent.position = menuContentOriginalPosition
	menuContent.modulate = Color(1, 1, 1, 1)

	menuTween = create_tween()
	menuTween.set_parallel(true)

	menuTween.tween_property(
		menuContent,
		"position",
		menuContentOriginalPosition + MENU_SLIDE_OFFSET,
		MENU_OUTRO_TIME
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	menuTween.tween_property(
		menuContent,
		"modulate",
		Color(1, 1, 1, 0),
		MENU_OUTRO_FADE_TIME
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	await menuTween.finished


# Opens the start game screen.
func onStartGamePressed() -> void:
	if isLeavingPage:
		return

	isLeavingPage = true
	playSound(startGamePlayer)

	await get_tree().create_timer(START_GAME_DELAY).timeout
	await playMenuContentOutro()

	goToStartGame()


# Placeholder for opening the profile page.
func onProfilePressed() -> void:
	if isLeavingPage:
		return

	playSound(clickPlayer)
	print("Profile pressed")


# Placeholder for opening the settings page.
func onSettingsPressed() -> void:
	if isLeavingPage:
		return

	playSound(clickPlayer)
	print("Settings pressed")


# Exits the game after playing the outro animation.
func onExitGamePressed() -> void:
	if isLeavingPage:
		return

	isLeavingPage = true
	playSound(clickPlayer)

	await get_tree().create_timer(EXIT_GAME_DELAY).timeout
	await playMenuContentOutro()

	get_tree().quit()


# Placeholder for opening the credits page.
func onCreditsPressed() -> void:
	if isLeavingPage:
		return

	playSound(clickPlayer)
	print("Credits pressed")


# Placeholder for opening the ranking page.
func onRankingPressed() -> void:
	if isLeavingPage:
		return

	playSound(clickPlayer)
	print("Ranking pressed")


# Placeholder for opening the achievements page.
func onAchievementsPressed() -> void:
	if isLeavingPage:
		return

	playSound(clickPlayer)
	print("Achievements pressed")


# Changes from the main menu to the start game screen.
func goToStartGame() -> void:
	var transitionManager: Node = get_node_or_null("/root/SceneTransitionManager")

	if transitionManager != null and transitionManager.has_method("changeSceneWithFade"):
		transitionManager.call(
			"changeSceneWithFade",
			START_GAME_SCENE_PATH,
			START_GAME_FADE_OUT_TIME,
			START_GAME_FADE_IN_TIME
		)
		return

	get_tree().change_scene_to_file(START_GAME_SCENE_PATH)


# Plays an audio player from the start.
func playSound(player: AudioStreamPlayer) -> void:
	if player == null:
		return

	player.stop()
	player.play()
