extends TextureButton

signal header_pressed(column_key: String)

const NORMAL_WIDTH := 300
const LONG_WIDTH := 520
const CELL_HEIGHT := 120

const TYPE_NORMAL := "normal"
const TYPE_LONG := "long"

const HEADER_FONT := preload("res://assets/fonts/mapfont/Paradox_King_Script.otf")
const HEADER_FONT_SIZE := 50

const TEXTURE_HEADER_NORMAL := preload("res://assets/interface/ui/level_gameplay/title_header_border.png")
const TEXTURE_HEADER_NORMAL_CLICKED := preload("res://assets/interface/ui/level_gameplay/title_header_border_clicked.png")
const TEXTURE_HEADER_LONG := preload("res://assets/interface/ui/level_gameplay/title_header_border_long.png")
const TEXTURE_HEADER_LONG_CLICKED := preload("res://assets/interface/ui/level_gameplay/title_header_border_long_clicked.png")

@onready var title_label: Label = $TitleLabel

var column_title := ""
var column_key := ""
var cell_type := TYPE_NORMAL
var is_active := false


func _ready() -> void:
	pressed.connect(_on_pressed)
	apply_label_style()
	apply_visual_state()


func setup(column: Dictionary, active: bool = false) -> void:
	column_title = str(column.get("title", ""))
	column_key = str(column.get("key", ""))
	cell_type = str(column.get("type", TYPE_NORMAL))
	is_active = active

	if title_label != null:
		title_label.text = column_title.to_upper()
		apply_label_style()

	apply_visual_state()


func set_active(active: bool) -> void:
	is_active = active
	apply_visual_state()


func apply_label_style() -> void:
	if title_label == null:
		return

	title_label.add_theme_font_override("font", HEADER_FONT)
	title_label.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)
	title_label.add_theme_color_override("font_color", Color(0.972549, 0.909804, 0.74902, 1))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.clip_text = true
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


func apply_visual_state() -> void:
	var width := NORMAL_WIDTH

	if cell_type == TYPE_LONG:
		width = LONG_WIDTH

	custom_minimum_size = Vector2(width, CELL_HEIGHT)
	size = Vector2(width, CELL_HEIGHT)

	if cell_type == TYPE_LONG:
		texture_normal = TEXTURE_HEADER_LONG_CLICKED if is_active else TEXTURE_HEADER_LONG
		texture_pressed = TEXTURE_HEADER_LONG_CLICKED
		texture_hover = TEXTURE_HEADER_LONG_CLICKED if is_active else TEXTURE_HEADER_LONG
	else:
		texture_normal = TEXTURE_HEADER_NORMAL_CLICKED if is_active else TEXTURE_HEADER_NORMAL
		texture_pressed = TEXTURE_HEADER_NORMAL_CLICKED
		texture_hover = TEXTURE_HEADER_NORMAL_CLICKED if is_active else TEXTURE_HEADER_NORMAL


func _on_pressed() -> void:
	header_pressed.emit(column_key)
