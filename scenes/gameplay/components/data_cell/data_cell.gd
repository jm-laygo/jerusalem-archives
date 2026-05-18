extends Control

const NORMAL_WIDTH := 300
const LONG_WIDTH := 520
const SUPER_LONG_WIDTH := 720
const CELL_HEIGHT := 120

const TYPE_NORMAL := "normal"
const TYPE_LONG := "long"
const TYPE_SUPER_LONG := "superlong"

const DATA_FONT_SIZE := 50

const DATA_TEXT_COLOR := Color(0.972549, 0.909804, 0.74902, 1)

const DATA_NORMAL_TEXTURE: Texture2D = preload("res://assets/interface/ui/level_gameplay/ui_data_container.png")
const DATA_NORMAL_PRESSED_TEXTURE: Texture2D = preload("res://assets/interface/ui/level_gameplay/ui_data_container_pressed.png")
const DATA_LONG_TEXTURE: Texture2D = preload("res://assets/interface/ui/level_gameplay/ui_data_container_long.png")
const DATA_LONG_PRESSED_TEXTURE: Texture2D = preload("res://assets/interface/ui/level_gameplay/ui_data_container_long_pressed.png")

@onready var background: TextureRect = $Background
@onready var valueLabel: Label = $ValueLabel

var cellType := TYPE_NORMAL
var isSelected := false
var cellValue := ""


# Prepares the cell so row buttons handle all input.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if background != null:
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if valueLabel != null:
		valueLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	applyLabelStyle()
	applyVisualState()


# Sets the cell value, width type, and selected state.
func setup(value: String, type: String = TYPE_NORMAL, selected: bool = false) -> void:
	cellValue = value
	cellType = type
	isSelected = selected

	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if valueLabel != null:
		valueLabel.text = cellValue
		applyLabelStyle()

	applyVisualState()


# Updates the selected visual state.
func setSelected(selected: bool) -> void:
	isSelected = selected
	applyVisualState()


# Updates the displayed cell value.
func setValue(value: String) -> void:
	cellValue = value

	if valueLabel != null:
		valueLabel.text = cellValue
		applyLabelStyle()


# Updates the cell width type.
func setCellType(type: String) -> void:
	cellType = type
	applyVisualState()


# Returns the cell width based on its column type.
func getCellWidth() -> int:
	if cellType == TYPE_SUPER_LONG:
		return SUPER_LONG_WIDTH

	if cellType == TYPE_LONG:
		return LONG_WIDTH

	return NORMAL_WIDTH


# Applies text styling to the value label.
func applyLabelStyle() -> void:
	if valueLabel == null:
		return

	valueLabel.add_theme_font_size_override("font_size", DATA_FONT_SIZE)
	valueLabel.add_theme_color_override("font_color", DATA_TEXT_COLOR)

	valueLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	valueLabel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	valueLabel.clip_text = true
	valueLabel.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


# Applies size and background texture based on state.
func applyVisualState() -> void:
	var cellWidth := getCellWidth()

	custom_minimum_size = Vector2(cellWidth, CELL_HEIGHT)
	size = Vector2(cellWidth, CELL_HEIGHT)

	if background == null:
		return

	background.custom_minimum_size = Vector2(cellWidth, CELL_HEIGHT)
	background.size = Vector2(cellWidth, CELL_HEIGHT)
	background.texture = getTextureForState()


# Returns the correct background texture for type and selection state.
func getTextureForState() -> Texture2D:
	if cellType == TYPE_LONG or cellType == TYPE_SUPER_LONG:
		return DATA_LONG_PRESSED_TEXTURE if isSelected else DATA_LONG_TEXTURE

	return DATA_NORMAL_PRESSED_TEXTURE if isSelected else DATA_NORMAL_TEXTURE