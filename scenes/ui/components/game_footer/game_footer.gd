extends TextureRect

signal backPressed
signal settingsPressed
signal achievementsPressed

const DESIGN_WIDTH := 1080.0
const FOOTER_HEIGHT := 200.0
const FOOTER_HIDDEN_OFFSET := 170.0

const BUTTON_NORMAL_MODULATE := Color(1, 1, 1, 1)
const BUTTON_PRESSED_MODULATE := Color(0.88, 0.88, 0.88, 1)

const CHILD_PUSH_OFFSET := Vector2(0, 3)
const BUTTON_PUSH_TIME := 0.045
const BUTTON_RELEASE_TIME := 0.10

const INTRO_TIME := 0.30
const OUTRO_TIME := 0.30

@onready var backButton: TextureButton = $FooterButtons/BackButton
@onready var settingsButton: TextureButton = $FooterButtons/SettingsButton
@onready var achievementsButton: TextureButton = $FooterButtons/AchievementsButton

var footerOriginalPosition := Vector2.ZERO

var introTween: Tween
var outroTween: Tween

var activeButton: TextureButton = null
var buttonTweens := {}
var childOriginalPositions := {}


# Prepares footer layout, buttons, and animation values.
func _ready() -> void:
	await get_tree().process_frame

	forceBottomLayout()
	setupButtons()
	cacheOriginalValues()


# Forces the footer to stay pinned to the bottom of the screen.
func forceBottomLayout() -> void:
	anchor_left = 0.5
	anchor_top = 1.0
	anchor_right = 0.5
	anchor_bottom = 1.0

	offset_left = -(DESIGN_WIDTH / 2.0)
	offset_top = -FOOTER_HEIGHT
	offset_right = DESIGN_WIDTH / 2.0
	offset_bottom = 0.0

	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN


# Applies shared setup to all footer buttons.
func setupButtons() -> void:
	setupFooterButton(backButton)
	setupFooterButton(settingsButton)
	setupFooterButton(achievementsButton)


# Prepares one footer button for interaction feedback and signal handling.
func setupFooterButton(button: TextureButton) -> void:
	if button == null:
		return

	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.disabled = false
	button.modulate = BUTTON_NORMAL_MODULATE

	button.texture_hover = button.texture_normal
	button.texture_focused = button.texture_normal
	button.texture_disabled = button.texture_normal

	cacheChildPositions(button)
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


# Stores the original child positions for press/release animation.
func cacheChildPositions(button: TextureButton) -> void:
	if button == null:
		return

	childOriginalPositions[button] = {}

	for child in button.get_children():
		if child is Control:
			childOriginalPositions[button][child] = child.position


# Prevents footer button children from blocking clicks.
func ignoreChildrenMouse(button: TextureButton) -> void:
	if button == null:
		return

	for child in button.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE


# Handles footer button press start.
func onButtonDown(button: TextureButton) -> void:
	if button == null:
		return

	activeButton = button
	pushButtonDown(button)


# Handles footer button release and emits the correct footer signal.
func onButtonUp(button: TextureButton) -> void:
	if button == null:
		return

	var shouldClick := activeButton == button and isMouseInsideButton(button)

	activeButton = null
	releaseButton(button)

	if not shouldClick:
		return

	if button == backButton:
		backPressed.emit()
	elif button == settingsButton:
		settingsPressed.emit()
	elif button == achievementsButton:
		achievementsPressed.emit()


# Cancels the active press state when the mouse leaves a button.
func onButtonMouseExited(button: TextureButton) -> void:
	if button == null:
		return

	if activeButton != button:
		return

	activeButton = null
	releaseButton(button)


# Animates a footer button into its pressed state.
func pushButtonDown(button: TextureButton) -> void:
	if button == null:
		return

	killButtonTween(button)

	var tween := create_tween()
	buttonTweens[button] = tween
	tween.set_parallel(true)

	tween.tween_property(
		button,
		"modulate",
		BUTTON_PRESSED_MODULATE,
		BUTTON_PUSH_TIME
	)

	for child in button.get_children():
		if child is Control:
			var originalPosition: Vector2 = childOriginalPositions[button].get(child, child.position)

			tween.tween_property(
				child,
				"position",
				originalPosition + CHILD_PUSH_OFFSET,
				BUTTON_PUSH_TIME
			).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


# Animates a footer button back to its normal state.
func releaseButton(button: TextureButton) -> void:
	if button == null:
		return

	killButtonTween(button)

	var tween := create_tween()
	buttonTweens[button] = tween
	tween.set_parallel(true)

	tween.tween_property(
		button,
		"modulate",
		BUTTON_NORMAL_MODULATE,
		BUTTON_RELEASE_TIME
	)

	for child in button.get_children():
		if child is Control:
			var originalPosition: Vector2 = childOriginalPositions[button].get(child, child.position)

			tween.tween_property(
				child,
				"position",
				originalPosition,
				BUTTON_RELEASE_TIME
			).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# Stops the active tween for one footer button.
func killButtonTween(button: TextureButton) -> void:
	if button == null:
		return

	if not buttonTweens.has(button):
		return

	var tween: Tween = buttonTweens[button]

	if tween != null and tween.is_valid():
		tween.kill()

	buttonTweens.erase(button)


# Checks if the mouse is still inside a footer button.
func isMouseInsideButton(button: TextureButton) -> bool:
	if button == null:
		return false

	var mousePosition := get_global_mouse_position()
	var buttonRect := Rect2(button.global_position, button.size)

	return buttonRect.has_point(mousePosition)


# Saves the footer's normal visible position.
func cacheOriginalValues() -> void:
	forceBottomLayout()
	footerOriginalPosition = position


# Places the footer below the screen before the intro animation.
func prepareIntroState() -> void:
	position = footerOriginalPosition + Vector2(0, FOOTER_HIDDEN_OFFSET)


# Slides the footer into view.
func playIntroAnimation() -> void:
	killTween(introTween)

	introTween = create_tween()

	introTween.tween_property(
		self,
		"position",
		footerOriginalPosition,
		INTRO_TIME
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await introTween.finished


# Slides the footer out of view.
func playOutroAnimation() -> void:
	killTween(outroTween)

	var footerOutPosition := footerOriginalPosition + Vector2(0, FOOTER_HIDDEN_OFFSET)

	outroTween = create_tween()

	outroTween.tween_property(
		self,
		"position",
		footerOutPosition,
		OUTRO_TIME
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await outroTween.finished


# Stops a tween safely.
func killTween(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
