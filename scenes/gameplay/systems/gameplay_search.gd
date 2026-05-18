extends RefCounted

const SEARCH_BAR_NORMAL_TEXTURE: Texture2D = preload("res://assets/interface/search/search_bar.png")
const SEARCH_BAR_PRESSED_TEXTURE: Texture2D = preload("res://assets/interface/search/search_bar_pressed.png")
const GENERIC_SELECT_SOUND: AudioStream = preload("res://assets/sounds/ui/ui_generic_select.wav")

const BUTTON_NORMAL_MODULATE := Color(1, 1, 1, 1)
const BUTTON_PRESSED_MODULATE := Color(0.85, 0.85, 0.85, 1)

const BUTTON_NORMAL_SCALE := Vector2.ONE
const BUTTON_PRESSED_SCALE := Vector2(0.94, 0.94)

const BUTTON_PRESS_TIME := 0.05
const BUTTON_RELEASE_TIME := 0.10

var gameplay: Control

var selectPlayer: AudioStreamPlayer
var activeButton: TextureButton = null
var buttonTweens := {}

var isSearchFocused := false


# Stores the gameplay screen reference used by this search system.
func _init(gameplayOwner: Control) -> void:
	gameplay = gameplayOwner


# Prepares the search input, filter button, and clear button.
func setupSearchTools() -> void:
	setupSelectSound()
	setupSearchBarClick()
	setupSearchInput()
	setupSearchButton(gameplay.filterButton, Callable(self, "onFilterPressed"))
	setupSearchButton(gameplay.clearButton, Callable(self, "onClearPressed"))
	restoreSearchBarTexture()


# Creates the UI select sound player.
func setupSelectSound() -> void:
	selectPlayer = AudioStreamPlayer.new()
	selectPlayer.stream = GENERIC_SELECT_SOUND
	selectPlayer.bus = "Master"
	gameplay.add_child(selectPlayer)

# Makes the full search bar clickable, not only the LineEdit area.
func setupSearchBarClick() -> void:
	if gameplay.searchBar == null:
		return

	gameplay.searchBar.mouse_filter = Control.MOUSE_FILTER_STOP

	var guiInputCallable := Callable(self, "onSearchBarGuiInput")

	if not gameplay.searchBar.gui_input.is_connected(guiInputCallable):
		gameplay.searchBar.gui_input.connect(guiInputCallable)

# Focuses the search input when the search bar background is clicked.
func onSearchBarGuiInput(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
			return

		focusSearchInput()
		gameplay.get_viewport().set_input_as_handled()

	if event is InputEventScreenTouch:
		if not event.pressed:
			return

		focusSearchInput()
		gameplay.get_viewport().set_input_as_handled()

# Applies focus, pressed texture, and select sound to the search input.
func focusSearchInput() -> void:
	if gameplay.searchInput == null:
		return

	playSelectSound()
	applySearchBarPressedTexture()
	gameplay.searchInput.grab_focus()

# Connects the search text input.
func setupSearchInput() -> void:
	if gameplay.searchInput == null:
		push_error("SearchInput not found.")
		return

	gameplay.searchInput.focus_mode = Control.FOCUS_CLICK
	gameplay.searchInput.mouse_filter = Control.MOUSE_FILTER_STOP
	gameplay.searchInput.clear_button_enabled = false

	var textChangedCallable := Callable(self, "onSearchTextChanged")
	var focusEnteredCallable := Callable(self, "onSearchFocusEntered")
	var focusExitedCallable := Callable(self, "onSearchFocusExited")
	var guiInputCallable := Callable(self, "onSearchInputGuiInput")

	if not gameplay.searchInput.text_changed.is_connected(textChangedCallable):
		gameplay.searchInput.text_changed.connect(textChangedCallable)

	if not gameplay.searchInput.focus_entered.is_connected(focusEnteredCallable):
		gameplay.searchInput.focus_entered.connect(focusEnteredCallable)

	if not gameplay.searchInput.focus_exited.is_connected(focusExitedCallable):
		gameplay.searchInput.focus_exited.connect(focusExitedCallable)

	if not gameplay.searchInput.gui_input.is_connected(guiInputCallable):
		gameplay.searchInput.gui_input.connect(guiInputCallable)


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


# Handles outside clicks so search focus and pressed texture reset properly.
func handleInput(event: InputEvent) -> void:
	if gameplay.searchInput == null:
		return

	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
			return

		if isPointerInsideSearchTools(gameplay.get_global_mouse_position()):
			return

		releaseSearchFocus()

	elif event is InputEventScreenTouch:
		if not event.pressed:
			return

		if isPointerInsideSearchTools(event.position):
			return

		releaseSearchFocus()


# Checks whether pointer is inside the search bar or search buttons.
func isPointerInsideSearchTools(pointerPosition: Vector2) -> bool:
	if gameplay.searchBar != null and gameplay.searchBar.get_global_rect().has_point(pointerPosition):
		return true

	if gameplay.searchButtons != null and gameplay.searchButtons.get_global_rect().has_point(pointerPosition):
		return true

	return false


# Forces search input to lose focus and restores the normal bar texture.
func releaseSearchFocus() -> void:
	if gameplay.searchInput != null:
		gameplay.searchInput.release_focus()

	isSearchFocused = false
	restoreSearchBarTexture()


# Re-applies pressed search bar texture when the input is clicked.
func onSearchInputGuiInput(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			focusSearchInput()

	if event is InputEventScreenTouch and event.pressed:
		focusSearchInput()


# Applies pressed search bar texture and plays select sound.
func onSearchFocusEntered() -> void:
	if isSearchFocused:
		return

	isSearchFocused = true
	playSelectSound()
	applySearchBarPressedTexture()


# Restores the normal search bar texture.
func onSearchFocusExited() -> void:
	isSearchFocused = false
	restoreSearchBarTexture()


# Changes search bar to pressed texture.
func applySearchBarPressedTexture() -> void:
	if gameplay.searchBar != null:
		gameplay.searchBar.texture = SEARCH_BAR_PRESSED_TEXTURE


# Restores search bar normal texture.
func restoreSearchBarTexture() -> void:
	if gameplay.searchBar != null:
		gameplay.searchBar.texture = SEARCH_BAR_NORMAL_TEXTURE


# Filters rows whenever the search text changes.
func onSearchTextChanged(_newText: String) -> void:
	applySearchFilter()


# Placeholder filter button action.
func onFilterPressed() -> void:
	playSelectSound()
	releaseSearchFocus()

	if gameplay.objectiveText != null:
		gameplay.setObjectiveText("Filter options will be added later.", 44)


# Clears the search text, selected records, and restores all records.
func onClearPressed() -> void:
	playSelectSound()
	releaseSearchFocus()

	if gameplay.searchInput != null:
		gameplay.searchInput.text = ""

	if gameplay.selectionSystem != null:
		gameplay.selectionSystem.resetSelection()

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


# Plays generic select sound.
func playSelectSound() -> void:
	if selectPlayer == null:
		return

	selectPlayer.stop()
	selectPlayer.play()