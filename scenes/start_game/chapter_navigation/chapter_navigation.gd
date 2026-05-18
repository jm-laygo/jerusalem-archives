extends Control

signal previousPressed
signal nextPressed
signal selectPressed

const CHAPTER_BACK_NORMAL_TEXTURE: Texture2D = preload("res://assets/interface/buttons/btn_start_game_back.png")
const CHAPTER_BACK_PRESSED_TEXTURE: Texture2D = preload("res://assets/interface/buttons/btn_start_game_back_pressed.png")

const CHAPTER_NEXT_NORMAL_TEXTURE: Texture2D = preload("res://assets/interface/buttons/btn_start_game_next.png")
const CHAPTER_NEXT_PRESSED_TEXTURE: Texture2D = preload("res://assets/interface/buttons/btn_start_game_next_pressed.png")

const SELECT_NORMAL_TEXTURE: Texture2D = preload("res://assets/interface/buttons/btn_start_game_select.png")
const SELECT_PRESSED_TEXTURE: Texture2D = preload("res://assets/interface/buttons/btn_start_game_select_pressed.png")

const BUTTON_NORMAL_MODULATE := Color(1, 1, 1, 1)
const BUTTON_PRESSED_MODULATE := Color(0.92, 0.92, 0.92, 1)
const BUTTON_HIDDEN_MODULATE := Color(1, 1, 1, 0)

const SELECT_PRESSED_SCALE_MULTIPLIER := Vector2(0.96, 0.92)
const ARROW_PRESSED_SCALE_MULTIPLIER := Vector2(0.94, 0.94)

const BUTTON_PRESS_TIME := 0.06
const BUTTON_RELEASE_TIME := 0.10

const INTRO_TIME := 0.30
const OUTRO_TIME := 0.30
const INTRO_FADE_TIME := 0.20
const OUTRO_FADE_TIME := 0.18

const SELECT_INTRO_TIME := 0.30
const SELECT_INTRO_FADE_TIME := 0.16
const SELECT_BELOW_SCREEN_EXTRA := 160.0

const DESIGN_WIDTH := 1080.0
const DEFAULT_DESIGN_HEIGHT := 1720.0
const MINIMUM_DESIGN_HEIGHT := 900.0

const SELECT_BOTTOM_OFFSET := 180.0
const ARROW_POSITION_RATIO_Y := 0.43

const BACK_BUTTON_POSITION_X := -10.0
const NEXT_BUTTON_POSITION_X := 889.0
const ARROW_BUTTON_SIZE := Vector2(201.0, 211.0)

const SELECT_BUTTON_POSITION_X := 240.0
const SELECT_BUTTON_SIZE := Vector2(600.0, 265.0)

const OFFSCREEN_SIDE_PADDING := 60.0
const INTRO_OFFSCREEN_SIDE_PADDING := 40.0

const TWEEN_BACK := "back"
const TWEEN_NEXT := "next"
const TWEEN_SELECT := "select"

@onready var chapterBackButton: TextureButton = $SelectChapterBackButton
@onready var chapterNextButton: TextureButton = $SelectChapterNextButton
@onready var selectButton: TextureButton = $SelectButton

var isLocked := false
var activeButton: TextureButton = null

var currentDesignHeight := DEFAULT_DESIGN_HEIGHT

var backButtonOriginalPosition := Vector2.ZERO
var nextButtonOriginalPosition := Vector2.ZERO
var selectTargetPosition := Vector2.ZERO
var selectStartPosition := Vector2.ZERO

var backButtonOriginalScale := Vector2.ONE
var nextButtonOriginalScale := Vector2.ONE
var selectOriginalScale := Vector2.ONE

var introTween: Tween
var outroTween: Tween
var backButtonTween: Tween
var nextButtonTween: Tween
var selectButtonTween: Tween


# Sets up navigation buttons, layout, and cached animation values.
func _ready() -> void:
	setupButtons()
	forceDesignLayout(currentDesignHeight)

	await get_tree().process_frame

	cacheOriginalValues()
	forceSelectVisible()


# Locks or unlocks all navigation actions.
func setLocked(value: bool) -> void:
	isLocked = value


# Applies setup to every navigation button.
func setupButtons() -> void:
	setupNavigationButton(
		chapterBackButton,
		CHAPTER_BACK_NORMAL_TEXTURE,
		CHAPTER_BACK_PRESSED_TEXTURE,
		Callable(self, "onChapterBackButtonDown"),
		Callable(self, "onChapterBackButtonUp"),
		Callable(self, "onChapterBackButtonExited")
	)

	setupNavigationButton(
		chapterNextButton,
		CHAPTER_NEXT_NORMAL_TEXTURE,
		CHAPTER_NEXT_PRESSED_TEXTURE,
		Callable(self, "onChapterNextButtonDown"),
		Callable(self, "onChapterNextButtonUp"),
		Callable(self, "onChapterNextButtonExited")
	)

	setupNavigationButton(
		selectButton,
		SELECT_NORMAL_TEXTURE,
		SELECT_PRESSED_TEXTURE,
		Callable(self, "onSelectButtonDown"),
		Callable(self, "onSelectButtonUp"),
		Callable(self, "onSelectButtonExited")
	)

	ignoreChildrenMouse(chapterBackButton)
	ignoreChildrenMouse(chapterNextButton)
	ignoreChildrenMouse(selectButton)


# Prepares one navigation button with textures and interaction callbacks.
func setupNavigationButton(
	button: TextureButton,
	normalTexture: Texture2D,
	pressedTexture: Texture2D,
	downCallable: Callable,
	upCallable: Callable,
	exitCallable: Callable
) -> void:
	if button == null:
		return

	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.modulate = BUTTON_NORMAL_MODULATE

	button.texture_normal = normalTexture
	button.texture_hover = normalTexture
	button.texture_pressed = pressedTexture
	button.texture_focused = normalTexture
	button.texture_disabled = normalTexture

	if not button.button_down.is_connected(downCallable):
		button.button_down.connect(downCallable)

	if not button.button_up.is_connected(upCallable):
		button.button_up.connect(upCallable)

	if not button.mouse_exited.is_connected(exitCallable):
		button.mouse_exited.connect(exitCallable)


# Prevents child labels/images from blocking button clicks.
func ignoreChildrenMouse(button: TextureButton) -> void:
	if button == null:
		return

	for child in button.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE


# Forces the navigation component to match the slider design size.
func forceDesignLayout(designHeight: float = DEFAULT_DESIGN_HEIGHT) -> void:
	currentDesignHeight = max(MINIMUM_DESIGN_HEIGHT, designHeight)

	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	position = Vector2.ZERO
	size = Vector2(DESIGN_WIDTH, currentDesignHeight)
	scale = Vector2.ONE

	forceBackButtonLayout()
	forceNextButtonLayout()
	forceSelectButtonLayout()
	cacheOriginalValues()


# Positions and sizes the previous chapter button.
func forceBackButtonLayout() -> void:
	if chapterBackButton == null:
		return

	chapterBackButton.anchor_left = 0.0
	chapterBackButton.anchor_top = 0.0
	chapterBackButton.anchor_right = 0.0
	chapterBackButton.anchor_bottom = 0.0
	chapterBackButton.position = Vector2(BACK_BUTTON_POSITION_X, currentDesignHeight * ARROW_POSITION_RATIO_Y)
	chapterBackButton.size = ARROW_BUTTON_SIZE
	chapterBackButton.scale = Vector2.ONE
	chapterBackButton.ignore_texture_size = true
	chapterBackButton.stretch_mode = TextureButton.STRETCH_SCALE


# Positions and sizes the next chapter button.
func forceNextButtonLayout() -> void:
	if chapterNextButton == null:
		return

	chapterNextButton.anchor_left = 0.0
	chapterNextButton.anchor_top = 0.0
	chapterNextButton.anchor_right = 0.0
	chapterNextButton.anchor_bottom = 0.0
	chapterNextButton.position = Vector2(NEXT_BUTTON_POSITION_X, currentDesignHeight * ARROW_POSITION_RATIO_Y)
	chapterNextButton.size = ARROW_BUTTON_SIZE
	chapterNextButton.scale = Vector2.ONE
	chapterNextButton.ignore_texture_size = true
	chapterNextButton.stretch_mode = TextureButton.STRETCH_SCALE


# Positions and sizes the select button.
func forceSelectButtonLayout() -> void:
	if selectButton == null:
		return

	selectButton.anchor_left = 0.0
	selectButton.anchor_top = 0.0
	selectButton.anchor_right = 0.0
	selectButton.anchor_bottom = 0.0
	selectButton.position = Vector2(SELECT_BUTTON_POSITION_X, currentDesignHeight - SELECT_BOTTOM_OFFSET)
	selectButton.size = SELECT_BUTTON_SIZE
	selectButton.scale = Vector2.ONE
	selectButton.ignore_texture_size = true
	selectButton.stretch_mode = TextureButton.STRETCH_SCALE
	selectButton.visible = true
	selectButton.modulate = BUTTON_NORMAL_MODULATE
	selectButton.mouse_filter = Control.MOUSE_FILTER_STOP


# Caches original positions and scales used by animations.
func cacheOriginalValues() -> void:
	if chapterBackButton != null:
		backButtonOriginalPosition = chapterBackButton.position
		backButtonOriginalScale = chapterBackButton.scale
		chapterBackButton.pivot_offset = chapterBackButton.size / 2.0

	if chapterNextButton != null:
		nextButtonOriginalPosition = chapterNextButton.position
		nextButtonOriginalScale = chapterNextButton.scale
		chapterNextButton.pivot_offset = chapterNextButton.size / 2.0

	if selectButton != null:
		selectOriginalScale = selectButton.scale
		selectButton.pivot_offset = selectButton.size / 2.0

		selectTargetPosition = Vector2(
			(DESIGN_WIDTH - selectButton.size.x) / 2.0,
			currentDesignHeight - SELECT_BOTTOM_OFFSET
		)

		selectStartPosition = Vector2(
			selectTargetPosition.x,
			currentDesignHeight + selectButton.size.y + SELECT_BELOW_SCREEN_EXTRA
		)


# Restores the select button after layout or animation changes.
func forceSelectVisible() -> void:
	if selectButton == null:
		return

	selectButton.visible = true
	selectButton.modulate = BUTTON_NORMAL_MODULATE
	selectButton.mouse_filter = Control.MOUSE_FILTER_STOP
	selectButton.position = selectTargetPosition
	selectButton.scale = Vector2.ONE


# Places navigation buttons in their hidden intro positions.
func prepareIntroState() -> void:
	if chapterBackButton != null:
		chapterBackButton.position = Vector2(
			-chapterBackButton.size.x - INTRO_OFFSCREEN_SIDE_PADDING,
			backButtonOriginalPosition.y
		)
		chapterBackButton.modulate = BUTTON_HIDDEN_MODULATE

	if chapterNextButton != null:
		chapterNextButton.position = Vector2(
			size.x + INTRO_OFFSCREEN_SIDE_PADDING,
			nextButtonOriginalPosition.y
		)
		chapterNextButton.modulate = BUTTON_HIDDEN_MODULATE

	if selectButton != null:
		selectButton.position = selectStartPosition
		selectButton.modulate = BUTTON_HIDDEN_MODULATE
		selectButton.visible = true


# Plays the navigation intro animation.
func playIntroAnimation() -> void:
	killTween(introTween)

	introTween = get_tree().create_tween()
	introTween.set_parallel(true)

	if chapterBackButton != null:
		introTween.tween_property(
			chapterBackButton,
			"position",
			backButtonOriginalPosition,
			INTRO_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		introTween.tween_property(
			chapterBackButton,
			"modulate",
			BUTTON_NORMAL_MODULATE,
			INTRO_FADE_TIME
		)

	if chapterNextButton != null:
		introTween.tween_property(
			chapterNextButton,
			"position",
			nextButtonOriginalPosition,
			INTRO_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		introTween.tween_property(
			chapterNextButton,
			"modulate",
			BUTTON_NORMAL_MODULATE,
			INTRO_FADE_TIME
		)

	if selectButton != null:
		introTween.tween_property(
			selectButton,
			"position",
			selectTargetPosition,
			SELECT_INTRO_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		introTween.tween_property(
			selectButton,
			"modulate",
			BUTTON_NORMAL_MODULATE,
			INTRO_FADE_TIME
		)


# Restores the select button animation before the difficulty popup opens.
func playSelectIntroAnimation() -> void:
	if selectButton == null:
		return

	killButtonTween(TWEEN_SELECT)

	selectButtonTween = get_tree().create_tween()
	selectButtonTween.set_parallel(true)

	selectButtonTween.tween_property(
		selectButton,
		"position",
		selectTargetPosition,
		SELECT_INTRO_TIME
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	selectButtonTween.tween_property(
		selectButton,
		"modulate",
		BUTTON_NORMAL_MODULATE,
		SELECT_INTRO_FADE_TIME
	)


# Plays and waits for the navigation outro animation.
func playOutroAnimation() -> void:
	createOutroTween()

	if outroTween != null:
		await outroTween.finished


# Creates the navigation outro tween.
func createOutroTween() -> Tween:
	killTween(outroTween)
	killButtonTween(TWEEN_BACK)
	killButtonTween(TWEEN_NEXT)
	killButtonTween(TWEEN_SELECT)

	outroTween = get_tree().create_tween()
	outroTween.set_parallel(true)

	if chapterBackButton != null:
		chapterBackButton.modulate = BUTTON_NORMAL_MODULATE
		chapterBackButton.scale = backButtonOriginalScale

		outroTween.tween_property(
			chapterBackButton,
			"position",
			getBackButtonOutroPosition(),
			OUTRO_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		outroTween.tween_property(
			chapterBackButton,
			"modulate",
			BUTTON_HIDDEN_MODULATE,
			OUTRO_FADE_TIME
		)

	if chapterNextButton != null:
		chapterNextButton.modulate = BUTTON_NORMAL_MODULATE
		chapterNextButton.scale = nextButtonOriginalScale

		outroTween.tween_property(
			chapterNextButton,
			"position",
			getNextButtonOutroPosition(),
			OUTRO_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		outroTween.tween_property(
			chapterNextButton,
			"modulate",
			BUTTON_HIDDEN_MODULATE,
			OUTRO_FADE_TIME
		)

	if selectButton != null:
		selectButton.modulate = BUTTON_NORMAL_MODULATE
		selectButton.scale = selectOriginalScale

		outroTween.tween_property(
			selectButton,
			"position",
			getSelectButtonOutroPosition(),
			OUTRO_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		outroTween.tween_property(
			selectButton,
			"modulate",
			BUTTON_HIDDEN_MODULATE,
			OUTRO_FADE_TIME
		)

	return outroTween


# Returns the previous button outro position.
func getBackButtonOutroPosition() -> Vector2:
	if chapterBackButton == null:
		return Vector2.ZERO

	return Vector2(
		-chapterBackButton.size.x - OFFSCREEN_SIDE_PADDING,
		backButtonOriginalPosition.y
	)


# Returns the next button outro position.
func getNextButtonOutroPosition() -> Vector2:
	if chapterNextButton == null:
		return Vector2.ZERO

	return Vector2(
		size.x + chapterNextButton.size.x + OFFSCREEN_SIDE_PADDING,
		nextButtonOriginalPosition.y
	)


# Returns the select button outro position.
func getSelectButtonOutroPosition() -> Vector2:
	if selectButton == null:
		return Vector2.ZERO

	return Vector2(
		selectTargetPosition.x,
		currentDesignHeight + selectButton.size.y + SELECT_BELOW_SCREEN_EXTRA
	)


# Handles previous button press start.
func onChapterBackButtonDown() -> void:
	if isLocked or chapterBackButton == null:
		return

	activeButton = chapterBackButton
	applyButtonPressedTexture(chapterBackButton, CHAPTER_BACK_PRESSED_TEXTURE)

	var pressedScale := backButtonOriginalScale * ARROW_PRESSED_SCALE_MULTIPLIER
	pressButtonAnimation(chapterBackButton, TWEEN_BACK, pressedScale)


# Handles previous button release.
func onChapterBackButtonUp() -> void:
	if chapterBackButton == null:
		return

	var shouldClick := activeButton == chapterBackButton and isMouseInsideButton(chapterBackButton)

	activeButton = null
	resetChapterBackButton()

	if shouldClick and not isLocked:
		previousPressed.emit()


# Cancels previous button press when the mouse exits.
func onChapterBackButtonExited() -> void:
	if activeButton != chapterBackButton:
		return

	activeButton = null
	resetChapterBackButton()


# Handles next button press start.
func onChapterNextButtonDown() -> void:
	if isLocked or chapterNextButton == null:
		return

	activeButton = chapterNextButton
	applyButtonPressedTexture(chapterNextButton, CHAPTER_NEXT_PRESSED_TEXTURE)

	var pressedScale := nextButtonOriginalScale * ARROW_PRESSED_SCALE_MULTIPLIER
	pressButtonAnimation(chapterNextButton, TWEEN_NEXT, pressedScale)


# Handles next button release.
func onChapterNextButtonUp() -> void:
	if chapterNextButton == null:
		return

	var shouldClick := activeButton == chapterNextButton and isMouseInsideButton(chapterNextButton)

	activeButton = null
	resetChapterNextButton()

	if shouldClick and not isLocked:
		nextPressed.emit()


# Cancels next button press when the mouse exits.
func onChapterNextButtonExited() -> void:
	if activeButton != chapterNextButton:
		return

	activeButton = null
	resetChapterNextButton()


# Handles select button press start.
func onSelectButtonDown() -> void:
	if isLocked or selectButton == null:
		return

	activeButton = selectButton
	applyButtonPressedTexture(selectButton, SELECT_PRESSED_TEXTURE)

	var pressedScale := selectOriginalScale * SELECT_PRESSED_SCALE_MULTIPLIER
	pressButtonAnimation(selectButton, TWEEN_SELECT, pressedScale)


# Handles select button release.
func onSelectButtonUp() -> void:
	if selectButton == null:
		return

	var shouldClick := activeButton == selectButton and isMouseInsideButton(selectButton)

	activeButton = null
	resetSelectButton()

	if shouldClick and not isLocked:
		selectPressed.emit()


# Cancels select button press when the mouse exits.
func onSelectButtonExited() -> void:
	if activeButton != selectButton:
		return

	activeButton = null
	resetSelectButton()


# Applies a pressed texture to a button.
func applyButtonPressedTexture(button: TextureButton, pressedTexture: Texture2D) -> void:
	if button == null:
		return

	button.texture_normal = pressedTexture
	button.texture_hover = pressedTexture


# Resets the previous button visual state.
func resetChapterBackButton() -> void:
	if chapterBackButton == null:
		return

	chapterBackButton.texture_normal = CHAPTER_BACK_NORMAL_TEXTURE
	chapterBackButton.texture_hover = CHAPTER_BACK_NORMAL_TEXTURE
	resetButtonAnimation(chapterBackButton, TWEEN_BACK, backButtonOriginalScale)


# Resets the next button visual state.
func resetChapterNextButton() -> void:
	if chapterNextButton == null:
		return

	chapterNextButton.texture_normal = CHAPTER_NEXT_NORMAL_TEXTURE
	chapterNextButton.texture_hover = CHAPTER_NEXT_NORMAL_TEXTURE
	resetButtonAnimation(chapterNextButton, TWEEN_NEXT, nextButtonOriginalScale)


# Resets the select button visual state.
func resetSelectButton() -> void:
	if selectButton == null:
		return

	selectButton.texture_normal = SELECT_NORMAL_TEXTURE
	selectButton.texture_hover = SELECT_NORMAL_TEXTURE
	resetButtonAnimation(selectButton, TWEEN_SELECT, selectOriginalScale)


# Checks if the mouse is still inside the button.
func isMouseInsideButton(button: TextureButton) -> bool:
	if button == null:
		return false

	var mousePosition := get_global_mouse_position()
	var buttonRect := Rect2(button.global_position, button.size)
	return buttonRect.has_point(mousePosition)


# Animates a button into its pressed state.
func pressButtonAnimation(button: TextureButton, tweenName: String, pressedScale: Vector2) -> void:
	if button == null:
		return

	killButtonTween(tweenName)

	var tween := get_tree().create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		button,
		"scale",
		pressedScale,
		BUTTON_PRESS_TIME
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		button,
		"modulate",
		BUTTON_PRESSED_MODULATE,
		BUTTON_PRESS_TIME
	)

	setButtonTween(tweenName, tween)


# Animates a button back to its normal state.
func resetButtonAnimation(button: TextureButton, tweenName: String, originalScale: Vector2) -> void:
	if button == null:
		return

	killButtonTween(tweenName)

	var tween := get_tree().create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		button,
		"scale",
		originalScale,
		BUTTON_RELEASE_TIME
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		button,
		"modulate",
		BUTTON_NORMAL_MODULATE,
		BUTTON_RELEASE_TIME
	)

	setButtonTween(tweenName, tween)


# Stops a specific button tween.
func killButtonTween(tweenName: String) -> void:
	match tweenName:
		TWEEN_BACK:
			killTween(backButtonTween)
		TWEEN_NEXT:
			killTween(nextButtonTween)
		TWEEN_SELECT:
			killTween(selectButtonTween)


# Stores a specific button tween.
func setButtonTween(tweenName: String, tween: Tween) -> void:
	match tweenName:
		TWEEN_BACK:
			backButtonTween = tween
		TWEEN_NEXT:
			nextButtonTween = tween
		TWEEN_SELECT:
			selectButtonTween = tween


# Stops an active tween safely.
func killTween(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()