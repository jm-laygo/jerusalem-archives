extends Control

signal resume_pressed
signal achievements_pressed
signal settings_pressed
signal back_to_menu_pressed

@onready var dim: ColorRect = $Dim
@onready var pause_panel: TextureRect = $PausePanel

@onready var resume_button: TextureButton = $PausePanel/Buttons/ResumeButton
@onready var achievements_button: TextureButton = $PausePanel/Buttons/AchievementsButton
@onready var settings_button: TextureButton = $PausePanel/Buttons/SettingsButton
@onready var back_to_menu_button: TextureButton = $PausePanel/Buttons/BackToMenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Keep the .tscn visible for editing.
	# But when the game runs, start hidden.
	visible = false

	if dim != null:
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if pause_panel != null:
		pause_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	setup_pause_button(resume_button, _on_resume_pressed)
	setup_pause_button(achievements_button, _on_achievements_pressed)
	setup_pause_button(settings_button, _on_settings_pressed)
	setup_pause_button(back_to_menu_button, _on_back_to_menu_pressed)


func setup_pause_button(button: TextureButton, callback: Callable) -> void:
	if button == null:
		return

	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.scale = Vector2.ONE
	button.modulate = Color(1, 1, 1, 1)

	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)

	if not button.button_down.is_connected(_on_pause_button_down.bind(button)):
		button.button_down.connect(_on_pause_button_down.bind(button))

	if not button.button_up.is_connected(_on_pause_button_up.bind(button)):
		button.button_up.connect(_on_pause_button_up.bind(button))

	if not button.mouse_exited.is_connected(_on_pause_button_mouse_exited.bind(button)):
		button.mouse_exited.connect(_on_pause_button_mouse_exited.bind(button))


func _on_pause_button_down(button: TextureButton) -> void:
	if button == null:
		return

	# Grey/white highlight only. No push-down scale.
	button.modulate = Color(0.85, 0.85, 0.85, 1.0)
	button.scale = Vector2.ONE


func _on_pause_button_up(button: TextureButton) -> void:
	if button == null:
		return

	button.modulate = Color(1, 1, 1, 1)
	button.scale = Vector2.ONE


func _on_pause_button_mouse_exited(button: TextureButton) -> void:
	if button == null:
		return

	button.modulate = Color(1, 1, 1, 1)
	button.scale = Vector2.ONE


func open() -> void:
	visible = true
	move_to_front()
	get_tree().paused = true


func close() -> void:
	get_tree().paused = false
	visible = false


func _on_resume_pressed() -> void:
	close()
	resume_pressed.emit()


func _on_achievements_pressed() -> void:
	achievements_pressed.emit()


func _on_settings_pressed() -> void:
	settings_pressed.emit()


func _on_back_to_menu_pressed() -> void:
	get_tree().paused = false
	back_to_menu_pressed.emit()
