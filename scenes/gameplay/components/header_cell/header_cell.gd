extends TextureButton

signal headerPressed(columnKey: String)

const NORMAL_WIDTH := 300
const LONG_WIDTH := 520
const SUPER_LONG_WIDTH := 720
const CELL_HEIGHT := 120

const TYPE_NORMAL := "normal"
const TYPE_LONG := "long"
const TYPE_SUPER_LONG := "superlong"

const HEADER_FONT: FontFile = preload("res://assets/fonts/mapfont/Paradox_King_Script.otf")
const HEADER_HEIGHT := 97.5
const HEADER_FONT_SIZE := 42
const HEADER_TEXT_COLOR := Color(0.972549, 0.909804, 0.74902, 1)

const HEADER_NORMAL_TEXTURE: Texture2D = preload("res://assets/interface/ui/level_gameplay/ui_row_title_header_container.png")
const HEADER_NORMAL_PRESSED_TEXTURE: Texture2D = preload("res://assets/interface/ui/level_gameplay/ui_row_title_header_container_pressed.png")
const HEADER_LONG_TEXTURE: Texture2D = preload("res://assets/interface/ui/level_gameplay/ui_row_title_header_container_long.png")
const HEADER_LONG_PRESSED_TEXTURE: Texture2D = preload("res://assets/interface/ui/level_gameplay/ui_row_title_header_container_long_pressed.png")

@onready var titleLabel: Label = $TitleLabel

var columnTitle := ""
var columnKey := ""
var cellType := TYPE_NORMAL
var isActive := false


# Prepares header styling and connects the press signal.
func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_SCALE

	if not pressed.is_connected(onPressed):
		pressed.connect(onPressed)

	applyLabelStyle()
	applyVisualState()


# Sets this header cell's column data and active sort state.
func setup(column: Dictionary, active: bool = false) -> void:
	columnTitle = str(column.get("title", ""))
	columnKey = str(column.get("key", ""))
	cellType = str(column.get("type", TYPE_NORMAL))
	isActive = active

	if titleLabel != null:
		titleLabel.text = columnTitle.to_upper()
		applyLabelStyle()

	applyVisualState()


# Updates the active sort visual state.
func setActive(active: bool) -> void:
	isActive = active
	applyVisualState()


# Returns the header width based on its column type.
func getCellWidth() -> int:
	if cellType == TYPE_SUPER_LONG:
		return SUPER_LONG_WIDTH

	if cellType == TYPE_LONG:
		return LONG_WIDTH

	return NORMAL_WIDTH


# Applies text styling to the title label.
func applyLabelStyle() -> void:
	if titleLabel == null:
		return

	titleLabel.add_theme_font_override("font", HEADER_FONT)
	titleLabel.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)
	titleLabel.add_theme_color_override("font_color", HEADER_TEXT_COLOR)
	titleLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titleLabel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titleLabel.clip_text = true
	titleLabel.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	titleLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE


# Applies the correct size and texture based on type and active state.
func applyVisualState() -> void:
	var cellWidth := getCellWidth()

	custom_minimum_size = Vector2(cellWidth, CELL_HEIGHT)
	size = Vector2(cellWidth, CELL_HEIGHT)

	if cellType == TYPE_LONG or cellType == TYPE_SUPER_LONG:
		texture_normal = HEADER_LONG_PRESSED_TEXTURE if isActive else HEADER_LONG_TEXTURE
		texture_pressed = HEADER_LONG_PRESSED_TEXTURE
		texture_hover = HEADER_LONG_PRESSED_TEXTURE if isActive else HEADER_LONG_TEXTURE
		texture_focused = texture_normal
		texture_disabled = texture_normal
		return

	texture_normal = HEADER_NORMAL_PRESSED_TEXTURE if isActive else HEADER_NORMAL_TEXTURE
	texture_pressed = HEADER_NORMAL_PRESSED_TEXTURE
	texture_hover = HEADER_NORMAL_PRESSED_TEXTURE if isActive else HEADER_NORMAL_TEXTURE
	texture_focused = texture_normal
	texture_disabled = texture_normal


# Emits the selected column key when this header is pressed.
func onPressed() -> void:
	headerPressed.emit(columnKey)
