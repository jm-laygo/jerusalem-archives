extends RefCounted

const DEFAULT_SELECTION_LIMIT := 1
const DEFAULT_SELECTION_MODE := "single"

const SELECTED_ID_BOX_SIZE := Vector2(170.0, 86.0)
const SELECTED_ID_FONT_SIZE := 40
const SELECTED_ID_TEXT_COLOR := Color(0.972549, 0.909804, 0.74902, 1.0)
const SELECTED_ID_TEXT_SHADOW_COLOR := Color(0, 0, 0, 0.85)
const SELECTED_ID_BOX_SPACING := 16

var gameplay: Control

var selectionMode: String = DEFAULT_SELECTION_MODE
var selectionLimit: int = DEFAULT_SELECTION_LIMIT
var selectedRecords: Array = []
var selectedRows: Array = []


# Stores the gameplay screen reference used by this selection system.
func _init(gameplayOwner: Control) -> void:
	gameplay = gameplayOwner


# Prepares the selected ID display area.
func setupSelectionDisplay() -> void:
	if gameplay.selectedPanel != null:
		gameplay.selectedPanel.visible = true
		gameplay.selectedPanel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if gameplay.selectedCountLabel != null:
		gameplay.selectedCountLabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gameplay.selectedCountLabel.text = getSelectedCountText()

	if gameplay.selectedIdScroll != null:
		gameplay.selectedIdScroll.mouse_filter = Control.MOUSE_FILTER_PASS
		gameplay.selectedIdScroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		gameplay.selectedIdScroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	if gameplay.selectedIdHBox != null:
		gameplay.selectedIdHBox.add_theme_constant_override("separation", SELECTED_ID_BOX_SPACING)
		gameplay.selectedIdHBox.alignment = BoxContainer.ALIGNMENT_CENTER
		gameplay.selectedIdHBox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	updateSelectedDisplay()


# Reads selection rules from the current level.
func configureFromLevel(levelData: Dictionary) -> void:
	selectionMode = str(levelData.get("selection_mode", DEFAULT_SELECTION_MODE)).to_lower()
	selectionLimit = int(levelData.get("selection_limit", DEFAULT_SELECTION_LIMIT))

	if selectionMode != "multiple":
		selectionMode = "single"

	if selectionLimit <= 0:
		selectionLimit = DEFAULT_SELECTION_LIMIT

	if selectionMode == "single":
		selectionLimit = 1


# Clears all selected rows and selected ID boxes.
func resetSelection() -> void:
	for row in selectedRows:
		if row != null and is_instance_valid(row) and row.has_method("setSelected"):
			row.setSelected(false)

	selectedRecords.clear()
	selectedRows.clear()

	gameplay.selectedRecord = {}
	gameplay.selectedRow = null

	updateSelectedDisplay()


# Toggles row selection.
func toggleRowSelection(record: Dictionary, row: Button) -> void:
	if row == null:
		return

	if isRowSelected(row):
		deselectRow(row)
		updateSelectedDisplay()
		return

	if selectionMode == "single":
		clearCurrentSelection()
		selectRow(record, row)
		updateSelectedDisplay()
		return

	if selectedRows.size() >= selectionLimit:
		if gameplay.audioSystem != null:
			gameplay.audioSystem.playFooterClickSound(gameplay.checkIncorrectSound)
		return

	selectRow(record, row)
	updateSelectedDisplay()


# Selects one row and stores its record.
func selectRow(record: Dictionary, row: Button) -> void:
	selectedRecords.append(record)
	selectedRows.append(row)

	if row.has_method("setSelected"):
		row.setSelected(true)

	gameplay.selectedRecord = record
	gameplay.selectedRow = row


# Deselects one row and removes its record.
func deselectRow(row: Button) -> void:
	var rowIndex: int = selectedRows.find(row)

	if rowIndex == -1:
		return

	if row.has_method("setSelected"):
		row.setSelected(false)

	selectedRows.remove_at(rowIndex)
	selectedRecords.remove_at(rowIndex)

	if selectedRecords.is_empty():
		gameplay.selectedRecord = {}
		gameplay.selectedRow = null
	else:
		gameplay.selectedRecord = selectedRecords[selectedRecords.size() - 1]
		gameplay.selectedRow = selectedRows[selectedRows.size() - 1]


# Clears the current selected row list.
func clearCurrentSelection() -> void:
	for row in selectedRows:
		if row != null and is_instance_valid(row) and row.has_method("setSelected"):
			row.setSelected(false)

	selectedRecords.clear()
	selectedRows.clear()

	gameplay.selectedRecord = {}
	gameplay.selectedRow = null


# Checks if a row is currently selected.
func isRowSelected(row: Button) -> bool:
	return selectedRows.has(row)


# Checks if a record ID is currently selected.
func isRecordIdSelected(recordId: String) -> bool:
	for record in selectedRecords:
		if str(record.get("record_id", "")) == recordId:
			return true

	return false


# Returns all selected record IDs.
func getSelectedRecordIds() -> Array[String]:
	var selectedIds: Array[String] = []

	for record in selectedRecords:
		var recordId: String = str(record.get("record_id", ""))
		selectedIds.append(recordId)

	return selectedIds


# Checks if there is at least one selected record.
func hasSelection() -> bool:
	return not selectedRecords.is_empty()


# Updates the selected count and selected ID boxes.
func updateSelectedDisplay() -> void:
	updateSelectedCountLabel()
	rebuildSelectedIdBoxes()


# Builds the selected count text.
func getSelectedCountText() -> String:
	if selectionMode == "multiple":
		return "SELECTED %s / %s" % [selectedRecords.size(), selectionLimit]

	return "SELECTED %s" % selectedRecords.size()


# Updates the selected count label.
func updateSelectedCountLabel() -> void:
	if gameplay.selectedCountLabel == null:
		return

	gameplay.selectedCountLabel.text = getSelectedCountText()


# Rebuilds selected ID boxes inside the horizontal scroll area.
func rebuildSelectedIdBoxes() -> void:
	if gameplay.selectedIdHBox == null:
		return

	for child in gameplay.selectedIdHBox.get_children():
		child.queue_free()

	for record in selectedRecords:
		var recordId: String = str(record.get("record_id", ""))
		var selectedBox: Control = createSelectedIdBox(recordId)
		gameplay.selectedIdHBox.add_child(selectedBox)

	call_deferred("refreshSelectedIdLayout")


# Refreshes the layout so the IDs stay centered when there are only a few.
func refreshSelectedIdLayout() -> void:
	if gameplay.selectedIdHBox == null or gameplay.selectedIdScroll == null:
		return

	var contentWidth: float = getSelectedBoxesContentWidth()
	var viewportWidth: float = gameplay.selectedIdScroll.size.x

	gameplay.selectedIdHBox.custom_minimum_size = Vector2(
		max(contentWidth, viewportWidth),
		SELECTED_ID_BOX_SIZE.y
	)

	gameplay.selectedIdScroll.scroll_horizontal = 0


# Calculates the total width needed by all selected ID boxes.
func getSelectedBoxesContentWidth() -> float:
	if selectedRecords.is_empty():
		return 0.0

	var boxWidth: float = SELECTED_ID_BOX_SIZE.x
	var totalSpacing: float = SELECTED_ID_BOX_SPACING * max(selectedRecords.size() - 1, 0)

	return (boxWidth * selectedRecords.size()) + totalSpacing


# Creates one selected ID box with centered text.
func createSelectedIdBox(recordId: String) -> Control:
	var box := TextureRect.new()
	box.custom_minimum_size = SELECTED_ID_BOX_SIZE
	box.size = SELECTED_ID_BOX_SIZE
	box.texture = gameplay.SELECTED_ID_TEXTURE
	box.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	box.stretch_mode = TextureRect.STRETCH_SCALE
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var label := Label.new()
	label.name = "SelectedIdLabel"
	label.set_anchors_preset(Control.PRESET_FULL_RECT)

	label.offset_left = 8.0
	label.offset_top = 4.0
	label.offset_right = -8.0
	label.offset_bottom = -6.0

	label.text = recordId
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	label.add_theme_color_override("font_color", SELECTED_ID_TEXT_COLOR)
	label.add_theme_color_override("font_shadow_color", SELECTED_ID_TEXT_SHADOW_COLOR)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_font_size_override("font_size", SELECTED_ID_FONT_SIZE)

	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	box.add_child(label)

	return box