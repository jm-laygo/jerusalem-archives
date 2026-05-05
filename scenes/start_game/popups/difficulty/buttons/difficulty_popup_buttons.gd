extends VBoxContainer

signal difficulty_selected(difficulty_name: String)

@onready var easy_button: TextureButton = $EasyButton
@onready var normal_button: TextureButton = $NormalButton
@onready var hard_button: TextureButton = $HardButton


func _ready() -> void:
	_setup_buttons()


func _setup_buttons() -> void:
	_setup_difficulty_button(easy_button)
	_setup_difficulty_button(normal_button)
	_setup_difficulty_button(hard_button)

	if easy_button != null and not easy_button.pressed.is_connected(_on_easy_pressed):
		easy_button.pressed.connect(_on_easy_pressed)

	if normal_button != null and not normal_button.pressed.is_connected(_on_normal_pressed):
		normal_button.pressed.connect(_on_normal_pressed)

	if hard_button != null and not hard_button.pressed.is_connected(_on_hard_pressed):
		hard_button.pressed.connect(_on_hard_pressed)


func _setup_difficulty_button(button: TextureButton) -> void:
	if button == null:
		return

	button.focus_mode = Control.FOCUS_NONE
	button.modulate = Color(1, 1, 1, 1)

	for child in button.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_easy_pressed() -> void:
	difficulty_selected.emit("Easy")


func _on_normal_pressed() -> void:
	difficulty_selected.emit("Normal")


func _on_hard_pressed() -> void:
	difficulty_selected.emit("Hard")