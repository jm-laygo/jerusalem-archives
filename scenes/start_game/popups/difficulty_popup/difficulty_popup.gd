extends Popup

signal closed
signal difficultySelected(pageId: String, difficultyName: String)

const CONTAINER_SHOW_SOUND: AudioStream = preload("res://assets/sounds/ui/ui_main_menu_container_show.wav")
const CLICK_SOUND: AudioStream = preload("res://assets/sounds/ui/ui_generic_select.wav")

const POPUP_SIZE := Vector2i(900, 1400)
const OVERLAY_COLOR := Color(0, 0, 0, 0.62)
const TRANSPARENT_COLOR := Color(0, 0, 0, 0)

const SHOW_TIME := 0.28
const HIDE_TIME := 0.24

const SHOW_OFFSET := Vector2(0, 80)
const HIDE_OFFSET := Vector2(0, 80)

@onready var container: Control = $DifficultyContainer

var containerShowPlayer: AudioStreamPlayer
var clickPlayer: AudioStreamPlayer

var overlay: ColorRect
var popupTween: Tween

var selectedPageId := ""
var containerOriginalPosition := Vector2.ZERO

var isShowing := false
var isClosing := false
var allowHide := false


# Prepares popup behavior, audio, and container signals.
func _ready() -> void:
	exclusive = true

	setupAudioPlayers()
	connectComponentSignals()

	if container != null:
		containerOriginalPosition = container.position
		container.modulate = Color(1, 1, 1, 0)

	if not popup_hide.is_connected(onPopupHide):
		popup_hide.connect(onPopupHide)


# Stores the selected chapter/page id used when a difficulty is chosen.
func setup(pageId: String) -> void:
	selectedPageId = pageId


# Creates audio players used by the popup.
func setupAudioPlayers() -> void:
	containerShowPlayer = createAudioPlayer(CONTAINER_SHOW_SOUND)
	clickPlayer = createAudioPlayer(CLICK_SOUND)


# Creates one audio player and attaches it to this popup.
func createAudioPlayer(stream: AudioStream) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Master"
	add_child(player)
	return player


# Connects signals from the difficulty container.
func connectComponentSignals() -> void:
	if container == null:
		push_error("DifficultyContainer not found.")
		return

	connectSignalIfAvailable(container, "closePressed", Callable(self, "onClosePressed"))
	connectSignalIfAvailable(container, "difficultySelected", Callable(self, "onDifficultySelected"))


# Connects a signal only when it exists and is not already connected.
func connectSignalIfAvailable(target: Object, signalName: String, callback: Callable) -> void:
	if target == null:
		return

	if not target.has_signal(signalName):
		push_error("%s has no %s signal." % [target.name, signalName])
		return

	if not target.is_connected(signalName, callback):
		target.connect(signalName, callback)


# Shows the popup with overlay and container animation.
func showWithAnimation() -> void:
	if isShowing or isClosing:
		return

	isShowing = true
	isClosing = false
	allowHide = false

	killTweens()
	createOverlay()

	popup_centered(POPUP_SIZE)
	await get_tree().process_frame

	if container != null:
		containerOriginalPosition = container.position
		container.position = containerOriginalPosition + SHOW_OFFSET
		container.modulate = Color(1, 1, 1, 0)

	playSound(containerShowPlayer)

	popupTween = create_tween()
	popupTween.set_parallel(true)

	if overlay != null:
		overlay.color = TRANSPARENT_COLOR
		overlay.visible = true
		popupTween.tween_property(
			overlay,
			"color",
			OVERLAY_COLOR,
			SHOW_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if container != null:
		popupTween.tween_property(
			container,
			"position",
			containerOriginalPosition,
			SHOW_TIME
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		popupTween.tween_property(
			container,
			"modulate",
			Color(1, 1, 1, 1),
			SHOW_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await popupTween.finished
	isShowing = false


# Closes the popup with overlay and container animation.
func closeWithAnimation() -> void:
	if isClosing:
		return

	isClosing = true
	isShowing = false
	allowHide = true

	killTweens()
	playSound(clickPlayer)

	popupTween = create_tween()
	popupTween.set_parallel(true)

	if container != null:
		popupTween.tween_property(
			container,
			"position",
			containerOriginalPosition + HIDE_OFFSET,
			HIDE_TIME
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

		popupTween.tween_property(
			container,
			"modulate",
			Color(1, 1, 1, 0),
			HIDE_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if overlay != null:
		popupTween.tween_property(
			overlay,
			"color",
			TRANSPARENT_COLOR,
			HIDE_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await popupTween.finished

	hide()
	removeOverlay()

	isClosing = false
	allowHide = false

	closed.emit()
	queue_free()


# Creates the dark overlay behind the popup.
func createOverlay() -> void:
	if overlay != null and is_instance_valid(overlay):
		return

	var parentNode := get_parent()

	if parentNode == null:
		return

	overlay = ColorRect.new()
	overlay.name = "DifficultyDarkOverlay"
	overlay.color = TRANSPARENT_COLOR
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = true

	parentNode.add_child(overlay)
	parentNode.move_child(overlay, get_index())

	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.offset_left = 0
	overlay.offset_top = 0
	overlay.offset_right = 0
	overlay.offset_bottom = 0


# Removes the dark overlay.
func removeOverlay() -> void:
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()

	overlay = null


# Stops active popup tweens before creating new ones.
func killTweens() -> void:
	if popupTween != null and popupTween.is_valid():
		popupTween.kill()


# Prevents accidental direct hiding without the close animation.
func onPopupHide() -> void:
	if allowHide or isClosing:
		return

	call_deferred("forceRestorePopup")


# Restores the popup if Godot hides it without using the animation.
func forceRestorePopup() -> void:
	if isClosing:
		return

	createOverlay()

	if overlay != null:
		overlay.color = OVERLAY_COLOR
		overlay.visible = true

	popup_centered(POPUP_SIZE)

	await get_tree().process_frame

	if container != null:
		container.position = containerOriginalPosition
		container.modulate = Color(1, 1, 1, 1)


# Handles close button press.
func onClosePressed() -> void:
	closeWithAnimation()


# Emits the selected difficulty and closes the popup.
func onDifficultySelected(difficultyName: String) -> void:
	difficultySelected.emit(selectedPageId, difficultyName)
	await closeWithAnimation()


# Plays an audio player from the start.
func playSound(player: AudioStreamPlayer) -> void:
	if player == null:
		return

	player.stop()
	player.play()
