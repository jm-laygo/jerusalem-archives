extends Control

signal creditsPressed
signal achievementsPressed

const FOOTER_NORMAL_MODULATE := Color(1, 1, 1, 1)
const FOOTER_PRESSED_MODULATE := Color(0.55, 0.55, 0.55, 1)

@onready var creditsIcon: TextureButton = $CreditsIcon
@onready var achievementsIcon: TextureButton = $AchievementsIcon


# Prepares footer icons and connects their pressed signals.
func _ready() -> void:
	setupFooterButtons()
	connectFooterSignals()


# Applies shared setup to all footer icon buttons.
func setupFooterButtons() -> void:
	setupFooterButton(creditsIcon)
	setupFooterButton(achievementsIcon)


# Connects footer icon buttons to public footer signals.
func connectFooterSignals() -> void:
	if not creditsIcon.pressed.is_connected(creditsPressed.emit):
		creditsIcon.pressed.connect(creditsPressed.emit)

	if not achievementsIcon.pressed.is_connected(achievementsPressed.emit):
		achievementsIcon.pressed.connect(achievementsPressed.emit)


# Prepares one footer icon button for consistent interaction feedback.
func setupFooterButton(button: TextureButton) -> void:
	if button == null:
		return

	button.focus_mode = Control.FOCUS_NONE
	button.texture_hover = button.texture_normal
	button.texture_focused = button.texture_normal
	button.texture_pressed = button.texture_normal
	button.modulate = FOOTER_NORMAL_MODULATE

	var buttonDownCallable := onFooterButtonDown.bind(button)
	var buttonUpCallable := onFooterButtonUp.bind(button)
	var mouseExitedCallable := onFooterButtonMouseExited.bind(button)

	if not button.button_down.is_connected(buttonDownCallable):
		button.button_down.connect(buttonDownCallable)

	if not button.button_up.is_connected(buttonUpCallable):
		button.button_up.connect(buttonUpCallable)

	if not button.mouse_exited.is_connected(mouseExitedCallable):
		button.mouse_exited.connect(mouseExitedCallable)


# Darkens the footer icon while pressed.
func onFooterButtonDown(button: TextureButton) -> void:
	if button == null:
		return

	button.modulate = FOOTER_PRESSED_MODULATE


# Restores the footer icon after release.
func onFooterButtonUp(button: TextureButton) -> void:
	if button == null:
		return

	button.modulate = FOOTER_NORMAL_MODULATE


# Restores the footer icon when the cursor leaves it.
func onFooterButtonMouseExited(button: TextureButton) -> void:
	if button == null:
		return

	if button.button_pressed:
		return

	button.modulate = FOOTER_NORMAL_MODULATE