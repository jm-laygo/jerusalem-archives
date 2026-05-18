extends RefCounted

const CHECK_HEADER_WIDTH := 150.0
const HEADER_HEIGHT := 120.0

const NORMAL_WIDTH := 300.0
const LONG_WIDTH := 520.0
const SUPER_LONG_WIDTH := 720.0
const TABLE_RIGHT_PADDING := 160.0
const TABLE_WIDTH := 1080.0

const HEADER_Y := 246.0
const ROWS_Y := 374.0
const DEFAULT_ROWS_VIEWPORT_HEIGHT := 100.0

const COLUMN_TYPE_NORMAL := "normal"
const COLUMN_TYPE_LONG := "long"
const COLUMN_TYPE_SUPER_LONG := "superlong"

const RECORD_ID_KEY := "record_id"

var gameplay: Control


# Stores the gameplay screen reference used by this table system.
func _init(gameplayOwner: Control) -> void:
	gameplay = gameplayOwner


# Creates the manual table viewport nodes used by headers and rows.
func setupManualTableNodes() -> void:
	if gameplay.dataHeader == null:
		return

	removeLegacyTableViewport()
	setupHeaderViewport()
	setupRowsViewport()

	gameplay.tableHeaderViewport.move_to_front()
	gameplay.tableRowsViewport.move_to_front()
	gameplay.scrollSystem.moveCustomScrollbarsToFront()


# Removes the old ScrollContainer table if it still exists in the scene.
func removeLegacyTableViewport() -> void:
	var oldTableViewport: Node = gameplay.dataHeader.get_node_or_null("TableViewport")

	if oldTableViewport != null:
		oldTableViewport.queue_free()


# Creates or retrieves the clipped header viewport.
func setupHeaderViewport() -> void:
	gameplay.tableHeaderViewport = gameplay.dataHeader.get_node_or_null("TableHeaderViewport") as Control

	if gameplay.tableHeaderViewport == null:
		gameplay.tableHeaderViewport = Control.new()
		gameplay.tableHeaderViewport.name = "TableHeaderViewport"
		gameplay.dataHeader.add_child(gameplay.tableHeaderViewport)

	gameplay.tableHeaderViewport.position = Vector2(0.0, HEADER_Y)
	gameplay.tableHeaderViewport.size = Vector2(TABLE_WIDTH, HEADER_HEIGHT)
	gameplay.tableHeaderViewport.custom_minimum_size = Vector2(TABLE_WIDTH, HEADER_HEIGHT)
	gameplay.tableHeaderViewport.clip_contents = true
	gameplay.tableHeaderViewport.mouse_filter = Control.MOUSE_FILTER_IGNORE

	gameplay.headerHBox = gameplay.tableHeaderViewport.get_node_or_null("HeaderHBox") as HBoxContainer

	if gameplay.headerHBox == null:
		gameplay.headerHBox = HBoxContainer.new()
		gameplay.headerHBox.name = "HeaderHBox"
		gameplay.tableHeaderViewport.add_child(gameplay.headerHBox)

	gameplay.headerHBox.position = Vector2.ZERO
	gameplay.headerHBox.add_theme_constant_override("separation", 0)


# Creates or retrieves the clipped rows viewport.
func setupRowsViewport() -> void:
	gameplay.tableRowsViewport = gameplay.dataHeader.get_node_or_null("TableRowsViewport") as Control

	if gameplay.tableRowsViewport == null:
		gameplay.tableRowsViewport = Control.new()
		gameplay.tableRowsViewport.name = "TableRowsViewport"
		gameplay.dataHeader.add_child(gameplay.tableRowsViewport)

	gameplay.tableRowsViewport.position = Vector2(0.0, ROWS_Y)
	gameplay.tableRowsViewport.size = Vector2(TABLE_WIDTH, DEFAULT_ROWS_VIEWPORT_HEIGHT)
	gameplay.tableRowsViewport.custom_minimum_size = Vector2(TABLE_WIDTH, DEFAULT_ROWS_VIEWPORT_HEIGHT)
	gameplay.tableRowsViewport.clip_contents = true
	gameplay.tableRowsViewport.mouse_filter = Control.MOUSE_FILTER_PASS

	gameplay.rowsVBox = gameplay.tableRowsViewport.get_node_or_null("RowsVBox") as VBoxContainer

	if gameplay.rowsVBox == null:
		gameplay.rowsVBox = VBoxContainer.new()
		gameplay.rowsVBox.name = "RowsVBox"
		gameplay.tableRowsViewport.add_child(gameplay.rowsVBox)

	gameplay.rowsVBox.position = Vector2.ZERO
	gameplay.rowsVBox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	gameplay.rowsVBox.add_theme_constant_override("separation", 0)


# Builds the table headers and rows.
func buildTable() -> void:
	clearContainer(gameplay.headerHBox)
	clearContainer(gameplay.rowsVBox)

	buildHeaders()
	buildRows()

	gameplay.call_deferred("refreshScrollLimits")


# Removes all children from a container.
func clearContainer(container: Node) -> void:
	if container == null:
		return

	for child in container.get_children():
		child.queue_free()


# Builds the table header row.
func buildHeaders() -> void:
	if gameplay.headerHBox == null:
		return

	var checkSpacer := Control.new()
	checkSpacer.custom_minimum_size = Vector2(CHECK_HEADER_WIDTH, HEADER_HEIGHT)
	gameplay.headerHBox.add_child(checkSpacer)

	for column in gameplay.currentColumns:
		var headerCell = gameplay.HEADER_CELL_SCENE.instantiate()
		gameplay.headerHBox.add_child(headerCell)

		var columnKey := str(column.get("key", ""))
		var isActiveSort: bool = columnKey == gameplay.activeSortColumnKey

		headerCell.setup(column, isActiveSort)

		if headerCell.has_signal("headerPressed"):
			headerCell.headerPressed.connect(Callable(gameplay, "onHeaderPressed"))
		elif headerCell.has_signal("header_pressed"):
			headerCell.header_pressed.connect(Callable(gameplay, "onHeaderPressed"))

	var rightSpacer := Control.new()
	rightSpacer.custom_minimum_size = Vector2(TABLE_RIGHT_PADDING, HEADER_HEIGHT)
	gameplay.headerHBox.add_child(rightSpacer)


# Builds the table record rows.
func buildRows() -> void:
	if gameplay.rowsVBox == null:
		return

	for record in gameplay.currentRecords:
		var row = gameplay.TABLE_ROW_SCENE.instantiate()
		gameplay.rowsVBox.add_child(row)

		row.setup(gameplay.currentColumns, record, false)

		if row.has_signal("rowSelected"):
			row.rowSelected.connect(Callable(gameplay, "onRowSelected").bind(row))
		elif row.has_signal("row_selected"):
			row.row_selected.connect(Callable(gameplay, "onRowSelected").bind(row))


# Calculates full table width from column definitions.
func calculateTableWidth() -> float:
	var total := CHECK_HEADER_WIDTH

	for column in gameplay.currentColumns:
		var columnType := str(column.get("type", COLUMN_TYPE_NORMAL))

		if columnType == COLUMN_TYPE_SUPER_LONG:
			total += SUPER_LONG_WIDTH
		elif columnType == COLUMN_TYPE_LONG:
			total += LONG_WIDTH
		else:
			total += NORMAL_WIDTH

	return total


# Handles a header click and toggles sorting.
func onHeaderPressed(columnKey: String) -> void:
	gameplay.audioSystem.playFooterClickSound(gameplay.titleHeaderClickSound)

	if columnKey.is_empty():
		return

	if gameplay.activeSortColumnKey == columnKey:
		gameplay.activeSortColumnKey = ""
	else:
		gameplay.activeSortColumnKey = columnKey

	if gameplay.searchSystem != null:
		gameplay.searchSystem.applySearchFilter(false)
	elif not gameplay.activeSortColumnKey.is_empty():
		gameplay.currentRecords = gameplay.originalRecords.duplicate(true)
		sortCurrentRecordsByColumn(gameplay.activeSortColumnKey)
	else:
		gameplay.currentRecords = gameplay.originalRecords.duplicate(true)

	rebuildTableKeepScroll()


# Sorts the currently displayed records using the given column key.
func sortCurrentRecordsByColumn(columnKey: String) -> void:
	if columnKey == RECORD_ID_KEY:
		gameplay.currentRecords.sort_custom(func(a, b) -> bool:
			return getRecordIdNumber(a) > getRecordIdNumber(b)
		)
		return

	gameplay.currentRecords.sort_custom(func(a, b) -> bool:
		var valueA := str(a.get(columnKey, "")).to_lower()
		var valueB := str(b.get(columnKey, "")).to_lower()

		if valueA == valueB:
			return getRecordIdNumber(a) < getRecordIdNumber(b)

		return valueA < valueB
	)


# Extracts the number inside a record id.
func getRecordIdNumber(record: Dictionary) -> int:
	var rawId := str(record.get(RECORD_ID_KEY, ""))
	var digits := ""

	for character in rawId:
		if character >= "0" and character <= "9":
			digits += character

	if digits.is_empty():
		return 0

	return int(digits)


# Rebuilds the table without resetting the scroll position.
func rebuildTableKeepScroll() -> void:
	var oldScrollX: float = gameplay.scrollX
	var oldScrollY: float = gameplay.scrollY

	clearContainer(gameplay.headerHBox)
	clearContainer(gameplay.rowsVBox)

	buildHeaders()
	buildRows()

	gameplay.scrollX = oldScrollX
	gameplay.scrollY = oldScrollY

	gameplay.call_deferred("refreshScrollLimits")
