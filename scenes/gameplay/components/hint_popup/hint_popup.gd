extends Control

signal popup_closed

const EMPTY_HINT_TEXT := "No hint available."

const FADE_IN_DURATION := 0.18
const FADE_OUT_DURATION := 0.18
const AUTO_CLOSE_DELAY := 3.4

@onready var popup_background: TextureRect = $PopupBackground
@onready var hint_label: Label = $PopupBackground/HintLabel

var closeTween: Tween = null
var autoCloseTimer: Timer = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0

	if popup_background != null:
		popup_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		popup_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		popup_background.stretch_mode = TextureRect.STRETCH_SCALE

	if hint_label != null:
		hint_label.text = EMPTY_HINT_TEXT
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint_label.clip_text = false
		hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	setupAutoCloseTimer()


# Creates the timer used to hide the hint after a few seconds.
func setupAutoCloseTimer() -> void:
	autoCloseTimer = Timer.new()
	autoCloseTimer.name = "AutoCloseTimer"
	autoCloseTimer.one_shot = true
	autoCloseTimer.wait_time = AUTO_CLOSE_DELAY
	autoCloseTimer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(autoCloseTimer)

	autoCloseTimer.timeout.connect(closePopup)


# Opens the hint popup with text.
func openPopup(hintText: String) -> void:
	if hint_label != null:
		if hintText.strip_edges().is_empty():
			hint_label.text = EMPTY_HINT_TEXT
		else:
			hint_label.text = hintText

	visible = true
	move_to_front()
	playOpenFade()

	if autoCloseTimer != null:
		autoCloseTimer.stop()
		autoCloseTimer.start()


# Plays fade in.
func playOpenFade() -> void:
	killTween()

	modulate.a = 0.0

	closeTween = create_tween()
	closeTween.tween_property(self, "modulate:a", 1.0, FADE_IN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# Starts fade out.
func closePopup() -> void:
	if not visible:
		return

	killTween()

	closeTween = create_tween()
	closeTween.tween_property(self, "modulate:a", 0.0, FADE_OUT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	closeTween.finished.connect(finishClose)


# Finishes closing.
func finishClose() -> void:
	visible = false
	popup_closed.emit()


# Stops the current tween.
func killTween() -> void:
	if closeTween != null and closeTween.is_valid():
		closeTween.kill()

	closeTween = null