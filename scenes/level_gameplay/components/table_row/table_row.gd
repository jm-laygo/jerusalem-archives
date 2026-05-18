extends Button

signal row_selected(record: Dictionary)

const CHECK_WIDTH := 150
const NORMAL_WIDTH := 300
const LONG_WIDTH := 520

const ROW_HEIGHT := 130
const CELL_HEIGHT := 120
const CELL_Y_OFFSET := 5

const TYPE_NORMAL := "normal"
const TYPE_LONG := "long"

const DATA_CELL_SCENE := preload("res://scenes/level_gameplay/components/data_cell/data_cell.tscn")

const TEXTURE_ROW_NORMAL := preload("res://assets/interface/ui/level_gameplay/row_container.png")
const TEXTURE_ROW_CLICKED := preload("res://assets/interface/ui/level_gameplay/row_container_clicked.png")

const TEXTURE_CHECK_CONTAINER := preload("res://assets/interface/ui/level_gameplay/check_container.png")
const TEXTURE_CHECK_ICON := preload("res://assets/interface/icons/check_icon1.png")

@onready var row_background: TextureRect = $RowBackground
@onready var cells_hbox: HBoxContainer = $CellsHBox

@onready var check_cell: Control = $CellsHBox/CheckCell
@onready var check_background: TextureRect = $CellsHBox/CheckCell/CheckBackground
@onready var check_icon: TextureRect = $CellsHBox/CheckCell/CheckIcon

var row_record: Dictionary = {}
var row_columns: Array = []
var is_selected := false
var row_total_width := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	pressed.connect(_on_pressed)
	apply_visual_state()


func setup(columns: Array, record: Dictionary, selected: bool = false) -> void:
	row_columns = columns
	row_record = record
	is_selected = selected

	row_total_width = calculate_row_width()

	resize_row()
	clear_data_cells()
	build_data_cells()
	apply_visual_state()


func calculate_row_width() -> int:
	var total_width := CHECK_WIDTH

	for column in row_columns:
		var type := str(column.get("type", TYPE_NORMAL))

		if type == TYPE_LONG:
			total_width += LONG_WIDTH
		else:
			total_width += NORMAL_WIDTH

	return total_width


func resize_row() -> void:
	custom_minimum_size = Vector2(row_total_width, ROW_HEIGHT)

	if row_background != null:
		row_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_background.custom_minimum_size = Vector2(row_total_width, ROW_HEIGHT)
		row_background.position = Vector2.ZERO

	if cells_hbox != null:
		cells_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cells_hbox.custom_minimum_size = Vector2(row_total_width, CELL_HEIGHT)
		cells_hbox.position = Vector2(0, CELL_Y_OFFSET)

	if check_cell != null:
		check_cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		check_cell.custom_minimum_size = Vector2(CHECK_WIDTH, CELL_HEIGHT)

	if check_background != null:
		check_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		check_background.texture = TEXTURE_CHECK_CONTAINER
		check_background.custom_minimum_size = Vector2(CHECK_WIDTH, CELL_HEIGHT)
		check_background.position = Vector2.ZERO

	if check_icon != null:
		check_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		check_icon.texture = TEXTURE_CHECK_ICON
		check_icon.visible = is_selected


func clear_data_cells() -> void:
	if cells_hbox == null:
		return

	for child in cells_hbox.get_children():
		if child == check_cell:
			continue

		child.queue_free()


func build_data_cells() -> void:
	if cells_hbox == null:
		return

	for column in row_columns:
		var data_cell = DATA_CELL_SCENE.instantiate()
		cells_hbox.add_child(data_cell)

		data_cell.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var key := str(column.get("key", ""))
		var type := str(column.get("type", TYPE_NORMAL))
		var value := str(row_record.get(key, ""))

		data_cell.setup(value, type, is_selected)


func set_selected(selected: bool) -> void:
	is_selected = selected
	apply_visual_state()

	if cells_hbox == null:
		return

	for child in cells_hbox.get_children():
		if child == check_cell:
			continue

		if child.has_method("set_selected"):
			child.set_selected(is_selected)


func apply_visual_state() -> void:
	resize_row()

	if row_background != null:
		row_background.texture = TEXTURE_ROW_CLICKED if is_selected else TEXTURE_ROW_NORMAL

	if check_background != null:
		check_background.texture = TEXTURE_CHECK_CONTAINER
		check_background.visible = true

	if check_icon != null:
		check_icon.texture = TEXTURE_CHECK_ICON
		check_icon.visible = is_selected


func _on_pressed() -> void:
	row_selected.emit(row_record)
