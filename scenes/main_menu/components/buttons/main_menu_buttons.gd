extends Control

signal startGamePressed
signal creditsPressed
signal exitGamePressed

const MAIN_NORMAL_TEXTURE: Texture2D = preload("res://assets/interface/buttons/btn_main_menu.png")
const MAIN_PRESSED_TEXTURE: Texture2D = preload("res://assets/interface/buttons/btn_main_menu_pressed.png")

const BUTTON_TEXTURE_MARGIN_LEFT := 48.0
const BUTTON_TEXTURE_MARGIN_TOP := 18.0
const BUTTON_TEXTURE_MARGIN_RIGHT := 48.0
const BUTTON_TEXTURE_MARGIN_BOTTOM := 18.0

const CLICK_FEEDBACK_TIME := 0.045

const BUTTON_PRESSED_SCALE := Vector2(0.97, 0.94)
const BUTTON_PUSH_OFFSET := Vector2(0, 3)
const BUTTON_PUSH_TIME := 0.045
const BUTTON_RELEASE_TIME := 0.10

const TEXT_NORMAL_COLOR := Color(1, 1, 1, 1)
const TEXT_PRESSED_COLOR := Color(0.90, 0.62, 0.39, 1)

@onready var startGameButton: Button = $StartGameButton
@onready var creditsButton: Button = $CreditsButton
@onready var exitGameButton: Button = $ExitGameButton

var mainNormalStyle: StyleBoxTexture
var mainPressedStyle: StyleBoxTexture

var buttonStateTokens := {}
var buttonOriginalPositions := {}
var buttonTweens := {}


# Creates button styles, waits for layout sizing, then prepares all menu buttons.
func _ready() -> void:
	createButtonStyles()

	await get_tree().process_frame

	setupButtons()
	connectButtonSignals()


# Creates reusable styleboxes for normal and pressed button states.
func createButtonStyles() -> void:
	mainNormalStyle = createButtonStyle(MAIN_NORMAL_TEXTURE)
	mainPressedStyle = createButtonStyle(MAIN_PRESSED_TEXTURE)


# Creates a scalable texture stylebox for the main menu buttons.
func createButtonStyle(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = BUTTON_TEXTURE_MARGIN_LEFT
	style.texture_margin_top = BUTTON_TEXTURE_MARGIN_TOP
	style.texture_margin_right = BUTTON_TEXTURE_MARGIN_RIGHT
	style.texture_margin_bottom = BUTTON_TEXTURE_MARGIN_BOTTOM
	return style


# Applies shared setup to all main menu buttons.
func setupButtons() -> void:
	setupMainButton(startGameButton)
	setupMainButton(creditsButton)
	setupMainButton(exitGameButton)


# Connects button press events to this component's public signals.
func connectButtonSignals() -> void:
	if not startGameButton.pressed.is_connected(startGamePressed.emit):
		startGameButton.pressed.connect(startGamePressed.emit)

	if not creditsButton.pressed.is_connected(creditsPressed.emit):
		creditsButton.pressed.connect(creditsPressed.emit)

	if not exitGameButton.pressed.is_connected(exitGamePressed.emit):
		exitGameButton.pressed.connect(exitGamePressed.emit)


# Prepares one button's focus, pivot, style, position memory, and press animations.
func setupMainButton(button: Button) -> void:
	if button == null:
		return

	button.focus_mode = Control.FOCUS_NONE
	button.scale = Vector2.ONE
	button.pivot_offset = button.size * 0.5

	buttonStateTokens[button] = 0
	buttonOriginalPositions[button] = button.position

	applyMainButtonNormal(button)
	connectButtonFeedbackSignals(button)


# Connects visual feedback signals for a single button.
func connectButtonFeedbackSignals(button: Button) -> void:
	if button == null:
		return

	var buttonDownCallable := onMainButtonDown.bind(button)
	var buttonUpCallable := onMainButtonUp.bind(button)
	var mouseExitedCallable := onMainButtonMouseExited.bind(button)

	if not button.button_down.is_connected(buttonDownCallable):
		button.button_down.connect(buttonDownCallable)

	if not button.button_up.is_connected(buttonUpCallable):
		button.button_up.connect(buttonUpCallable)

	if not button.mouse_exited.is_connected(mouseExitedCallable):
		button.mouse_exited.connect(mouseExitedCallable)


# Applies the normal visual state to a main menu button.
func applyMainButtonNormal(button: Button) -> void:
	applyMainButtonStyle(button, mainNormalStyle, TEXT_NORMAL_COLOR)


# Applies the pressed visual state to a main menu button.
func applyMainButtonPressed(button: Button) -> void:
	applyMainButtonStyle(button, mainPressedStyle, TEXT_PRESSED_COLOR)


# Applies the texture style and text color to all button interaction states.
func applyMainButtonStyle(button: Button, style: StyleBoxTexture, textColor: Color) -> void:
	if button == null:
		return

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("focus", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("disabled", style)

	button.add_theme_color_override("font_color", textColor)
	button.add_theme_color_override("font_hover_color", textColor)
	button.add_theme_color_override("font_focus_color", textColor)
	button.add_theme_color_override("font_pressed_color", textColor)


# Handles the button-down visual feedback.
func onMainButtonDown(button: Button) -> void:
	if button == null:
		return

	buttonStateTokens[button] = int(buttonStateTokens.get(button, 0)) + 1

	applyMainButtonPressed(button)
	pushButtonDown(button)


# Handles the button release visual feedback.
func onMainButtonUp(button: Button) -> void:
	if button == null:
		return

	var stateToken := int(buttonStateTokens.get(button, 0)) + 1
	buttonStateTokens[button] = stateToken

	releaseButton(button)

	await get_tree().create_timer(CLICK_FEEDBACK_TIME).timeout

	if int(buttonStateTokens.get(button, 0)) == stateToken and not button.button_pressed:
		applyMainButtonNormal(button)


# Resets the button if the mouse exits while it is not being pressed.
func onMainButtonMouseExited(button: Button) -> void:
	if button == null:
		return

	if button.button_pressed:
		return

	buttonStateTokens[button] = int(buttonStateTokens.get(button, 0)) + 1

	applyMainButtonNormal(button)
	releaseButton(button)


# Animates a button into its pressed position.
func pushButtonDown(button: Button) -> void:
	if button == null:
		return

	killButtonTween(button)

	var originalPosition: Vector2 = buttonOriginalPositions.get(button, button.position)
	var targetPosition := originalPosition + BUTTON_PUSH_OFFSET

	var tween := create_tween()
	buttonTweens[button] = tween
	tween.set_parallel(true)

	tween.tween_property(
		button,
		"scale",
		BUTTON_PRESSED_SCALE,
		BUTTON_PUSH_TIME
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		button,
		"position",
		targetPosition,
		BUTTON_PUSH_TIME
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


# Animates a button back to its original position.
func releaseButton(button: Button) -> void:
	if button == null:
		return

	killButtonTween(button)

	var originalPosition: Vector2 = buttonOriginalPositions.get(button, button.position)

	var tween := create_tween()
	buttonTweens[button] = tween
	tween.set_parallel(true)

	tween.tween_property(
		button,
		"scale",
		Vector2.ONE,
		BUTTON_RELEASE_TIME
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		button,
		"position",
		originalPosition,
		BUTTON_RELEASE_TIME
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Stops the current animation of a button before starting a new one.
func killButtonTween(button: Button) -> void:
	if button == null:
		return

	if not buttonTweens.has(button):
		return

	var tween: Tween = buttonTweens[button]

	if tween != null and tween.is_valid():
		tween.kill()

	buttonTweens.erase(button)