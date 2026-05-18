extends RefCounted

const BUTTON_NORMAL_MODULATE := Color(1, 1, 1, 1)
const BUTTON_PRESSED_MODULATE := Color(0.85, 0.85, 0.85, 1)

const BUTTON_NORMAL_SCALE := Vector2.ONE
const BUTTON_PRESSED_SCALE := Vector2(0.94, 0.94)

const BUTTON_PRESS_TIME := 0.05
const BUTTON_RELEASE_TIME := 0.10

var gameplay: Control

var activeButton: TextureButton = null
var buttonTweens := {}


# Stores the gameplay screen reference used by this search system.
func _init(gameplayOwner: Control) -> void:
	gameplay = gameplayOwner


# Prepares the search input, filter button, and clear button.
func setupSearchTools() -> void:
	setupSearchInput()
	setupSearchButton(gameplay.filterButton, Callable(self, "onFilterPressed"))
	setupSearchButton(gameplay.clearButton, Callable(self, "onClearPressed"))


# Connects the search text input.
func setupSearchInput() -> void:
	if gameplay.searchInput == null:
		push_error("SearchInput not found.")
		return

	gameplay.searchInput.focus_mode = Control.FOCUS_CLICK
	gameplay.searchInput.mouse_filter = Control.MOUSE_FILTER_STOP
	gameplay.searchInput.clear_button_enabled = false
	gameplay.searchInput.placeholder_text = ""

	var textChangedCallable := Callable(self, "onSearchTextChanged")

	if not gameplay.searchInput.text_changed.is_connected(textChangedCallable):
		gameplay.searchInput.text_changed.connect(textChangedCallable)


# Prepares one search area button.
func setupSearchButton(button: TextureButton, pressedCallback: Callable) -> void:
	if button == null:
		return

	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.modulate = BUTTON_NORMAL_MODULATE
	button.scale = BUTTON_NORMAL_SCALE
	button.pivot_offset = button.size * 0.5

	var buttonDownCallable := onSearchButtonDown.bind(button)
	var buttonUpCallable := onSearchButtonUp.bind(button)
	var mouseExitedCallable := onSearchButtonMouseExited.bind(button)

	if not button.button_down.is_connected(buttonDownCallable):
		button.button_down.connect(buttonDownCallable)

	if not button.button_up.is_connected(buttonUpCallable):
		button.button_up.connect(buttonUpCallable)

	if not button.mouse_exited.is_connected(mouseExitedCallable):
		button.mouse_exited.connect(mouseExitedCallable)

	if not button.pressed.is_connected(pressedCallback):
		button.pressed.connect(pressedCallback)


# Filters rows whenever the search text changes.
func onSearchTextChanged(_newText: String) -> void:
	applySearchFilter()


# Placeholder filter button action.
func onFilterPressed() -> void:
	if gameplay.objectiveText != null:
		gameplay.setObjectiveText("Filter options will be added later.", 44)


# Clears the search text and restores all records.
func onClearPressed() -> void:
	if gameplay.searchInput == null:
		return

	gameplay.searchInput.text = ""
	applySearchFilter()


# Applies search text to all record values.
func applySearchFilter(shouldRebuild: bool = true) -> void:
	var searchText := ""

	if gameplay.searchInput != null:
		searchText = gameplay.searchInput.text.strip_edges().to_lower()

	var filteredRecords: Array = []

	if searchText.is_empty():
		filteredRecords = gameplay.originalRecords.duplicate(true)
	else:
		for record in gameplay.originalRecords:
			if doesRecordMatchSearch(record, searchText):
				filteredRecords.append(record)

	gameplay.currentRecords = filteredRecords

	if not gameplay.activeSortColumnKey.is_empty():
		gameplay.tableSystem.sortCurrentRecordsByColumn(gameplay.activeSortColumnKey)

	gameplay.scrollX = 0.0
	gameplay.scrollY = 0.0

	if shouldRebuild:
		gameplay.rebuildTableKeepScroll()


# Checks if any value in the record contains the search text.
func doesRecordMatchSearch(record: Dictionary, searchText: String) -> bool:
	for key in record.keys():
		var valueText := str(record.get(key, "")).to_lower()

		if valueText.contains(searchText):
			return true

	return false


# Handles search button press start.
func onSearchButtonDown(button: TextureButton) -> void:
	if button == null:
		return

	activeButton = button
	animateButton(button, BUTTON_PRESSED_SCALE, BUTTON_PRESSED_MODULATE, BUTTON_PRESS_TIME)


# Handles search button release.
func onSearchButtonUp(button: TextureButton) -> void:
	if button == null:
		return

	activeButton = null
	animateButton(button, BUTTON_NORMAL_SCALE, BUTTON_NORMAL_MODULATE, BUTTON_RELEASE_TIME)


# Cancels button press when mouse exits.
func onSearchButtonMouseExited(button: TextureButton) -> void:
	if button == null:
		return

	if activeButton != button:
		return

	activeButton = null
	animateButton(button, BUTTON_NORMAL_SCALE, BUTTON_NORMAL_MODULATE, BUTTON_RELEASE_TIME)


# Animates one search button.
func animateButton(
	button: TextureButton,
	targetScale: Vector2,
	targetModulate: Color,
	duration: float
) -> void:
	if button == null:
		return

	killButtonTween(button)

	var tween := gameplay.create_tween()
	buttonTweens[button] = tween
	tween.set_parallel(true)

	tween.tween_property(
		button,
		"scale",
		targetScale,
		duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		button,
		"modulate",
		targetModulate,
		duration
	)


# Stops the active tween for one button.
func killButtonTween(button: TextureButton) -> void:
	if button == null:
		return

	if not buttonTweens.has(button):
		return

	var tween: Tween = buttonTweens[button]

	if tween != null and tween.is_valid():
		tween.kill()

	buttonTweens.erase(button)