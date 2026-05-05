extends Control

signal startGamePressed
signal profilePressed
signal settingsPressed
signal exitGamePressed

const MAIN_NORMAL_TEXTURE: Texture2D = preload("res://assets/interface/buttons/generic_button.png")
const MAIN_CLICKED_TEXTURE: Texture2D = preload("res://assets/interface/buttons/generic_button_clicked.png")

const CLICK_FEEDBACK_TIME := 0.045

const BUTTON_PRESSED_SCALE := Vector2(0.97, 0.94)
const BUTTON_PUSH_OFFSET := Vector2(0, 3)
const BUTTON_PUSH_TIME := 0.045
const BUTTON_RELEASE_TIME := 0.10

const TEXT_NORMAL := Color(1,1,1, 1)
const TEXT_CLICKED := Color(0.90, 0.62, 0.39, 1)

@onready var startGameButton: Button = $StartGameButton
@onready var profileButton: Button = $ProfileButton
@onready var settingsButton: Button = $SettingsButton
@onready var exitGameButton: Button = $ExitGameButton

var mainStyleNormal: StyleBoxTexture
var mainStyleClicked: StyleBoxTexture

var mainButtonTokens := {}
var buttonOriginalPositions := {}
var buttonTweens := {}


func _ready() -> void:
	_createMainButtonStyles()

	await get_tree().process_frame

	_setupButtons()


func _createMainButtonStyles() -> void:
	mainStyleNormal = _makeMainStyle(MAIN_NORMAL_TEXTURE)
	mainStyleClicked = _makeMainStyle(MAIN_CLICKED_TEXTURE)


func _makeMainStyle(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 48.0
	style.texture_margin_top = 18.0
	style.texture_margin_right = 48.0
	style.texture_margin_bottom = 18.0
	return style


func _setupButtons() -> void:
	_setupMainButton(startGameButton)
	_setupMainButton(profileButton)
	_setupMainButton(settingsButton)
	_setupMainButton(exitGameButton)

	startGameButton.pressed.connect(startGamePressed.emit)
	profileButton.pressed.connect(profilePressed.emit)
	settingsButton.pressed.connect(settingsPressed.emit)
	exitGameButton.pressed.connect(exitGamePressed.emit)


func _setupMainButton(button: Button) -> void:
	if button == null:
		return

	button.focus_mode = Control.FOCUS_NONE
	button.scale = Vector2.ONE
	button.pivot_offset = button.size * 0.5

	mainButtonTokens[button] = 0
	buttonOriginalPositions[button] = button.position

	_applyMainButtonNormal(button)

	if not button.button_down.is_connected(_onMainButtonDown.bind(button)):
		button.button_down.connect(_onMainButtonDown.bind(button))

	if not button.button_up.is_connected(_onMainButtonUp.bind(button)):
		button.button_up.connect(_onMainButtonUp.bind(button))

	if not button.mouse_exited.is_connected(_onMainButtonMouseExited.bind(button)):
		button.mouse_exited.connect(_onMainButtonMouseExited.bind(button))


func _applyMainButtonNormal(button: Button) -> void:
	_applyMainButtonStyle(button, mainStyleNormal, TEXT_NORMAL)


func _applyMainButtonClicked(button: Button) -> void:
	_applyMainButtonStyle(button, mainStyleClicked, TEXT_CLICKED)


func _applyMainButtonStyle(button: Button, style: StyleBoxTexture, textColor: Color) -> void:
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


func _onMainButtonDown(button: Button) -> void:
	if button == null:
		return

	mainButtonTokens[button] = int(mainButtonTokens.get(button, 0)) + 1

	_applyMainButtonClicked(button)
	_pushButtonDown(button)


func _onMainButtonUp(button: Button) -> void:
	if button == null:
		return

	var token := int(mainButtonTokens.get(button, 0)) + 1
	mainButtonTokens[button] = token

	_releaseButton(button)

	await get_tree().create_timer(CLICK_FEEDBACK_TIME).timeout

	if int(mainButtonTokens.get(button, 0)) == token and not button.button_pressed:
		_applyMainButtonNormal(button)


func _onMainButtonMouseExited(button: Button) -> void:
	if button == null:
		return

	if button.button_pressed:
		return

	mainButtonTokens[button] = int(mainButtonTokens.get(button, 0)) + 1

	_applyMainButtonNormal(button)
	_releaseButton(button)


func _pushButtonDown(button: Button) -> void:
	if button == null:
		return

	_killButtonTween(button)

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


func _releaseButton(button: Button) -> void:
	if button == null:
		return

	_killButtonTween(button)

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


func _killButtonTween(button: Button) -> void:
	if button == null:
		return

	if not buttonTweens.has(button):
		return

	var tween: Tween = buttonTweens[button]

	if tween != null and tween.is_valid():
		tween.kill()