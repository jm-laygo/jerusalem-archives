extends Control

const NORMAL_WIDTH := 300
const LONG_WIDTH := 520
const CELL_HEIGHT := 120

const TYPE_NORMAL := "normal"
const TYPE_LONG := "long"

const DATA_FONT_SIZE := 50

const TEXTURE_DATA_NORMAL := preload("res://assets/interface/ui/level_gameplay/data_container.png")
const TEXTURE_DATA_NORMAL_CLICKED := preload("res://assets/interface/ui/level_gameplay/data_container_clicked.png")
const TEXTURE_DATA_LONG := preload("res://assets/interface/ui/level_gameplay/data_container_long.png")
const TEXTURE_DATA_LONG_CLICKED := preload("res://assets/interface/ui/level_gameplay/data_container_long_clicked.png")

@onready var background: TextureRect = $Background
@onready var value_label: Label = $ValueLabel

var cell_type := TYPE_NORMAL
var is_selected := false
var cell_value := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if background != null:
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if value_label != null:
		value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	apply_label_style()
	apply_visual_state()


func setup(value: String, type: String = TYPE_NORMAL, selected: bool = false) -> void:
	cell_value = value
	cell_type = type
	is_selected = selected

	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if value_label != null:
		value_label.text = cell_value
		apply_label_style()

	apply_visual_state()


func set_selected(selected: bool) -> void:
	is_selected = selected
	apply_visual_state()


func set_value(value: String) -> void:
	cell_value = value

	if value_label != null:
		value_label.text = cell_value
		apply_label_style()


func set_cell_type(type: String) -> void:
	cell_type = type
	apply_visual_state()


func apply_label_style() -> void:
	if value_label == null:
		return

	value_label.add_theme_font_size_override("font_size", DATA_FONT_SIZE)
	value_label.add_theme_color_override("font_color", Color(0.972549, 0.909804, 0.74902, 1))

	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.clip_text = true
	value_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


func apply_visual_state() -> void:
	var width := NORMAL_WIDTH

	if cell_type == TYPE_LONG:
		width = LONG_WIDTH

	custom_minimum_size = Vector2(width, CELL_HEIGHT)

	if background == null:
		return

	background.custom_minimum_size = Vector2(width, CELL_HEIGHT)
	background.texture = get_texture_for_state()


func get_texture_for_state() -> Texture2D:
	if cell_type == TYPE_LONG:
		return TEXTURE_DATA_LONG_CLICKED if is_selected else TEXTURE_DATA_LONG

	return TEXTURE_DATA_NORMAL_CLICKED if is_selected else TEXTURE_DATA_NORMAL
