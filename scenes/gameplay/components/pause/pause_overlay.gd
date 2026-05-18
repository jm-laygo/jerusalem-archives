extends Control

signal resumePressed
signal achievementsPressed
signal settingsPressed
signal backToMenuPressed

const BUTTON_NORMAL_MODULATE := Color(1, 1, 1, 1)
const BUTTON_PRESSED_MODULATE := Color(0.85, 0.85, 0.85, 1)

@onready var dim: ColorRect = $Dim
@onready var pausePanel: TextureRect = $PausePanel

@onready var resumeButton: TextureButton = $PausePanel/Buttons/ResumeButton
@onready var achievementsButton: TextureButton = $PausePanel/Buttons/AchievementsButton
@onready var settingsButton: TextureButton = $PausePanel/Buttons/SettingsButton
@onready var backToMenuButton: TextureButton = $PausePanel/Buttons/BackToMenuButton


# Prepares the pause overlay and connects all menu buttons.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true

	setupOverlayNodes()
	setupPauseButtons()


# Sets overlay nodes to ignore input where needed.
func setupOverlayNodes() -> void:
	if dim != null:
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if pausePanel != null:
		pausePanel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pausePanel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pausePanel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED


# Connects all pause menu buttons.
func setupPauseButtons() -> void:
	setupPauseButton(resumeButton, Callable(self, "onResumePressed"))
	setupPauseButton(achievementsButton, Callable(self, "onAchievementsPressed"))
	setupPauseButton(settingsButton, Callable(self, "onSettingsPressed"))
	setupPauseButton(backToMenuButton, Callable(self, "onBackToMenuPressed"))


# Prepares one pause menu button.
func setupPauseButton(button: TextureButton, callback: Callable) -> void:
	if button == null:
		return

	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.scale = Vector2.ONE
	button.modulate = BUTTON_NORMAL_MODULATE

	ignoreChildrenMouse(button)

	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)

	var buttonDownCallable := onPauseButtonDown.bind(button)
	var buttonUpCallable := onPauseButtonUp.bind(button)
	var mouseExitedCallable := onPauseButtonMouseExited.bind(button)

	if not button.button_down.is_connected(buttonDownCallable):
		button.button_down.connect(buttonDownCallable)

	if not button.button_up.is_connected(buttonUpCallable):
		button.button_up.connect(buttonUpCallable)

	if not button.mouse_exited.is_connected(mouseExitedCallable):
		button.mouse_exited.connect(mouseExitedCallable)


# Prevents button children from blocking clicks.
func ignoreChildrenMouse(button: TextureButton) -> void:
	if button == null:
		return

	for child in button.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE


# Applies simple grey/white press feedback.
func onPauseButtonDown(button: TextureButton) -> void:
	if button == null:
		return

	button.modulate = BUTTON_PRESSED_MODULATE
	button.scale = Vector2.ONE


# Restores normal button feedback.
func onPauseButtonUp(button: TextureButton) -> void:
	if button == null:
		return

	button.modulate = BUTTON_NORMAL_MODULATE
	button.scale = Vector2.ONE


# Restores normal feedback when the mouse exits.
func onPauseButtonMouseExited(button: TextureButton) -> void:
	if button == null:
		return

	button.modulate = BUTTON_NORMAL_MODULATE
	button.scale = Vector2.ONE


# Emits resume action.
func onResumePressed() -> void:
	resumePressed.emit()


# Emits achievements action.
func onAchievementsPressed() -> void:
	achievementsPressed.emit()


# Emits settings action.
func onSettingsPressed() -> void:
	settingsPressed.emit()


# Emits back-to-menu action.
func onBackToMenuPressed() -> void:
	backToMenuPressed.emit()