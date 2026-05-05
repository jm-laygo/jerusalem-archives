extends Control

signal close_pressed
signal difficulty_selected(difficulty_name: String)

const X_NORMAL := Color(1, 1, 1, 1)
const X_CLICKED := Color(1.35, 1.15, 0.85, 1)

@onready var close_button: TextureButton = $CloseButton
@onready var difficulty_buttons: VBoxContainer = $DifficultyButtons


func _ready() -> void:
	_setup_close_button()
	_connect_buttons()


func _setup_close_button() -> void:
	if close_button == null:
		push_error("CloseButton not found.")
		return

	close_button.focus_mode = Control.FOCUS_NONE
	close_button.modulate = X_NORMAL

	if not close_button.button_down.is_connected(_on_close_button_down):
		close_button.button_down.connect(_on_close_button_down)

	if not close_button.button_up.is_connected(_on_close_button_up):
		close_button.button_up.connect(_on_close_button_up)

	if not close_button.mouse_exited.is_connected(_on_close_button_up):
		close_button.mouse_exited.connect(_on_close_button_up)

	if not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)

	for child in close_button.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _connect_buttons() -> void:
	if difficulty_buttons == null:
		push_error("DifficultyButtons not found.")
		return

	if difficulty_buttons.has_signal("difficulty_selected"):
		difficulty_buttons.connect("difficulty_selected", _on_difficulty_selected)


func _on_close_button_down() -> void:
	if close_button == null:
		return

	close_button.modulate = X_CLICKED


func _on_close_button_up() -> void:
	if close_button == null:
		return

	close_button.modulate = X_NORMAL


func _on_close_pressed() -> void:
	_on_close_button_up()
	close_pressed.emit()


func _on_difficulty_selected(difficulty_name: String) -> void:
	difficulty_selected.emit(difficulty_name)