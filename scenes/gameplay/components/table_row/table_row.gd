extends Button

signal rowSelected(record: Dictionary)

const CHECK_WIDTH := 150
const NORMAL_WIDTH := 300
const LONG_WIDTH := 520
const SUPER_LONG_WIDTH := 720
const TABLE_RIGHT_PADDING := 160

const ROW_HEIGHT := 130
const CELL_HEIGHT := 120
const CELL_Y_OFFSET := 5

const TYPE_NORMAL := "normal"
const TYPE_LONG := "long"
const TYPE_SUPER_LONG := "superlong"

const DATA_CELL_SCENE := preload("res://scenes/gameplay/components/data_cell/data_cell.tscn")

const ROW_NORMAL_TEXTURE: Texture2D = preload("res://assets/interface/ui/level_gameplay/ui_row_container.png")
const ROW_PRESSED_TEXTURE: Texture2D = preload("res://assets/interface/ui/level_gameplay/ui_row_container_pressed.png")

const CHECK_CONTAINER_TEXTURE: Texture2D = preload("res://assets/interface/ui/level_gameplay/ui_check_container.png")
const CHECK_CONTAINER_PRESSED_TEXTURE: Texture2D = preload("res://assets/interface/ui/level_gameplay/ui_check_container_pressed.png")
const CHECK_ICON_TEXTURE: Texture2D = preload("res://assets/interface/icons/icon_check01.png")

const ROW_NORMAL_SCALE := Vector2.ONE
const ROW_PRESSED_SCALE := Vector2(1.01, 1.01)
const ROW_ANIMATION_TIME := 0.08
const ROW_RETURN_TIME := 0.12
const ROW_WRONG_COLOR := Color(1.0, 0.45, 0.45, 1.0)
const ROW_CORRECT_COLOR := Color(0.55, 1.0, 0.55, 1.0)
const ROW_NORMAL_COLOR := Color(1, 1, 1, 1)

@onready var rowBackground: TextureRect = $RowBackground
@onready var cellsHBox: HBoxContainer = $CellsHBox

@onready var checkCell: Control = $CellsHBox/CheckCell
@onready var checkBackground: TextureRect = $CellsHBox/CheckCell/CheckBackground
@onready var checkIcon: TextureRect = $CellsHBox/CheckCell/CheckIcon

var rowRecord: Dictionary = {}
var rowColumns: Array = []

var isSelected := false
var rowTotalWidth := 0

var rowTween: Tween


# Prepares row input and default visuals.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE

	if not pressed.is_connected(onPressed):
		pressed.connect(onPressed)

	applyVisualState()


# Sets the row data, rebuilds cells, and applies selected state.
func setup(columns: Array, record: Dictionary, selected: bool = false) -> void:
	rowColumns = columns
	rowRecord = record
	isSelected = selected

	rowTotalWidth = calculateRowWidth()

	resizeRow()
	clearDataCells()
	buildDataCells()
	applyVisualState()


# Calculates the full row width from all columns.
func calculateRowWidth() -> int:
	var totalWidth := CHECK_WIDTH

	for column in rowColumns:
		var columnType := str(column.get("type", TYPE_NORMAL))

		if columnType == TYPE_SUPER_LONG:
			totalWidth += SUPER_LONG_WIDTH
		elif columnType == TYPE_LONG:
			totalWidth += LONG_WIDTH
		else:
			totalWidth += NORMAL_WIDTH

	totalWidth += TABLE_RIGHT_PADDING

	return totalWidth


# Resizes the row and its fixed check cell area.
func resizeRow() -> void:
	custom_minimum_size = Vector2(rowTotalWidth, ROW_HEIGHT)
	size = Vector2(rowTotalWidth, ROW_HEIGHT)

	if rowBackground != null:
		rowBackground.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rowBackground.custom_minimum_size = Vector2(rowTotalWidth, ROW_HEIGHT)
		rowBackground.size = Vector2(rowTotalWidth, ROW_HEIGHT)
		rowBackground.position = Vector2.ZERO

	if cellsHBox != null:
		cellsHBox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cellsHBox.custom_minimum_size = Vector2(rowTotalWidth, CELL_HEIGHT)
		cellsHBox.size = Vector2(rowTotalWidth, CELL_HEIGHT)
		cellsHBox.position = Vector2(0, CELL_Y_OFFSET)

	if checkCell != null:
		checkCell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		checkCell.custom_minimum_size = Vector2(CHECK_WIDTH, CELL_HEIGHT)

	if checkBackground != null:
		checkBackground.mouse_filter = Control.MOUSE_FILTER_IGNORE
		checkBackground.texture = CHECK_CONTAINER_PRESSED_TEXTURE if isSelected else CHECK_CONTAINER_TEXTURE
		checkBackground.custom_minimum_size = Vector2(CHECK_WIDTH, CELL_HEIGHT)
		checkBackground.size = Vector2(CHECK_WIDTH, CELL_HEIGHT)
		checkBackground.position = Vector2.ZERO

	if checkIcon != null:
		checkIcon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		checkIcon.texture = CHECK_ICON_TEXTURE
		checkIcon.visible = isSelected


# Removes existing data cells while keeping the check cell.
func clearDataCells() -> void:
	if cellsHBox == null:
		return

	for child in cellsHBox.get_children():
		if child == checkCell:
			continue

		child.queue_free()


# Builds all row data cells from the row record.
func buildDataCells() -> void:
	if cellsHBox == null:
		return

	for column in rowColumns:
		var dataCell = DATA_CELL_SCENE.instantiate()
		cellsHBox.add_child(dataCell)

		dataCell.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var key := str(column.get("key", ""))
		var columnType := str(column.get("type", TYPE_NORMAL))
		var value := str(rowRecord.get(key, ""))

		dataCell.setup(value, columnType, isSelected)

	var rightSpacer := Control.new()
	rightSpacer.custom_minimum_size = Vector2(TABLE_RIGHT_PADDING, CELL_HEIGHT)
	rightSpacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cellsHBox.add_child(rightSpacer)


# Updates this row and its child cells when selected/unselected.
func setSelected(selected: bool) -> void:
	isSelected = selected
	applyVisualState()

	if cellsHBox == null:
		return

	for child in cellsHBox.get_children():
		if child == checkCell:
			continue

		if child.has_method("setSelected"):
			child.setSelected(isSelected)


# Applies row background and check icon state.
func applyVisualState() -> void:
	resizeRow()

	if rowBackground != null:
		rowBackground.texture = ROW_PRESSED_TEXTURE if isSelected else ROW_NORMAL_TEXTURE

	if checkBackground != null:
		checkBackground.texture = CHECK_CONTAINER_PRESSED_TEXTURE if isSelected else CHECK_CONTAINER_TEXTURE
		checkBackground.visible = true

	if checkIcon != null:
		checkIcon.texture = CHECK_ICON_TEXTURE
		checkIcon.visible = isSelected


# Emits the selected row record and plays a small selection animation.
func onPressed() -> void:
	playSelectAnimation()
	rowSelected.emit(rowRecord)

# Plays a subtle row selection animation.
func playSelectAnimation() -> void:
	if rowTween != null and rowTween.is_valid():
		rowTween.kill()

	pivot_offset = size * 0.5
	scale = ROW_NORMAL_SCALE

	rowTween = create_tween()
	rowTween.tween_property(self, "scale", ROW_PRESSED_SCALE, ROW_ANIMATION_TIME)
	rowTween.tween_property(self, "scale", ROW_NORMAL_SCALE, ROW_RETURN_TIME)


# Plays feedback when the selected row is correct.
func playCorrectAnimation() -> void:
	if rowBackground == null:
		return

	if rowTween != null and rowTween.is_valid():
		rowTween.kill()

	rowBackground.modulate = ROW_CORRECT_COLOR

	rowTween = create_tween()
	rowTween.tween_property(rowBackground, "modulate", ROW_NORMAL_COLOR, 0.35)


# Plays feedback when the selected row is wrong.
func playWrongAnimation() -> void:
	if rowBackground == null:
		return

	if rowTween != null and rowTween.is_valid():
		rowTween.kill()

	var originalPosition := position
	rowBackground.modulate = ROW_WRONG_COLOR

	rowTween = create_tween()
	rowTween.tween_property(self, "position", originalPosition + Vector2(-8, 0), 0.04)
	rowTween.tween_property(self, "position", originalPosition + Vector2(8, 0), 0.04)
	rowTween.tween_property(self, "position", originalPosition, 0.04)
	rowTween.tween_property(rowBackground, "modulate", ROW_NORMAL_COLOR, 0.25)