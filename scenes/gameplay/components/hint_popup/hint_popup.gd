extends Control

signal popup_closed

const EMPTY_HINT_TEXT := "No more hints available."

const FADE_IN_DURATION := 0.18
const FADE_OUT_DURATION := 0.18
const AUTO_CLOSE_DELAY := 10.0

const BACKGROUND_IMAGE_OPACITY := 0.90

@onready var popupBackground: TextureRect = $PopupBackground
@onready var hintLabel: Label = $PopupBackground/HintLabel

var closeTween: Tween = null
var autoCloseTimer: Timer = null


# Prepares the hint popup.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 1.0
	z_index = 900

	if popupBackground != null:
		popupBackground.mouse_filter = Control.MOUSE_FILTER_IGNORE
		popupBackground.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		popupBackground.stretch_mode = TextureRect.STRETCH_SCALE
		popupBackground.self_modulate = Color(1, 1, 1, BACKGROUND_IMAGE_OPACITY)

	if hintLabel != null:
		hintLabel.text = EMPTY_HINT_TEXT
		hintLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hintLabel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hintLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hintLabel.clip_text = false
		hintLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hintLabel.modulate = Color(1, 1, 1, 1)

	setupAutoCloseTimer()


# Creates the timer used to auto-close the popup.
func setupAutoCloseTimer() -> void:
	autoCloseTimer = Timer.new()
	autoCloseTimer.name = "AutoCloseTimer"
	autoCloseTimer.one_shot = true
	autoCloseTimer.wait_time = AUTO_CLOSE_DELAY
	autoCloseTimer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(autoCloseTimer)

	autoCloseTimer.timeout.connect(closePopup)


# Opens the popup with the given hint text.
func openPopup(hintText: String) -> void:
	if hintLabel != null:
		if hintText.strip_edges().is_empty():
			hintLabel.text = EMPTY_HINT_TEXT
		else:
			hintLabel.text = hintText

	visible = true
	move_to_front()
	playOpenFade()

	if autoCloseTimer != null:
		autoCloseTimer.stop()
		autoCloseTimer.start()


# Plays the fade-in animation.
func playOpenFade() -> void:
	killTween()

	modulate.a = 0.0

	var fadeTween := create_tween()
	closeTween = fadeTween
	fadeTween.tween_property(
		self,
		"modulate:a",
		1.0,
		FADE_IN_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# Starts fade-out then hides the popup.
func closePopup() -> void:
	if not visible:
		return

	killTween()

	var fadeTween := create_tween()
	closeTween = fadeTween
	fadeTween.tween_property(
		self,
		"modulate:a",
		0.0,
		FADE_OUT_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	fadeTween.finished.connect(_finishClose)


# Finishes the close action.
func _finishClose() -> void:
	visible = false
	modulate.a = 1.0
	popup_closed.emit()


# Stops the active tween.
func killTween() -> void:
	if closeTween != null and closeTween.is_valid():
		closeTween.kill()

	closeTween = null