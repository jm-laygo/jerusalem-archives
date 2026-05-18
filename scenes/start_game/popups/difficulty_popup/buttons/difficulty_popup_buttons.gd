extends Control

signal difficultySelected(difficultyName: String)

const EASY_DIFFICULTY := "Easy"
const NORMAL_DIFFICULTY := "Normal"
const HARD_DIFFICULTY := "Hard"

const BUTTON_NORMAL_MODULATE := Color(1, 1, 1, 1)
const BUTTON_PRESSED_SCALE := Vector2(0.97, 0.94)

const BUTTON_PUSH_TIME := 0.045
const BUTTON_RELEASE_TIME := 0.10

@onready var buttonsContainer: VBoxContainer = $DifficultyButtons
@onready var easyButton: TextureButton = $DifficultyButtons/EasyButton
@onready var normalButton: TextureButton = $DifficultyButtons/NormalButton
@onready var hardButton: TextureButton = $DifficultyButtons/HardButton

var buttonOriginalScales := {}
var buttonTweens := {}
var activeButton: TextureButton = null


# Prepares all difficulty buttons after their layout sizes are ready.
func _ready() -> void:
	await get_tree().process_frame

	setupButtons()


# Applies shared setup to all difficulty buttons.
func setupButtons() -> void:
	setupDifficultyButton(easyButton)
	setupDifficultyButton(normalButton)
	setupDifficultyButton(hardButton)


# Prepares one difficulty button for press feedback and click handling.
func setupDifficultyButton(button: TextureButton) -> void:
	if button == null:
		return

	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.modulate = BUTTON_NORMAL_MODULATE

	buttonOriginalScales[button] = button.scale
	button.pivot_offset = button.size * 0.5

	ignoreChildrenMouse(button)

	var buttonDownCallable := onButtonDown.bind(button)
	var buttonUpCallable := onButtonUp.bind(button)
	var mouseExitedCallable := onButtonMouseExited.bind(button)

	if not button.button_down.is_connected(buttonDownCallable):
		button.button_down.connect(buttonDownCallable)

	if not button.button_up.is_connected(buttonUpCallable):
		button.button_up.connect(buttonUpCallable)

	if not button.mouse_exited.is_connected(mouseExitedCallable):
		button.mouse_exited.connect(mouseExitedCallable)


# Prevents labels and icons from blocking button clicks.
func ignoreChildrenMouse(button: TextureButton) -> void:
	if button == null:
		return

	for child in button.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE


# Handles button press start.
func onButtonDown(button: TextureButton) -> void:
	if button == null:
		return

	activeButton = button
	pushButtonDown(button)


# Handles button release and emits the selected difficulty.
func onButtonUp(button: TextureButton) -> void:
	if button == null:
		return

	var shouldClick := activeButton == button and isMouseInsideButton(button)

	activeButton = null
	releaseButton(button)

	if not shouldClick:
		return

	var difficultyName := getDifficultyName(button)

	if difficultyName.is_empty():
		return

	difficultySelected.emit(difficultyName)


# Cancels button press when the mouse exits the active button.
func onButtonMouseExited(button: TextureButton) -> void:
	if button == null:
		return

	if activeButton != button:
		return

	activeButton = null
	releaseButton(button)


# Returns the difficulty name linked to a button.
func getDifficultyName(button: TextureButton) -> String:
	if button == easyButton:
		return EASY_DIFFICULTY

	if button == normalButton:
		return NORMAL_DIFFICULTY

	if button == hardButton:
		return HARD_DIFFICULTY

	return ""


# Animates a button into its pressed state.
func pushButtonDown(button: TextureButton) -> void:
	if button == null:
		return

	killButtonTween(button)

	var originalScale: Vector2 = buttonOriginalScales.get(button, Vector2.ONE)
	var targetScale := originalScale * BUTTON_PRESSED_SCALE

	var tween := create_tween()
	buttonTweens[button] = tween

	tween.tween_property(
		button,
		"scale",
		targetScale,
		BUTTON_PUSH_TIME
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


# Animates a button back to its normal state.
func releaseButton(button: TextureButton) -> void:
	if button == null:
		return

	killButtonTween(button)

	var originalScale: Vector2 = buttonOriginalScales.get(button, Vector2.ONE)

	var tween := create_tween()
	buttonTweens[button] = tween

	tween.tween_property(
		button,
		"scale",
		originalScale,
		BUTTON_RELEASE_TIME
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Stops the current tween for one button.
func killButtonTween(button: TextureButton) -> void:
	if button == null:
		return

	if not buttonTweens.has(button):
		return

	var tween: Tween = buttonTweens[button]

	if tween != null and tween.is_valid():
		tween.kill()

	buttonTweens.erase(button)


# Checks if the mouse is still inside the button.
func isMouseInsideButton(button: TextureButton) -> bool:
	if button == null:
		return false

	var mousePosition := get_global_mouse_position()
	var buttonRect := Rect2(button.global_position, button.size)
	return buttonRect.has_point(mousePosition)