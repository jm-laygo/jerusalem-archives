extends Control

signal closed

const CONTAINER_SHOW_SOUND: AudioStream = preload("res://assets/sounds/ui/ui_main_menu_container_show.wav")
const CLICK_SOUND: AudioStream = preload("res://assets/sounds/ui/ui_generic_select.wav")

const OVERLAY_COLOR := Color(0, 0, 0, 0.62)
const TRANSPARENT_COLOR := Color(0, 0, 0, 0)

const DESIGN_WIDTH := 900.0
const DESIGN_HEIGHT := 1400.0

const SHOW_TIME := 0.28
const HIDE_TIME := 0.24

const SHOW_OFFSET := Vector2(0, 80)
const HIDE_OFFSET := Vector2(0, 80)

@onready var overlay: ColorRect = $SettingsDarkOverlay
@onready var container: Control = $SettingsContainer

var containerShowPlayer: AudioStreamPlayer
var clickPlayer: AudioStreamPlayer

var popupTween: Tween
var containerTargetPosition := Vector2.ZERO

var isShowing := false
var isClosing := false


func _ready() -> void:
	z_index = 1000
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	setupAudioPlayers()
	connectComponentSignals()
	forcePopupLayout()

	if overlay != null:
		overlay.color = TRANSPARENT_COLOR

	if container != null:
		container.modulate = Color(1, 1, 1, 0)


func setupAudioPlayers() -> void:
	containerShowPlayer = createAudioPlayer(CONTAINER_SHOW_SOUND)
	clickPlayer = createAudioPlayer(CLICK_SOUND)


func createAudioPlayer(stream: AudioStream) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Master"
	add_child(player)
	return player


func connectComponentSignals() -> void:
	if container == null:
		push_error("SettingsContainer not found.")
		return

	connectSignalIfAvailable(container, "closePressed", Callable(self, "onClosePressed"))


func connectSignalIfAvailable(target: Object, signalName: String, callback: Callable) -> void:
	if target == null:
		return

	if not target.has_signal(signalName):
		push_error("%s has no %s signal." % [target.name, signalName])
		return

	if not target.is_connected(signalName, callback):
		target.connect(signalName, callback)


func forcePopupLayout() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0

	if overlay != null:
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.offset_left = 0.0
		overlay.offset_top = 0.0
		overlay.offset_right = 0.0
		overlay.offset_bottom = 0.0
		overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	forceContainerLayout()


func forceContainerLayout() -> void:
	if container == null:
		return

	var viewportSize := get_viewport_rect().size
	var scaleFactor: float = min(
		viewportSize.x / DESIGN_WIDTH,
		viewportSize.y / DESIGN_HEIGHT
	)

	scaleFactor = min(scaleFactor, 1.0)

	container.anchor_left = 0.5
	container.anchor_top = 0.5
	container.anchor_right = 0.5
	container.anchor_bottom = 0.5

	container.offset_left = -(DESIGN_WIDTH / 2.0)
	container.offset_top = -(DESIGN_HEIGHT / 2.0)
	container.offset_right = DESIGN_WIDTH / 2.0
	container.offset_bottom = DESIGN_HEIGHT / 2.0
	container.scale = Vector2(scaleFactor, scaleFactor)

	containerTargetPosition = container.position


func showWithAnimation() -> void:
	if isShowing or isClosing:
		return

	isShowing = true
	isClosing = false

	killTween()

	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	move_to_front()

	forcePopupLayout()

	if overlay != null:
		overlay.color = TRANSPARENT_COLOR

	if container != null:
		container.position = containerTargetPosition + SHOW_OFFSET
		container.modulate = Color(1, 1, 1, 0)

	playSound(containerShowPlayer)

	popupTween = create_tween()
	popupTween.set_parallel(true)

	if overlay != null:
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
			containerTargetPosition,
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


func closeWithAnimation() -> void:
	if isClosing:
		return

	isClosing = true
	isShowing = false

	killTween()
	playSound(clickPlayer)

	popupTween = create_tween()
	popupTween.set_parallel(true)

	if container != null:
		popupTween.tween_property(
			container,
			"position",
			containerTargetPosition + HIDE_OFFSET,
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

	closed.emit()
	queue_free()


func killTween() -> void:
	if popupTween != null and popupTween.is_valid():
		popupTween.kill()


func onClosePressed() -> void:
	closeWithAnimation()


func playSound(player: AudioStreamPlayer) -> void:
	if player == null:
		return

	player.stop()
	player.play()
