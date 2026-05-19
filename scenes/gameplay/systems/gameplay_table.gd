extends RefCounted

const CHECK_HEADER_WIDTH := 150.0

# This is the whole header metal/viewport area.
const HEADER_VIEWPORT_HEIGHT := 120.0

# This is ONLY the red/brown clickable header button height.
const HEADER_BUTTON_HEIGHT := 97.5

# Moves the smaller header buttons vertically inside the 120px header area.
const HEADER_BUTTON_Y := 7.8	

const NORMAL_WIDTH := 300.0
const LONG_WIDTH := 520.0
const SUPER_LONG_WIDTH := 720.0
const TABLE_RIGHT_PADDING := 160.0
const TABLE_WIDTH := 1080.0

const HEADER_Y := 300.0
const ROWS_Y := 428.0
const DEFAULT_ROWS_VIEWPORT_HEIGHT := 100.0

const COLUMN_TYPE_NORMAL := "normal"
const COLUMN_TYPE_LONG := "long"
const COLUMN_TYPE_SUPER_LONG := "superlong"

const RECORD_ID_KEY := "record_id"

var gameplay: Control


func _init(gameplayOwner: Control) -> void:
	gameplay = gameplayOwner


func setupManualTableNodes() -> void:
	if gameplay.dataHeader == null:
		return

	removeLegacyTableViewport()
	setupHeaderViewport()
	setupRowsViewport()

	gameplay.tableHeaderViewport.move_to_front()
	gameplay.tableRowsViewport.move_to_front()

	if gameplay.scrollSystem != null and gameplay.scrollSystem.has_method("moveCustomScrollbarsToFront"):
		gameplay.scrollSystem.moveCustomScrollbarsToFront()


func removeLegacyTableViewport() -> void:
	var oldTableViewport: Node = gameplay.dataHeader.get_node_or_null("TableViewport")

	if oldTableViewport != null:
		oldTableViewport.queue_free()


func setupHeaderViewport() -> void:
	gameplay.tableHeaderViewport = gameplay.dataHeader.get_node_or_null("TableHeaderViewport") as Control

	if gameplay.tableHeaderViewport == null:
		gameplay.tableHeaderViewport = Control.new()
		gameplay.tableHeaderViewport.name = "TableHeaderViewport"
		gameplay.dataHeader.add_child(gameplay.tableHeaderViewport)

	# Keep this tall. This is the full metal/header area.
	gameplay.tableHeaderViewport.position = Vector2(0.0, HEADER_Y)
	gameplay.tableHeaderViewport.size = Vector2(TABLE_WIDTH, HEADER_VIEWPORT_HEIGHT)
	gameplay.tableHeaderViewport.custom_minimum_size = Vector2(TABLE_WIDTH, HEADER_VIEWPORT_HEIGHT)
	gameplay.tableHeaderViewport.clip_contents = true
	gameplay.tableHeaderViewport.mouse_filter = Control.MOUSE_FILTER_IGNORE

	gameplay.headerHBox = gameplay.tableHeaderViewport.get_node_or_null("HeaderHBox") as HBoxContainer

	if gameplay.headerHBox == null:
		gameplay.headerHBox = HBoxContainer.new()
		gameplay.headerHBox.name = "HeaderHBox"
		gameplay.tableHeaderViewport.add_child(gameplay.headerHBox)

	gameplay.headerHBox.position = Vector2.ZERO
	gameplay.headerHBox.size = Vector2(calculateTableWidth() + TABLE_RIGHT_PADDING, HEADER_VIEWPORT_HEIGHT)
	gameplay.headerHBox.custom_minimum_size = Vector2(calculateTableWidth() + TABLE_RIGHT_PADDING, HEADER_VIEWPORT_HEIGHT)
	gameplay.headerHBox.add_theme_constant_override("separation", 0)


func setupRowsViewport() -> void:
	gameplay.tableRowsViewport = gameplay.dataHeader.get_node_or_null("TableRowsViewport") as Control

	if gameplay.tableRowsViewport == null:
		gameplay.tableRowsViewport = Control.new()
		gameplay.tableRowsViewport.name = "TableRowsViewport"
		gameplay.dataHeader.add_child(gameplay.tableRowsViewport)

	# Keep rows in the same place. Do not move them up.
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


func buildTable() -> void:
	clearContainer(gameplay.headerHBox)
	clearContainer(gameplay.rowsVBox)

	buildHeaders()
	buildRows()

	gameplay.call_deferred("refreshScrollLimits")


func clearContainer(container: Node) -> void:
	if container == null:
		return

	for child in container.get_children():
		child.queue_free()


func buildHeaders() -> void:
	if gameplay.headerHBox == null:
		return

	# Header viewport stays tall.
	gameplay.tableHeaderViewport.size = Vector2(TABLE_WIDTH, HEADER_VIEWPORT_HEIGHT)
	gameplay.tableHeaderViewport.custom_minimum_size = Vector2(TABLE_WIDTH, HEADER_VIEWPORT_HEIGHT)

	gameplay.headerHBox.position = Vector2.ZERO
	gameplay.headerHBox.size = Vector2(calculateTableWidth() + TABLE_RIGHT_PADDING, HEADER_VIEWPORT_HEIGHT)
	gameplay.headerHBox.custom_minimum_size = Vector2(calculateTableWidth() + TABLE_RIGHT_PADDING, HEADER_VIEWPORT_HEIGHT)

	# Empty check spacer still uses full header area.
	var checkSpacer := Control.new()
	checkSpacer.custom_minimum_size = Vector2(CHECK_HEADER_WIDTH, HEADER_VIEWPORT_HEIGHT)
	checkSpacer.size = Vector2(CHECK_HEADER_WIDTH, HEADER_VIEWPORT_HEIGHT)
	gameplay.headerHBox.add_child(checkSpacer)

	for column in gameplay.currentColumns:
		var columnType := str(column.get("type", COLUMN_TYPE_NORMAL))
		var cellWidth := getColumnWidth(columnType)

		# Wrapper keeps the full header area height.
		# This prevents HBoxContainer from forcing the button back to 120px.
		var headerWrapper := Control.new()
		headerWrapper.custom_minimum_size = Vector2(cellWidth, HEADER_VIEWPORT_HEIGHT)
		headerWrapper.size = Vector2(cellWidth, HEADER_VIEWPORT_HEIGHT)
		headerWrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gameplay.headerHBox.add_child(headerWrapper)

		var headerCell = gameplay.HEADER_CELL_SCENE.instantiate()
		headerWrapper.add_child(headerCell)

		var columnKey := str(column.get("key", ""))
		var isActiveSort: bool = columnKey == gameplay.activeSortColumnKey

		headerCell.setup(column, isActiveSort)

		# This is the actual smaller clickable button.
		headerCell.position = Vector2(0.0, HEADER_BUTTON_Y)
		headerCell.custom_minimum_size = Vector2(cellWidth, HEADER_BUTTON_HEIGHT)
		headerCell.size = Vector2(cellWidth, HEADER_BUTTON_HEIGHT)
		headerCell.set_deferred("custom_minimum_size", Vector2(cellWidth, HEADER_BUTTON_HEIGHT))
		headerCell.set_deferred("size", Vector2(cellWidth, HEADER_BUTTON_HEIGHT))

		if headerCell.has_signal("headerPressed"):
			headerCell.headerPressed.connect(Callable(gameplay, "onHeaderPressed"))
		elif headerCell.has_signal("header_pressed"):
			headerCell.header_pressed.connect(Callable(gameplay, "onHeaderPressed"))

	# Right spacer also keeps full header area.
	var rightSpacer := Control.new()
	rightSpacer.custom_minimum_size = Vector2(TABLE_RIGHT_PADDING, HEADER_VIEWPORT_HEIGHT)
	rightSpacer.size = Vector2(TABLE_RIGHT_PADDING, HEADER_VIEWPORT_HEIGHT)
	gameplay.headerHBox.add_child(rightSpacer)


func buildRows() -> void:
	if gameplay.rowsVBox == null:
		return

	for record in gameplay.currentRecords:
		var row = gameplay.TABLE_ROW_SCENE.instantiate()
		gameplay.rowsVBox.add_child(row)

		var recordId: String = str(record.get(RECORD_ID_KEY, ""))
		var isSelected := false

		if gameplay.selectionSystem != null:
			isSelected = gameplay.selectionSystem.isRecordIdSelected(recordId)

		row.setup(gameplay.currentColumns, record, isSelected)
		applyRowCellFont(row)

		if isSelected and gameplay.selectionSystem != null:
			if not gameplay.selectionSystem.selectedRows.has(row):
				gameplay.selectionSystem.selectedRows.append(row)

		if row.has_signal("rowSelected"):
			row.rowSelected.connect(Callable(gameplay, "onRowSelected").bind(row))
		elif row.has_signal("row_selected"):
			row.row_selected.connect(Callable(gameplay, "onRowSelected").bind(row))


func getColumnWidth(columnType: String) -> float:
	if columnType == COLUMN_TYPE_SUPER_LONG:
		return SUPER_LONG_WIDTH

	if columnType == COLUMN_TYPE_LONG:
		return LONG_WIDTH

	return NORMAL_WIDTH


func calculateTableWidth() -> float:
	var total := CHECK_HEADER_WIDTH

	for column in gameplay.currentColumns:
		var columnType := str(column.get("type", COLUMN_TYPE_NORMAL))
		total += getColumnWidth(columnType)

	return total


func onHeaderPressed(columnKey: String) -> void:
	gameplay.audioSystem.playFooterClickSound(gameplay.titleHeaderClickSound)

	if columnKey.is_empty():
		return

	var savedScrollX: float = gameplay.scrollX
	var savedScrollY: float = gameplay.scrollY

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

	rebuildTableKeepScrollAt(savedScrollX, savedScrollY)


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


func getRecordIdNumber(record: Dictionary) -> int:
	var rawId := str(record.get(RECORD_ID_KEY, ""))
	var digits := ""

	for character in rawId:
		if character >= "0" and character <= "9":
			digits += character

	if digits.is_empty():
		return 0

	return int(digits)


func rebuildTableKeepScroll() -> void:
	rebuildTableKeepScrollAt(gameplay.scrollX, gameplay.scrollY)


func rebuildTableKeepScrollAt(savedScrollX: float, savedScrollY: float) -> void:
	clearContainer(gameplay.headerHBox)
	clearContainer(gameplay.rowsVBox)

	if gameplay.selectionSystem != null:
		gameplay.selectionSystem.selectedRows.clear()

	buildHeaders()
	buildRows()

	restoreTableScrollPosition(savedScrollX, savedScrollY)

	call_deferred("restoreTableScrollPosition", savedScrollX, savedScrollY)


func restoreTableScrollPosition(savedScrollX: float, savedScrollY: float) -> void:
	gameplay.scrollX = savedScrollX
	gameplay.scrollY = savedScrollY

	if gameplay.scrollSystem != null and gameplay.scrollSystem.has_method("refreshScrollLimits"):
		gameplay.scrollSystem.refreshScrollLimits()

	gameplay.scrollX = clamp(gameplay.scrollX, 0.0, gameplay.maxScrollX)
	gameplay.scrollY = clamp(gameplay.scrollY, 0.0, gameplay.maxScrollY)

	applyCurrentScrollPosition()

	if gameplay.scrollSystem != null:
		if gameplay.scrollSystem.has_method("setupCustomScrollbarPositions"):
			gameplay.scrollSystem.setupCustomScrollbarPositions()

		if gameplay.scrollSystem.has_method("updateCustomScrollbars"):
			gameplay.scrollSystem.updateCustomScrollbars()


func applyCurrentScrollPosition() -> void:
	if gameplay.headerHBox != null:
		gameplay.headerHBox.position = Vector2(-gameplay.scrollX, 0.0)

	if gameplay.rowsVBox != null:
		gameplay.rowsVBox.position = Vector2(-gameplay.scrollX, -gameplay.scrollY)

func applyRowCellFont(row: Node) -> void:
	if row == null:
		return

	applyFontToLabelsRecursive(row)


# Applies the row font to labels recursively.
func applyFontToLabelsRecursive(node: Node) -> void:
	if node == null:
		return

	if node is Label:
		var label := node as Label
		label.add_theme_font_override("font", gameplay.ROW_CELL_FONT)

	for child in node.get_children():
		applyFontToLabelsRecursive(child)
