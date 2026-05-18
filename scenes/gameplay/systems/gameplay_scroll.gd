extends RefCounted

const TABLE_WIDTH := 1080.0
const FOOTER_HEIGHT := 217.0

const HEADER_HEIGHT := 120.0
const ROWS_Y := 374.0

const H_SCROLL_Y := 1090.0
const H_SCROLL_HEIGHT := 20.0
const H_SCROLL_TRACK_PADDING := 10.0
const H_SCROLL_SLIDER_Y_OFFSET := 4.0
const H_SCROLL_SLIDER_HEIGHT := 15.0

const V_SCROLL_X := 1060.0
const V_SCROLL_WIDTH := 20.0
const V_SCROLL_SLIDER_X_OFFSET := -1.0
const V_SCROLL_SLIDER_WIDTH := 26.0

const MIN_SCROLLBAR_RATIO := 0.08
const SCROLL_WHEEL_SPEED := 90.0
const DRAG_LOCK_THRESHOLD := 14.0

const DRAG_AXIS_NONE := ""
const DRAG_AXIS_HORIZONTAL := "horizontal"
const DRAG_AXIS_VERTICAL := "vertical"

var gameplay: Control


# Stores the gameplay screen reference used by this scroll system.
func _init(gameplayOwner: Control) -> void:
	gameplay = gameplayOwner


# Handles mouse wheel, mouse drag, touch, and screen drag scrolling.
func handleInput(event: InputEvent) -> void:
	if gameplay.pauseOverlay != null and is_instance_valid(gameplay.pauseOverlay):
		return

	if gameplay.tableRowsViewport == null or gameplay.tableHeaderViewport == null:
		return

	var tableRect: Rect2 = gameplay.tableRowsViewport.get_global_rect()
	var headerRect: Rect2 = gameplay.tableHeaderViewport.get_global_rect()

	if event is InputEventMouseButton:
		handleMouseButtonInput(event, tableRect, headerRect)

	if event is InputEventMouseMotion and gameplay.isDraggingTable:
		handleMouseDragInput()

	if event is InputEventScreenTouch:
		handleScreenTouchInput(event, tableRect, headerRect)

	if event is InputEventScreenDrag and gameplay.isDraggingTable:
		handleScreenDragInput(event)


# Handles mouse press, release, and wheel input.
func handleMouseButtonInput(
	event: InputEventMouseButton,
	tableRect: Rect2,
	headerRect: Rect2
) -> void:
	var mousePosition: Vector2 = gameplay.get_global_mouse_position()
	var isInsideTable := tableRect.has_point(mousePosition)
	var isInsideHeader := headerRect.has_point(mousePosition)

	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and (isInsideTable or isInsideHeader):
			gameplay.isDraggingTable = true
			gameplay.lastDragGlobalPosition = mousePosition
			gameplay.dragAxis = DRAG_AXIS_NONE
		elif not event.pressed:
			gameplay.isDraggingTable = false
			gameplay.dragAxis = DRAG_AXIS_NONE

	if not event.pressed:
		return

	if not isInsideTable and not isInsideHeader:
		return

	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		if Input.is_key_pressed(KEY_SHIFT):
			scrollTable(Vector2(-SCROLL_WHEEL_SPEED, 0.0))
		else:
			scrollTable(Vector2(0.0, -SCROLL_WHEEL_SPEED))

	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		if Input.is_key_pressed(KEY_SHIFT):
			scrollTable(Vector2(SCROLL_WHEEL_SPEED, 0.0))
		else:
			scrollTable(Vector2(0.0, SCROLL_WHEEL_SPEED))


# Handles mouse drag table scrolling.
func handleMouseDragInput() -> void:
	var mousePosition: Vector2 = gameplay.get_global_mouse_position()
	var rawDelta: Vector2 = gameplay.lastDragGlobalPosition - mousePosition

	gameplay.lastDragGlobalPosition = mousePosition
	scrollTable(getLockedDragDelta(rawDelta))


# Handles touch press and release for table scrolling.
func handleScreenTouchInput(
	event: InputEventScreenTouch,
	tableRect: Rect2,
	headerRect: Rect2
) -> void:
	var touchPosition: Vector2 = event.position
	var isInsideTable := tableRect.has_point(touchPosition)
	var isInsideHeader := headerRect.has_point(touchPosition)

	if event.pressed and (isInsideTable or isInsideHeader):
		gameplay.isDraggingTable = true
		gameplay.lastDragGlobalPosition = touchPosition
		gameplay.dragAxis = DRAG_AXIS_NONE
	else:
		gameplay.isDraggingTable = false
		gameplay.dragAxis = DRAG_AXIS_NONE


# Handles touch drag table scrolling.
func handleScreenDragInput(event: InputEventScreenDrag) -> void:
	var rawTouchDelta := Vector2(-event.relative.x, -event.relative.y)
	scrollTable(getLockedDragDelta(rawTouchDelta))


# Locks drag scrolling to either horizontal or vertical movement.
func getLockedDragDelta(rawDelta: Vector2) -> Vector2:
	if gameplay.dragAxis == DRAG_AXIS_NONE:
		if abs(rawDelta.x) < DRAG_LOCK_THRESHOLD and abs(rawDelta.y) < DRAG_LOCK_THRESHOLD:
			return Vector2.ZERO

		if abs(rawDelta.x) > abs(rawDelta.y):
			gameplay.dragAxis = DRAG_AXIS_HORIZONTAL
		else:
			gameplay.dragAxis = DRAG_AXIS_VERTICAL

	if gameplay.dragAxis == DRAG_AXIS_HORIZONTAL:
		return Vector2(rawDelta.x, 0.0)

	return Vector2(0.0, rawDelta.y)


# Updates scroll values and applies them to the table.
func scrollTable(delta: Vector2) -> void:
	gameplay.scrollX = clamp(gameplay.scrollX + delta.x, 0.0, gameplay.maxScrollX)
	gameplay.scrollY = clamp(gameplay.scrollY + delta.y, 0.0, gameplay.maxScrollY)

	applyTableScroll()


# Applies current scroll values to table header and rows.
func applyTableScroll() -> void:
	if gameplay.headerHBox != null:
		gameplay.headerHBox.position = Vector2(-gameplay.scrollX, 0.0)

	if gameplay.rowsVBox != null:
		gameplay.rowsVBox.position = Vector2(-gameplay.scrollX, -gameplay.scrollY)

	updateCustomScrollbars()


# Recalculates content size, viewport size, scroll limits, and scrollbar state.
func refreshScrollLimits() -> void:
	if gameplay.tableRowsViewport == null or gameplay.rowsVBox == null:
		return

	gameplay.tableContentWidth = gameplay.tableSystem.calculateTableWidth()
	gameplay.tableContentHeight = getRealRowsContentHeight()

	if gameplay.headerHBox != null:
		gameplay.headerHBox.custom_minimum_size = Vector2(gameplay.tableContentWidth, HEADER_HEIGHT)
		gameplay.headerHBox.size = Vector2(gameplay.tableContentWidth, HEADER_HEIGHT)

	if gameplay.rowsVBox != null:
		gameplay.rowsVBox.custom_minimum_size = Vector2(gameplay.tableContentWidth, gameplay.tableContentHeight)
		gameplay.rowsVBox.size = Vector2(gameplay.tableContentWidth, gameplay.tableContentHeight)

	var screenHeight: float = gameplay.get_viewport_rect().size.y
	var rowsAbsoluteY: float = gameplay.tableRowsViewport.get_global_rect().position.y
	var footerAbsoluteY: float = screenHeight - FOOTER_HEIGHT
	var availableViewportHeight: float = footerAbsoluteY - rowsAbsoluteY
	var dynamicViewportHeight: float = minf(availableViewportHeight, gameplay.tableContentHeight)

	gameplay.tableRowsViewport.size = Vector2(TABLE_WIDTH, dynamicViewportHeight)
	gameplay.tableRowsViewport.custom_minimum_size = Vector2(TABLE_WIDTH, dynamicViewportHeight)

	gameplay.maxScrollX = max(0.0, gameplay.tableContentWidth - gameplay.tableRowsViewport.size.x)
	gameplay.maxScrollY = max(0.0, gameplay.tableContentHeight - gameplay.tableRowsViewport.size.y)

	gameplay.scrollX = clamp(gameplay.scrollX, 0.0, gameplay.maxScrollX)
	gameplay.scrollY = clamp(gameplay.scrollY, 0.0, gameplay.maxScrollY)

	applyTableScroll()
	setupCustomScrollbarPositions()
	updateCustomScrollbars()


# Calculates the real height of all row controls.
func getRealRowsContentHeight() -> float:
	if gameplay.rowsVBox == null:
		return 0.0

	var totalHeight := 0.0

	for child in gameplay.rowsVBox.get_children():
		if child is Control:
			totalHeight += child.custom_minimum_size.y

	return totalHeight


# Sets initial custom scrollbar positions and visibility.
func setupCustomScrollbarPositions() -> void:
	setupHorizontalScrollbarPosition()
	setupVerticalScrollbarPosition()


# Sets the horizontal scrollbar base position.
func setupHorizontalScrollbarPosition() -> void:
	if gameplay.horizontalScrollBackground != null:
		gameplay.horizontalScrollBackground.visible = true
		gameplay.horizontalScrollBackground.position = Vector2(0.0, H_SCROLL_Y)
		gameplay.horizontalScrollBackground.size = Vector2(TABLE_WIDTH, H_SCROLL_HEIGHT)
		gameplay.horizontalScrollBackground.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gameplay.horizontalScrollBackground.move_to_front()

	if gameplay.horizontalScrollSlider != null:
		gameplay.horizontalScrollSlider.visible = true
		gameplay.horizontalScrollSlider.position = Vector2(
			H_SCROLL_TRACK_PADDING,
			H_SCROLL_Y + H_SCROLL_SLIDER_Y_OFFSET
		)
		gameplay.horizontalScrollSlider.size = Vector2(200.0, H_SCROLL_SLIDER_HEIGHT)
		gameplay.horizontalScrollSlider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gameplay.horizontalScrollSlider.move_to_front()


# Sets the vertical scrollbar base position.
func setupVerticalScrollbarPosition() -> void:
	if gameplay.verticalScrollBackground != null:
		gameplay.verticalScrollBackground.visible = true
		gameplay.verticalScrollBackground.position = Vector2(V_SCROLL_X, ROWS_Y)

		if gameplay.tableRowsViewport != null:
			gameplay.verticalScrollBackground.size = Vector2(V_SCROLL_WIDTH, gameplay.tableRowsViewport.size.y)

		gameplay.verticalScrollBackground.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gameplay.verticalScrollBackground.move_to_front()

	if gameplay.verticalScrollSlider != null:
		gameplay.verticalScrollSlider.visible = true
		gameplay.verticalScrollSlider.position = Vector2(V_SCROLL_X + V_SCROLL_SLIDER_X_OFFSET, ROWS_Y)
		gameplay.verticalScrollSlider.size = Vector2(V_SCROLL_SLIDER_WIDTH, 85.0)
		gameplay.verticalScrollSlider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gameplay.verticalScrollSlider.move_to_front()


# Updates both custom scrollbars.
func updateCustomScrollbars() -> void:
	updateHorizontalScrollbar()
	updateVerticalScrollbar()
	moveCustomScrollbarsToFront()


# Updates the horizontal scrollbar slider size and position.
func updateHorizontalScrollbar() -> void:
	if (
		gameplay.horizontalScrollBackground == null
		or gameplay.horizontalScrollSlider == null
		or gameplay.tableRowsViewport == null
	):
		return

	gameplay.horizontalScrollBackground.visible = true
	gameplay.horizontalScrollBackground.position = Vector2(0.0, H_SCROLL_Y)
	gameplay.horizontalScrollBackground.size = Vector2(TABLE_WIDTH, H_SCROLL_HEIGHT)
	gameplay.horizontalScrollBackground.move_to_front()

	var trackLeft: float = gameplay.horizontalScrollBackground.position.x + H_SCROLL_TRACK_PADDING
	var trackWidth: float = gameplay.horizontalScrollBackground.size.x - (H_SCROLL_TRACK_PADDING * 2.0)

	if gameplay.maxScrollX <= 0.0:
		gameplay.horizontalScrollSlider.visible = false
		return

	gameplay.horizontalScrollSlider.visible = true

	var visibleRatio: float = clampf(
		gameplay.tableRowsViewport.size.x / gameplay.tableContentWidth,
		MIN_SCROLLBAR_RATIO,
		1.0
	)

	var sliderWidth: float = trackWidth * visibleRatio
	var progress: float = gameplay.scrollX / gameplay.maxScrollX
	var sliderX: float = trackLeft + ((trackWidth - sliderWidth) * progress)

	gameplay.horizontalScrollSlider.position.x = sliderX
	gameplay.horizontalScrollSlider.position.y = H_SCROLL_Y + H_SCROLL_SLIDER_Y_OFFSET
	gameplay.horizontalScrollSlider.size.x = sliderWidth
	gameplay.horizontalScrollSlider.size.y = H_SCROLL_SLIDER_HEIGHT
	gameplay.horizontalScrollSlider.move_to_front()


# Updates the vertical scrollbar slider size and position.
func updateVerticalScrollbar() -> void:
	if (
		gameplay.verticalScrollBackground == null
		or gameplay.verticalScrollSlider == null
		or gameplay.tableRowsViewport == null
	):
		return

	gameplay.verticalScrollBackground.visible = true
	gameplay.verticalScrollBackground.position = Vector2(V_SCROLL_X, ROWS_Y)
	gameplay.verticalScrollBackground.size = Vector2(V_SCROLL_WIDTH, gameplay.tableRowsViewport.size.y)
	gameplay.verticalScrollBackground.move_to_front()

	var trackTop: float = gameplay.verticalScrollBackground.position.y
	var trackHeight: float = gameplay.verticalScrollBackground.size.y

	if gameplay.maxScrollY <= 0.0:
		gameplay.verticalScrollSlider.visible = false
		return

	gameplay.verticalScrollSlider.visible = true

	var visibleRatio: float = clampf(
		gameplay.tableRowsViewport.size.y / gameplay.tableContentHeight,
		MIN_SCROLLBAR_RATIO,
		1.0
	)

	var sliderHeight: float = trackHeight * visibleRatio
	var progress: float = gameplay.scrollY / gameplay.maxScrollY
	var sliderY: float = trackTop + ((trackHeight - sliderHeight) * progress)

	gameplay.verticalScrollSlider.position.x = V_SCROLL_X + V_SCROLL_SLIDER_X_OFFSET
	gameplay.verticalScrollSlider.position.y = sliderY
	gameplay.verticalScrollSlider.size.x = V_SCROLL_SLIDER_WIDTH
	gameplay.verticalScrollSlider.size.y = sliderHeight
	gameplay.verticalScrollSlider.move_to_front()


# Moves all custom scrollbar nodes above the table.
func moveCustomScrollbarsToFront() -> void:
	if gameplay.horizontalScrollBackground != null:
		gameplay.horizontalScrollBackground.move_to_front()

	if gameplay.horizontalScrollSlider != null:
		gameplay.horizontalScrollSlider.move_to_front()

	if gameplay.verticalScrollBackground != null:
		gameplay.verticalScrollBackground.move_to_front()

	if gameplay.verticalScrollSlider != null:
		gameplay.verticalScrollSlider.move_to_front()
