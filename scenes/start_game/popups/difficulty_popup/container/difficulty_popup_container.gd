extends Control

signal closePressed
signal difficultySelected(difficultyName: String)

const CLOSE_NORMAL_MODULATE := Color(1, 1, 1, 1)
const CLOSE_PRESSED_MODULATE := Color(1.35, 1.15, 0.85, 1)

@onready var closeButton: TextureButton = $CloseButton
@onready var difficultyButtons: Control = $DifficultyButtons


# Prepares the close button and connects difficulty button signals.
func _ready() -> void:
	await get_tree().process_frame

	setupCloseButton()
	connectDifficultyButtons()


# Sets up the close button visual feedback and signals.
func setupCloseButton() -> void:
	if closeButton == null:
		push_error("CloseButton not found.")
		return

	closeButton.focus_mode = Control.FOCUS_NONE
	closeButton.modulate = CLOSE_NORMAL_MODULATE

	if not closeButton.button_down.is_connected(onCloseButtonDown):
		closeButton.button_down.connect(onCloseButtonDown)

	if not closeButton.button_up.is_connected(onCloseButtonUp):
		closeButton.button_up.connect(onCloseButtonUp)

	if not closeButton.mouse_exited.is_connected(onCloseButtonUp):
		closeButton.mouse_exited.connect(onCloseButtonUp)

	if not closeButton.pressed.is_connected(onClosePressed):
		closeButton.pressed.connect(onClosePressed)

	ignoreChildrenMouse(closeButton)


# Connects the difficulty buttons component to this container.
func connectDifficultyButtons() -> void:
	if difficultyButtons == null:
		push_error("DifficultyButtons not found.")
		return

	connectSignalIfAvailable(
		difficultyButtons,
		"difficultySelected",
		Callable(self, "onDifficultySelected")
	)


# Connects a signal only when it exists and is not already connected.
func connectSignalIfAvailable(target: Object, signalName: String, callback: Callable) -> void:
	if target == null:
		return

	if not target.has_signal(signalName):
		push_error("%s has no %s signal." % [target.name, signalName])
		return

	if not target.is_connected(signalName, callback):
		target.connect(signalName, callback)


# Prevents child controls from blocking button clicks.
func ignoreChildrenMouse(button: TextureButton) -> void:
	if button == null:
		return

	for child in button.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE


# Applies close button pressed feedback.
func onCloseButtonDown() -> void:
	if closeButton == null:
		return

	closeButton.modulate = CLOSE_PRESSED_MODULATE


# Restores the close button normal state.
func onCloseButtonUp() -> void:
	if closeButton == null:
		return

	closeButton.modulate = CLOSE_NORMAL_MODULATE


# Emits the container close signal.
func onClosePressed() -> void:
	onCloseButtonUp()
	closePressed.emit()


# Forwards the selected difficulty to the popup controller.
func onDifficultySelected(difficultyName: String) -> void:
	difficultySelected.emit(difficultyName)