extends RefCounted

const FOOTER_BUTTON_HIGHLIGHT_COLOR := Color(0.88, 0.88, 0.88, 1.0)
const FOOTER_BUTTON_TEXT_COLOR := Color(0.819608, 0.572549, 0.376471, 1.0)
const FOOTER_BUTTON_IDLE_COLOR := Color(1, 1, 1, 1)

var gameplay: Control


# Stores the gameplay screen reference used by this footer system.
func _init(gameplayOwner: Control) -> void:
	gameplay = gameplayOwner


# Connects Hint, Check, and Info footer buttons.
func connectButtons() -> void:
	setupFooterButton(
		gameplay.hintButton,
		gameplay.hintIcon,
		gameplay.hintLabelMargin,
		gameplay.hintLabel,
		gameplay.hintClickSound,
		Callable(gameplay, "onHintPressed")
	)

	setupFooterButton(
		gameplay.checkButton,
		gameplay.checkIcon,
		gameplay.checkLabelMargin,
		gameplay.checkLabel,
		null,
		Callable(gameplay, "onCheckPressed")
	)

	setupFooterButton(
		gameplay.infoButton,
		gameplay.infoIcon,
		gameplay.infoLabelMargin,
		gameplay.infoLabel,
		gameplay.infoClickSound,
		Callable(gameplay, "onInfoPressed")
	)


# Prepares one footer button for visual feedback and click handling.
func setupFooterButton(
	button: TextureButton,
	icon: TextureRect,
	labelMargin: MarginContainer,
	label: Label,
	soundPlayer: AudioStreamPlayer,
	pressedCallback: Callable
) -> void:
	if button == null:
		return

	if icon == null or labelMargin == null or label == null:
		return

	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.scale = Vector2.ONE
	button.modulate = FOOTER_BUTTON_IDLE_COLOR

	var buttonDownCallable := onFooterButtonDown.bind(button, icon, labelMargin, label)
	var buttonUpCallable := onFooterButtonUp.bind(button, icon, labelMargin, label)
	var mouseExitedCallable := onFooterButtonMouseExited.bind(button, icon, labelMargin, label)
	var pressedCallable := onFooterButtonPressed.bind(soundPlayer, pressedCallback)

	if not button.button_down.is_connected(buttonDownCallable):
		button.button_down.connect(buttonDownCallable)

	if not button.button_up.is_connected(buttonUpCallable):
		button.button_up.connect(buttonUpCallable)

	if not button.mouse_exited.is_connected(mouseExitedCallable):
		button.mouse_exited.connect(mouseExitedCallable)

	if not button.pressed.is_connected(pressedCallable):
		button.pressed.connect(pressedCallable)

	applyFooterButtonIdleState(button, icon, labelMargin, label)


# Applies footer button pressed visual feedback.
func onFooterButtonDown(
	button: TextureButton,
	icon: TextureRect,
	labelMargin: MarginContainer,
	label: Label
) -> void:
	applyFooterButtonPressedState(button, icon, labelMargin, label)


# Restores footer button normal visual state.
func onFooterButtonUp(
	button: TextureButton,
	icon: TextureRect,
	labelMargin: MarginContainer,
	label: Label
) -> void:
	applyFooterButtonIdleState(button, icon, labelMargin, label)


# Restores footer button state when the pointer exits while pressed.
func onFooterButtonMouseExited(
	button: TextureButton,
	icon: TextureRect,
	labelMargin: MarginContainer,
	label: Label
) -> void:
	if button == null or not button.button_pressed:
		return

	applyFooterButtonIdleState(button, icon, labelMargin, label)


# Plays the assigned sound and calls the footer action.
func onFooterButtonPressed(soundPlayer: AudioStreamPlayer, pressedCallback: Callable) -> void:
	gameplay.audioSystem.playFooterClickSound(soundPlayer)

	if pressedCallback.is_valid():
		pressedCallback.call()


# Highlights a footer button while pressed.
func applyFooterButtonPressedState(
	button: TextureButton,
	icon: TextureRect,
	_labelMargin: MarginContainer,
	label: Label
) -> void:
	if button == null:
		return

	button.scale = Vector2.ONE
	button.modulate = FOOTER_BUTTON_IDLE_COLOR

	if icon != null:
		icon.modulate = FOOTER_BUTTON_HIGHLIGHT_COLOR

	if label != null:
		label.add_theme_color_override("font_color", FOOTER_BUTTON_TEXT_COLOR)


# Restores a footer button to its idle state.
func applyFooterButtonIdleState(
	button: TextureButton,
	icon: TextureRect,
	_labelMargin: MarginContainer,
	label: Label
) -> void:
	if button == null:
		return

	button.scale = Vector2.ONE
	button.modulate = FOOTER_BUTTON_IDLE_COLOR

	if icon != null:
		icon.modulate = FOOTER_BUTTON_IDLE_COLOR

	if label != null:
		label.add_theme_color_override("font_color", FOOTER_BUTTON_IDLE_COLOR)