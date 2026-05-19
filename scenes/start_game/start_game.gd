extends Control

const CLICK_SOUND: AudioStream = preload("res://assets/sounds/ui/ui_generic_select.wav")
const BACK_NEXT_SOUND: AudioStream = preload("res://assets/sounds/ui/ui_next_back.wav")
const SELECT_SOUND: AudioStream = preload("res://assets/sounds/ui/ui_select_chapter.wav")
const START_GAME_SHOW_SOUND: AudioStream = preload("res://assets/sounds/ui/ui_start_game_show.wav")


const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu/main_menu.tscn"
const LEVEL_SELECTION_SCENE_PATH := "res://scenes/level_selection/level_selection.tscn"

const DESIGN_WIDTH := 1080.0
const FOOTER_HEIGHT := 200.0

const INTRO_ANIMATION_TIME := 0.30
const OUTRO_ANIMATION_TIME := 0.30
const SELECT_POPUP_DELAY := 0.04

const MAIN_MENU_FADE_OUT_TIME := 0.50
const MAIN_MENU_FADE_IN_TIME := 0.30

const LEVEL_SELECTION_FADE_OUT_TIME := 0.50
const LEVEL_SELECTION_FADE_IN_TIME := 0.30

@onready var background: Control = $Background
@onready var chapterSlider: Control = $ChapterSlider
@onready var footer: Control = $Footer
@onready var popupLayer: Control = $PopupLayer

var clickPlayer: AudioStreamPlayer
var backNextPlayer: AudioStreamPlayer
var selectPlayer: AudioStreamPlayer
var startGameShowPlayer: AudioStreamPlayer

var selectedPageId := ""
var selectedDifficultyName := ""

var isLeavingPage := false


# Prepares audio, connects components, fixes layout, and plays the intro.
func _ready() -> void:
	setupAudioPlayers()
	connectComponentSignals()

	await get_tree().process_frame
	await get_tree().process_frame

	forceStartGameLayout()
	prepareIntroState()
	playStartGameShowSound()
	await playIntroAnimation()


# Re-applies layout when the window or viewport size changes.
func _notification(what: int) -> void:
	if what != NOTIFICATION_RESIZED:
		return

	if not is_node_ready():
		return

	forceStartGameLayout()
	call_deferred("forceStartGameLayout")


# Forces all major screen sections into their correct positions.
func forceStartGameLayout() -> void:
	forceBackgroundLayout()
	forceChapterSliderLayout()
	forceFooterLayout()
	forcePopupLayerLayout()


# Makes the background fill the entire screen.
func forceBackgroundLayout() -> void:
	if background == null:
		return

	background.anchor_left = 0.0
	background.anchor_top = 0.0
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.offset_left = 0.0
	background.offset_top = 0.0
	background.offset_right = 0.0
	background.offset_bottom = 0.0
	background.scale = Vector2.ONE


# Centers and sizes the chapter slider above the footer.
func forceChapterSliderLayout() -> void:
	if chapterSlider == null:
		if is_node_ready():
			push_error("ChapterSlider node not found in StartGame.")
		return

	var chapterSliderHeight: float = max(900.0, size.y - FOOTER_HEIGHT)

	if chapterSlider.has_method("forceDesignLayout"):
		chapterSlider.call("forceDesignLayout", chapterSliderHeight)

	chapterSlider.anchor_left = 0.5
	chapterSlider.anchor_right = 0.5
	chapterSlider.anchor_top = 0.0
	chapterSlider.anchor_bottom = 0.0

	chapterSlider.offset_left = -(DESIGN_WIDTH / 2.0)
	chapterSlider.offset_right = DESIGN_WIDTH / 2.0
	chapterSlider.offset_top = 0.0
	chapterSlider.offset_bottom = chapterSliderHeight
	chapterSlider.scale = Vector2.ONE

	if chapterSlider.has_method("forceNavigationVisible"):
		chapterSlider.call("forceNavigationVisible")


# Pins the footer to the bottom of the screen.
func forceFooterLayout() -> void:
	if footer == null:
		return

	footer.anchor_left = 0.5
	footer.anchor_right = 0.5
	footer.anchor_top = 1.0
	footer.anchor_bottom = 1.0

	footer.offset_left = -(DESIGN_WIDTH / 2.0)
	footer.offset_right = DESIGN_WIDTH / 2.0
	footer.offset_top = -FOOTER_HEIGHT
	footer.offset_bottom = 0.0

	footer.scale = Vector2.ONE
	footer.grow_horizontal = Control.GROW_DIRECTION_BOTH
	footer.grow_vertical = Control.GROW_DIRECTION_BEGIN

	if footer.has_method("forceBottomLayout"):
		footer.call("forceBottomLayout")


# Makes the popup layer full screen and disables it when empty.
func forcePopupLayerLayout() -> void:
	if popupLayer == null:
		return

	popupLayer.anchor_left = 0.0
	popupLayer.anchor_top = 0.0
	popupLayer.anchor_right = 1.0
	popupLayer.anchor_bottom = 1.0

	popupLayer.offset_left = 0.0
	popupLayer.offset_top = 0.0
	popupLayer.offset_right = 0.0
	popupLayer.offset_bottom = 0.0

	if popupLayer.get_child_count() == 0:
		popupLayer.visible = false
		popupLayer.mouse_filter = Control.MOUSE_FILTER_IGNORE


# Creates the audio players used by this screen.
func setupAudioPlayers() -> void:
	clickPlayer = createAudioPlayer(CLICK_SOUND)
	backNextPlayer = createAudioPlayer(BACK_NEXT_SOUND)
	selectPlayer = createAudioPlayer(SELECT_SOUND)
	startGameShowPlayer = createAudioPlayer(START_GAME_SHOW_SOUND)


# Creates one audio player and adds it to this scene.
func createAudioPlayer(stream: AudioStream) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Master"
	add_child(player)
	return player


# Connects child component signals to this screen controller.
func connectComponentSignals() -> void:
	if chapterSlider != null:
		connectSignalIfAvailable(chapterSlider, "backNextPressed", Callable(self, "onChapterSliderBackNextPressed"))
		connectSignalIfAvailable(chapterSlider, "selectPressed", Callable(self, "onChapterSliderSelectPressed"))
	else:
		push_error("ChapterSlider not found. Back/next/select will not work.")

	if footer != null:
		connectSignalIfAvailable(footer, "backPressed", Callable(self, "onFooterBackPressed"))
		connectSignalIfAvailable(footer, "settingsPressed", Callable(self, "onFooterSettingsPressed"))
		connectSignalIfAvailable(footer, "achievementsPressed", Callable(self, "onFooterAchievementsPressed"))


# Connects a signal only when the target has it and it is not already connected.
func connectSignalIfAvailable(target: Object, signalName: String, callback: Callable) -> void:
	if target == null:
		return

	if not target.has_signal(signalName):
		push_error("%s has no %s signal." % [target.name, signalName])
		return

	if not target.is_connected(signalName, callback):
		target.connect(signalName, callback)


# Sets child components to their hidden intro starting state.
func prepareIntroState() -> void:
	if chapterSlider != null and chapterSlider.has_method("prepareIntroState"):
		chapterSlider.call("prepareIntroState")

	if footer != null and footer.has_method("prepareIntroState"):
		footer.call("prepareIntroState")


# Plays the screen opening sound effect.
func playStartGameShowSound() -> void:
	playSound(startGameShowPlayer)


# Plays intro animations for the chapter slider and footer.
func playIntroAnimation() -> void:
	if chapterSlider != null and chapterSlider.has_method("playIntroAnimation"):
		chapterSlider.call("playIntroAnimation")

	if footer != null and footer.has_method("playIntroAnimation"):
		footer.call("playIntroAnimation")

	await get_tree().create_timer(INTRO_ANIMATION_TIME).timeout

	if chapterSlider != null and chapterSlider.has_method("forceNavigationVisible"):
		chapterSlider.call("forceNavigationVisible")


# Plays outro animations before leaving the screen.
func playOutroAnimation() -> void:
	if chapterSlider != null and chapterSlider.has_method("playOutroAnimation"):
		chapterSlider.call("playOutroAnimation")

	if footer != null and footer.has_method("playOutroAnimation"):
		footer.call("playOutroAnimation")

	await get_tree().create_timer(OUTRO_ANIMATION_TIME).timeout


# Plays the chapter navigation sound when previous/next is pressed.
func onChapterSliderBackNextPressed() -> void:
	playSound(backNextPlayer)


# Handles the select button press and advances to level selection.
func onChapterSliderSelectPressed(_pageId: String) -> void:
	if isLeavingPage:
		return

	isLeavingPage = true
	playPersistentSound(SELECT_SOUND)

	await playOutroAnimation()
	goToLevelSelection()


# Removes all existing popup instances.
func clearPopupLayer() -> void:
	if popupLayer == null:
		return

	for child in popupLayer.get_children():
		child.queue_free()


# Hides and clears the difficulty popup when it closes.
func onDifficultyPopupClosed() -> void:
	if popupLayer == null:
		return

	popupLayer.visible = false
	popupLayer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clearPopupLayer()


# Returns to the main menu.
func onFooterBackPressed() -> void:
	if isLeavingPage:
		return

	isLeavingPage = true
	playSound(clickPlayer)

	await playOutroAnimation()
	goToMainMenu()


# Placeholder for opening settings.
func onFooterSettingsPressed() -> void:
	playSound(clickPlayer)
	print("Settings pressed")


# Placeholder for opening achievements.
func onFooterAchievementsPressed() -> void:
	playSound(clickPlayer)
	print("Achievements pressed")


# Changes the current scene to level selection.
func goToLevelSelection() -> void:
	var transitionManager: Node = get_node_or_null("/root/SceneTransitionManager")

	if transitionManager != null and transitionManager.has_method("changeSceneWithFade"):
		transitionManager.call(
			"changeSceneWithFade",
			LEVEL_SELECTION_SCENE_PATH,
			LEVEL_SELECTION_FADE_OUT_TIME,
			LEVEL_SELECTION_FADE_IN_TIME
		)
		return

	get_tree().change_scene_to_file(LEVEL_SELECTION_SCENE_PATH)


# Changes the current scene back to the main menu.
func goToMainMenu() -> void:
	var transitionManager: Node = get_node_or_null("/root/SceneTransitionManager")

	if transitionManager != null and transitionManager.has_method("changeSceneWithFade"):
		transitionManager.call(
			"changeSceneWithFade",
			MAIN_MENU_SCENE_PATH,
			MAIN_MENU_FADE_OUT_TIME,
			MAIN_MENU_FADE_IN_TIME
		)
		return

	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


# Plays a reusable audio player from the start.
func playSound(player: AudioStreamPlayer) -> void:
	if player == null:
		return

	player.stop()
	player.play()


# Plays a sound that can continue even if the current scene changes.
func playPersistentSound(sound: AudioStream) -> void:
	if sound == null:
		return

	var soundPlayer := AudioStreamPlayer.new()
	soundPlayer.stream = sound
	soundPlayer.bus = "Master"
	get_tree().root.add_child(soundPlayer)
	soundPlayer.play()
	soundPlayer.finished.connect(soundPlayer.queue_free)