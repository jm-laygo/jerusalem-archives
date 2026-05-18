extends Control

const CLICK_SOUND: AudioStream = preload("res://assets/sounds/ui/ui_generic_select.wav")
const PLAY_SOUND: AudioStream = preload("res://assets/sounds/ui/ui_play.wav")

const START_GAME_SCENE_PATH := "res://scenes/start_game/start_game.tscn"
const LEVEL_GAMEPLAY_SCENE_PATH := "res://scenes/level_gameplay/level_gameplay.tscn"

const DESIGN_WIDTH := 1080.0
const DESIGN_HEIGHT := 1920.0

const HEADER_LEFT := -182.0
const HEADER_TOP := -31.0
const HEADER_RIGHT := 1342.0
const HEADER_BOTTOM := 1263.0

const PLAY_BUTTON_POSITION := Vector2(735.0, 1060.0)
const PLAY_BUTTON_SIZE := Vector2(380.0, 145.0)

const FOOTER_LEFT := 0.0
const FOOTER_RIGHT := 1080.0
const FOOTER_HEIGHT := 200.0

const SCENE_FADE_OUT_TIME := 0.50
const SCENE_FADE_IN_TIME := 0.30

const DUCKED_MAIN_THEME_VOLUME := 0.2
const MUSIC_DUCK_TIME := 0.35
const MUSIC_STOP_HOLD_TIME := 0.15

@onready var background: TextureRect = get_node_or_null("Background")
@onready var header: TextureRect = get_node_or_null("Header")
@onready var contentLayer: Control = get_node_or_null("ContentLayer")
@onready var footer: Control = get_node_or_null("GameFooter")
@onready var playButton: TextureButton = get_node_or_null("ContentLayer/PlayButton")

var clickPlayer: AudioStreamPlayer


# Prepares audio, connects buttons, and applies the responsive phone layout.
func _ready() -> void:
	setupAudioPlayer()
	connectFooterSignals()
	connectPlayButtonSignal()

	applyPhoneLayout()

	await get_tree().process_frame
	applyPhoneLayout()


# Re-applies layout when the viewport size changes.
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		applyPhoneLayout()


# Applies the 1080x1920 design layout to the current viewport.
func applyPhoneLayout() -> void:
	var viewportSize := get_viewport_rect().size
	var scaleFactor: float = viewportSize.x / DESIGN_WIDTH
	var phoneOrigin := Vector2.ZERO

	forceRootLayout()
	forceBackgroundLayout()
	placeDesignNode(header, phoneOrigin, scaleFactor, HEADER_LEFT, HEADER_TOP, HEADER_RIGHT, HEADER_BOTTOM)
	forceContentLayerLayout(phoneOrigin, scaleFactor)
	forcePlayButtonLayout()
	placeBottomDesignNode(footer, scaleFactor, FOOTER_LEFT, FOOTER_RIGHT, FOOTER_HEIGHT)


# Makes the root fill the real viewport.
func forceRootLayout() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0


# Makes the background fill the real screen.
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


# Applies the scaled design space to the content layer.
func forceContentLayerLayout(phoneOrigin: Vector2, scaleFactor: float) -> void:
	if contentLayer == null:
		return

	contentLayer.anchor_left = 0.0
	contentLayer.anchor_top = 0.0
	contentLayer.anchor_right = 0.0
	contentLayer.anchor_bottom = 0.0
	contentLayer.position = phoneOrigin
	contentLayer.size = Vector2(DESIGN_WIDTH, DESIGN_HEIGHT)
	contentLayer.scale = Vector2(scaleFactor, scaleFactor)


# Places and sizes the play button inside the design frame.
func forcePlayButtonLayout() -> void:
	if playButton == null:
		return

	playButton.anchor_left = 0.0
	playButton.anchor_top = 0.0
	playButton.anchor_right = 0.0
	playButton.anchor_bottom = 0.0

	playButton.position = PLAY_BUTTON_POSITION
	playButton.size = PLAY_BUTTON_SIZE
	playButton.scale = Vector2.ONE

	playButton.stretch_mode = TextureButton.STRETCH_SCALE
	playButton.ignore_texture_size = true


# Places a control using design coordinates and viewport width scaling.
func placeDesignNode(
	node: Control,
	phoneOrigin: Vector2,
	scaleFactor: float,
	left: float,
	top: float,
	right: float,
	bottom: float
) -> void:
	if node == null:
		return

	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 0.0
	node.anchor_bottom = 0.0

	node.position = phoneOrigin + Vector2(left, top) * scaleFactor
	node.size = Vector2(right - left, bottom - top)
	node.scale = Vector2(scaleFactor, scaleFactor)


# Places a control at the real bottom of the viewport.
func placeBottomDesignNode(
	node: Control,
	scaleFactor: float,
	left: float,
	right: float,
	height: float
) -> void:
	if node == null:
		return

	var viewportSize := get_viewport_rect().size
	var scaledHeight := height * scaleFactor

	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 0.0
	node.anchor_bottom = 0.0

	node.position = Vector2(left * scaleFactor, viewportSize.y - scaledHeight)
	node.size = Vector2(right - left, height)
	node.scale = Vector2(scaleFactor, scaleFactor)


# Creates the audio player used for simple UI sounds.
func setupAudioPlayer() -> void:
	clickPlayer = AudioStreamPlayer.new()
	clickPlayer.stream = CLICK_SOUND
	clickPlayer.bus = "Master"
	add_child(clickPlayer)


# Connects shared footer signals.
func connectFooterSignals() -> void:
	if footer == null:
		push_error("GameFooter not found in LevelSelection.")
		return

	connectSignalIfAvailable(footer, "backPressed", Callable(self, "onFooterBackPressed"))
	connectSignalIfAvailable(footer, "settingsPressed", Callable(self, "onFooterSettingsPressed"))
	connectSignalIfAvailable(footer, "achievementsPressed", Callable(self, "onFooterAchievementsPressed"))


# Connects the play button signal.
func connectPlayButtonSignal() -> void:
	if playButton == null:
		push_error("PlayButton not found in LevelSelection.")
		return

	var playCallable := Callable(self, "onPlayButtonPressed")

	if not playButton.pressed.is_connected(playCallable):
		playButton.pressed.connect(playCallable)


# Connects a signal only when it exists and is not already connected.
func connectSignalIfAvailable(target: Object, signalName: String, callback: Callable) -> void:
	if target == null:
		return

	if not target.has_signal(signalName):
		push_error("%s has no %s signal." % [target.name, signalName])
		return

	if not target.is_connected(signalName, callback):
		target.connect(signalName, callback)


# Returns to the start game screen.
func onFooterBackPressed() -> void:
	playPersistentSound(CLICK_SOUND)
	changeSceneWithFade(START_GAME_SCENE_PATH)


# Placeholder for opening settings.
func onFooterSettingsPressed() -> void:
	playSound(CLICK_SOUND)
	print("Footer settings pressed in LevelSelection.")


# Placeholder for opening achievements.
func onFooterAchievementsPressed() -> void:
	playSound(CLICK_SOUND)
	print("Footer achievements pressed in LevelSelection.")


# Starts gameplay from the selected level.
func onPlayButtonPressed() -> void:
	playPersistentSound(PLAY_SOUND)
	duckMainThemeMusicThenStop()
	changeSceneWithFade(LEVEL_GAMEPLAY_SCENE_PATH)


# Changes scene using the global transition manager when available.
func changeSceneWithFade(scenePath: String) -> void:
	var transitionManager: Node = get_node_or_null("/root/SceneTransitionManager")

	if transitionManager != null and transitionManager.has_method("changeSceneWithFade"):
		transitionManager.call(
			"changeSceneWithFade",
			scenePath,
			SCENE_FADE_OUT_TIME,
			SCENE_FADE_IN_TIME
		)
		return

	get_tree().change_scene_to_file(scenePath)


# Plays a sound through the reusable UI audio player.
func playSound(sound: AudioStream) -> void:
	if clickPlayer == null:
		return

	clickPlayer.stream = sound
	clickPlayer.stop()
	clickPlayer.play()


# Plays a sound that can continue after this scene changes.
func playPersistentSound(sound: AudioStream) -> void:
	var soundPlayer := AudioStreamPlayer.new()
	soundPlayer.stream = sound
	get_tree().root.add_child(soundPlayer)
	soundPlayer.play()
	soundPlayer.finished.connect(soundPlayer.queue_free)


# Ducks and stops the main theme before gameplay starts.
func duckMainThemeMusicThenStop() -> void:
	var musicManager: Node = get_node_or_null("/root/MusicManager")

	if musicManager != null and musicManager.has_method("duckMainThemeThenStop"):
		musicManager.call(
			"duckMainThemeThenStop",
			DUCKED_MAIN_THEME_VOLUME,
			MUSIC_DUCK_TIME,
			MUSIC_STOP_HOLD_TIME
		)
