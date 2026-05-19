extends Control

const GameplayAudio = preload("res://scenes/gameplay/systems/gameplay_audio.gd")
const GameplayLayout = preload("res://scenes/gameplay/systems/gameplay_layout.gd")
const GameplayFooter = preload("res://scenes/gameplay/systems/gameplay_footer.gd")
const GameplayHud = preload("res://scenes/gameplay/systems/gameplay_hud.gd")
const GameplayTable = preload("res://scenes/gameplay/systems/gameplay_table.gd")
const GameplayScroll = preload("res://scenes/gameplay/systems/gameplay_scroll.gd")
const GameplayPause = preload("res://scenes/gameplay/systems/gameplay_pause.gd")
const GameplayRules = preload("res://scenes/gameplay/systems/gameplay_rules.gd")
const GameplaySearch = preload("res://scenes/gameplay/systems/gameplay_search.gd")
const GameplaySelection = preload("res://scenes/gameplay/systems/gameplay_selection.gd")
const LevelRepository = preload("res://scripts/database/level_repository.gd")


const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu/main_menu.tscn"
const START_GAMEPLAY_SOUND: AudioStream = preload("res://assets/sounds/sfx/sfx_start_gameplay.wav")

const HEADER_CELL_SCENE := preload("res://scenes/gameplay/components/header_cell/header_cell.tscn")
const TABLE_ROW_SCENE := preload("res://scenes/gameplay/components/table_row/table_row.tscn")
const PAUSE_OVERLAY_SCENE := preload("res://scenes/gameplay/components/pause/pause_overlay.tscn")

const STAR_FILLED_TEXTURE: Texture2D = preload("res://assets/interface/icons/icon_star.png")
const STAR_EMPTY_TEXTURE: Texture2D = preload("res://assets/interface/icons/icon_empty_star.png")

const DESIGN_WIDTH := 1080.0
const FOOTER_HEIGHT := 217.0

const SELECTED_ID_TEXTURE: Texture2D = preload("res://assets/interface/ui/level_gameplay/ui_selected_id.png")

const INFO_POPUP_SCENE := preload("res://scenes/gameplay/components/info_popup/info_popup.tscn")
const HINT_POPUP_SCENE := preload("res://scenes/gameplay/components/hint_popup/hint_popup.tscn")

const RESULT_POPUP_SCENE := preload("res://scenes/gameplay/components/result_popup/result_popup.tscn")
const TRANSITION_FADE_DURATION := 0.35

const ROW_CELL_FONT: FontFile = preload("res://assets/fonts/Fondamento/Fondamento-Regular.ttf")

const ENABLED_BUTTON_COLOR := Color(1, 1, 1, 1)
const DISABLED_BUTTON_COLOR := Color(0.45, 0.45, 0.45, 0.65)
const MAX_HINT_COUNT := 4


@onready var header: TextureRect = get_node_or_null("Header") as TextureRect
@onready var headerLevel: TextureRect = get_node_or_null("HeaderLevel") as TextureRect
@onready var headerObjective: TextureRect = get_node_or_null("HeaderObjective") as TextureRect
@onready var dataHeader: TextureRect = get_node_or_null("DataHeader") as TextureRect
@onready var searchBar: TextureRect = get_node_or_null("SearchBar") as TextureRect
@onready var searchButtons: Control = get_node_or_null("SearchButtons") as Control
@onready var footer: TextureRect = get_node_or_null("Footer") as TextureRect

@onready var levelText: Label = get_node_or_null("HeaderLevel/LevelText") as Label
@onready var objectiveText: Label = get_node_or_null("HeaderObjective/ObjectiveText") as Label
@onready var livesIcon: TextureRect = get_node_or_null("Header/HudLayer/LivesIcon") as TextureRect
@onready var livesText: Label = get_node_or_null("Header/HudLayer/LivesText") as Label
@onready var timeText: Label = get_node_or_null("Header/HudLayer/TimeText") as Label

@onready var starLeft: TextureRect = get_node_or_null("Header/HudLayer/EmptyStars3") as TextureRect
@onready var starMiddle: TextureRect = get_node_or_null("Header/HudLayer/EmptyStars2") as TextureRect
@onready var starRight: TextureRect = get_node_or_null("Header/HudLayer/EmptyStars") as TextureRect

@onready var pauseButton: Control = getPauseButtonNode()

@onready var pauseClickSound: AudioStreamPlayer = get_node_or_null("PauseClickSound") as AudioStreamPlayer
@onready var pauseMenuClickSound: AudioStreamPlayer = get_node_or_null("PauseMenuClickSound") as AudioStreamPlayer
@onready var hintClickSound: AudioStreamPlayer = get_node_or_null("HintClickSound") as AudioStreamPlayer
@onready var checkCorrectSound: AudioStreamPlayer = get_node_or_null("CheckCorrectSound") as AudioStreamPlayer
@onready var checkIncorrectSound: AudioStreamPlayer = get_node_or_null("CheckIncorrectSound") as AudioStreamPlayer
@onready var infoClickSound: AudioStreamPlayer = get_node_or_null("InfoClickSound") as AudioStreamPlayer
@onready var rowClickSound: AudioStreamPlayer = get_node_or_null("RowClickSound") as AudioStreamPlayer
@onready var titleHeaderClickSound: AudioStreamPlayer = get_node_or_null("TitleHeaderClickSound") as AudioStreamPlayer
@onready var startGameplaySound: AudioStreamPlayer = get_node_or_null("StartGameplaySound") as AudioStreamPlayer

@onready var hintButton: TextureButton = get_node_or_null("Footer/FooterButtons/HintButton") as TextureButton
@onready var checkButton: TextureButton = get_node_or_null("Footer/FooterButtons/CheckButton") as TextureButton
@onready var infoButton: TextureButton = get_node_or_null("Footer/FooterButtons/InfoButton") as TextureButton

@onready var hintContent: HBoxContainer = get_node_or_null("Footer/FooterButtons/HintButton/HintContent") as HBoxContainer
@onready var checkContent: HBoxContainer = get_node_or_null("Footer/FooterButtons/CheckButton/CheckContent") as HBoxContainer
@onready var infoContent: HBoxContainer = get_node_or_null("Footer/FooterButtons/InfoButton/InfoContent") as HBoxContainer

@onready var hintLabelMargin: MarginContainer = get_node_or_null("Footer/FooterButtons/HintButton/HintContent/HintLabelMargin") as MarginContainer
@onready var checkLabelMargin: MarginContainer = get_node_or_null("Footer/FooterButtons/CheckButton/CheckContent/CheckLabelMargin") as MarginContainer
@onready var infoLabelMargin: MarginContainer = get_node_or_null("Footer/FooterButtons/InfoButton/InfoContent/InfoLabelMargin") as MarginContainer

@onready var hintIcon: TextureRect = get_node_or_null("Footer/FooterButtons/HintButton/HintContent/HintIcon") as TextureRect
@onready var checkIcon: TextureRect = get_node_or_null("Footer/FooterButtons/CheckButton/CheckContent/CheckIcon") as TextureRect
@onready var infoIcon: TextureRect = get_node_or_null("Footer/FooterButtons/InfoButton/InfoContent/InfoIcon") as TextureRect

@onready var hintLabel: Label = get_node_or_null("Footer/FooterButtons/HintButton/HintContent/HintLabelMargin/HintLabel") as Label
@onready var checkLabel: Label = get_node_or_null("Footer/FooterButtons/CheckButton/CheckContent/CheckLabelMargin/CheckLabel") as Label
@onready var infoLabel: Label = get_node_or_null("Footer/FooterButtons/InfoButton/InfoContent/InfoLabelMargin/InfoLabel") as Label

@onready var horizontalScrollBackground: TextureRect = get_node_or_null("DataHeader/HScrollBarBackground") as TextureRect
@onready var horizontalScrollSlider: TextureRect = get_node_or_null("DataHeader/HScrollBarSlider") as TextureRect
@onready var verticalScrollBackground: TextureRect = get_node_or_null("DataHeader/ScrollBarBackground") as TextureRect
@onready var verticalScrollSlider: TextureRect = get_node_or_null("DataHeader/ScrollBarSlider") as TextureRect

@onready var searchInput: LineEdit = get_node_or_null("SearchBar/SearchInput") as LineEdit
@onready var filterButton: TextureButton = get_node_or_null("SearchButtons/FilterButton") as TextureButton
@onready var clearButton: TextureButton = get_node_or_null("SearchButtons/ClearButton") as TextureButton

@onready var selectedPanel: Control = get_node_or_null("SelectedPanel") as Control
@onready var selectedCountLabel: Label = get_node_or_null("SelectedPanel/SelectedCountLabel") as Label
@onready var selectedIdScroll: ScrollContainer = get_node_or_null("SelectedPanel/SelectedIdScroll") as ScrollContainer
@onready var selectedIdHBox: HBoxContainer = get_node_or_null("SelectedPanel/SelectedIdScroll/SelectedIdHBox") as HBoxContainer

var tableHeaderViewport: Control
var tableRowsViewport: Control
var headerHBox: HBoxContainer
var rowsVBox: VBoxContainer

var currentLevel: Dictionary = {}
var currentColumns: Array = []
var currentRecords: Array = []
var originalRecords: Array = []
var activeSortColumnKey := ""

var selectedRecord: Dictionary = {}
var selectedRow: Button = null

var correctRecordId := ""
var hearts := 4
var maxHearts := 4
var hintIndex := 0
var hintsUsed := 0
var timeRemaining := 0.0
var levelTimeLimit := 0.0
var levelFinished := false
var currentStars := 3

var scrollX := 0.0
var scrollY := 0.0
var maxScrollX := 0.0
var maxScrollY := 0.0

var tableContentWidth := 0.0
var tableContentHeight := 0.0

var isDraggingTable := false
var lastDragGlobalPosition := Vector2.ZERO
var dragAxis := ""

var pauseOverlay: Control = null
var isPauseOpening := false
var isPauseButtonHolding := false

var audioSystem
var layoutSystem
var footerSystem
var hudSystem
var tableSystem
var scrollSystem
var pauseSystem
var rulesSystem
var searchSystem
var selectionSystem

var levelRepository

var infoPopup: Control = null
var hintPopup: Control = null

var resultPopup: Control = null
var currentLevelNumber := 1
var transitionOverlay: ColorRect = null
var isResultPopupOpen := false
var isResultTransitioning := false


# Creates gameplay systems and starts the first level.
func _ready() -> void:
	createSystems()
	setupSystems()
	loadLevel(1)


# Updates the active level timer.
func _process(delta: float) -> void:
	rulesSystem.updateTimer(delta)


# Re-applies gameplay layout when the viewport changes.
func _notification(what: int) -> void:
	if what != NOTIFICATION_RESIZED:
		return

	if layoutSystem == null or scrollSystem == null:
		return

	layoutSystem.applyFixedPhoneLayout()
	layoutSystem.setupFooterButtonsLayout()
	layoutSystem.fixSearchButtonsLayout()
	layoutSystem.setupSelectedPanelLayout()
	layoutSystem.setupObjectiveLabel()
	scrollSystem.setupCustomScrollbarPositions()
	call_deferred("refreshScrollLimits")


# Sends search and table input to the proper systems.
func _input(event: InputEvent) -> void:
	if searchSystem != null:
		searchSystem.handleInput(event)

	scrollSystem.handleInput(event)


# Creates all gameplay helper systems.
func createSystems() -> void:
	audioSystem = GameplayAudio.new(self)
	layoutSystem = GameplayLayout.new(self)
	footerSystem = GameplayFooter.new(self)
	hudSystem = GameplayHud.new(self)
	tableSystem = GameplayTable.new(self)
	scrollSystem = GameplayScroll.new(self)
	pauseSystem = GameplayPause.new(self)
	rulesSystem = GameplayRules.new(self)
	searchSystem = GameplaySearch.new(self)
	selectionSystem = GameplaySelection.new(self)
	levelRepository = LevelRepository.new()


# Runs startup setup for all gameplay systems.
func setupSystems() -> void:
	audioSystem.setupAudioProcessMode()
	audioSystem.playStartGameplaySound()

	layoutSystem.applyFixedPhoneLayout()
	layoutSystem.setupFooterButtonsLayout()
	layoutSystem.fixSearchButtonsLayout()
	layoutSystem.setupSelectedPanelLayout()
	layoutSystem.setupObjectiveLabel()

	tableSystem.setupManualTableNodes()
	scrollSystem.setupCustomScrollbarPositions()

	footerSystem.connectButtons()
	pauseSystem.connectPauseButton()

	searchSystem.setupSearchTools()
	selectionSystem.setupSelectionDisplay()

	setupInfoPopup()
	setupHintPopup()

	setupResultPopup()
	setupTransitionOverlay()


# Loads a level by number.
func loadLevel(levelNumber: int) -> void:
	currentLevelNumber = levelNumber
	isResultPopupOpen = false
	rulesSystem.loadLevel(levelNumber)


# Sets the objective header text.
func setObjectiveText(message: String, fontSize: int = 40) -> void:
	if objectiveText == null:
		return

	objectiveText.text = message
	objectiveText.add_theme_font_size_override("font_size", fontSize)
	objectiveText.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objectiveText.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	objectiveText.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objectiveText.clip_text = false


# Gets the current pause button node.
func getPauseButtonNode() -> Control:
	var pauseNode := get_node_or_null("Header/HudLayer/PauseButton") as Control

	if pauseNode != null:
		return pauseNode

	return get_node_or_null("Header/HudLayer/PauseIcon") as Control


# Refreshes table scroll limits after layout or table changes.
func refreshScrollLimits() -> void:
	scrollSystem.refreshScrollLimits()


# Handles table row selection.
func onRowSelected(record: Dictionary, row: Button) -> void:
	rulesSystem.onRowSelected(record, row)


# Handles table header sorting.
func onHeaderPressed(columnKey: String) -> void:
	tableSystem.onHeaderPressed(columnKey)


# Handles hint button press.
func onHintPressed() -> void:
	if gameplay.levelFinished:
		return

	var hints: Array = gameplay.currentLevel.get("hints", [])
	var hintLimit: int = mini(gameplay.MAX_HINT_COUNT, hints.size())

	if gameplay.hintIndex >= hintLimit:
		gameplay.updateActionButtonsState()

		if gameplay.has_method("openHintPopup"):
			gameplay.openHintPopup()

		return

	gameplay.audioSystem.playFooterClickSound(gameplay.hintClickSound)

	if gameplay.has_method("openHintPopup"):
		gameplay.openHintPopup()


# Handles check button press.
func onCheckPressed() -> void:
	rulesSystem.onCheckPressed()


# Handles info button press.
func onInfoPressed() -> void:
	rulesSystem.onInfoPressed()


# Opens the pause overlay.
func onPausePressed() -> void:
	pauseSystem.openPauseOverlay()


# Resumes gameplay from the pause overlay.
func onPauseResumePressed() -> void:
	pauseSystem.resumeGameplay()


# Handles achievements pressed from pause.
func onPauseAchievementsPressed() -> void:
	audioSystem.playPauseMenuClickSound()


# Handles settings pressed from pause.
func onPauseSettingsPressed() -> void:
	audioSystem.playPauseMenuClickSound()


# Returns from pause overlay to the main menu.
func onPauseBackToMenuPressed() -> void:
	pauseSystem.backToMainMenu()


# Updates all HUD elements.
func updateHud() -> void:
	hudSystem.updateHud()


# Builds the level table.
func buildTable() -> void:
	tableSystem.buildTable()


# Rebuilds the table while preserving scroll position.
func rebuildTableKeepScroll() -> void:
	tableSystem.rebuildTableKeepScroll()

# Creates and connects the case report popup.
func setupInfoPopup() -> void:
	if infoPopup != null:
		return

	infoPopup = INFO_POPUP_SCENE.instantiate() as Control
	add_child(infoPopup)
	infoPopup.visible = false

	if infoPopup.has_signal("popup_closed"):
		infoPopup.popup_closed.connect(_on_info_popup_closed)

	if infoPopup.has_signal("popup_button_pressed"):
		infoPopup.popup_button_pressed.connect(_on_info_popup_button_pressed)

func _on_info_popup_button_pressed() -> void:
	if audioSystem == null:
		return

	var selectedSound = get("genericSelectSound")

	if selectedSound == null:
		selectedSound = infoClickSound

	audioSystem.playFooterClickSound(selectedSound)


# Opens the case report popup.
func openInfoPopup() -> void:
	if infoPopup == null:
		setupInfoPopup()

	if infoPopup == null:
		return

	var caseTitle := str(currentLevel.get("case_title", "CASE REPORT"))
	var caseReport := str(currentLevel.get("story", ""))

	if caseReport.strip_edges().is_empty():
		caseReport = "No case report available."

	infoPopup.openPopup(caseTitle, caseReport)


# Called when the info popup closes.
func _on_info_popup_closed() -> void:
	pass


# Creates the hint popup.
func setupHintPopup() -> void:
	if hintPopup != null:
		return

	hintPopup = HINT_POPUP_SCENE.instantiate() as Control
	add_child(hintPopup)
	hintPopup.visible = false
	hintPopup.move_to_front()


# Opens the hint popup and reveals the next hint.
func openHintPopup() -> void:
	if hintPopup == null:
		setupHintPopup()

	if hintPopup == null:
		return

	var hints: Array = currentLevel.get("hints", [])
	var hintLimit: int = mini(MAX_HINT_COUNT, hints.size())

	if hints.is_empty():
		hintPopup.openPopup("No hint available.")
		updateActionButtonsState()
		return

	if hintIndex >= hintLimit:
		hintPopup.openPopup("No more hints available.")
		updateActionButtonsState()
		return

	var hintText: String = str(hints[hintIndex])

	hintIndex += 1
	hintsUsed += 1

	updateHud()
	updateActionButtonsState()

	hintPopup.openPopup(hintText)

# Creates and connects the result popup.
func setupResultPopup() -> void:
	if resultPopup != null:
		return

	resultPopup = RESULT_POPUP_SCENE.instantiate() as Control
	add_child(resultPopup)
	resultPopup.visible = false

	if resultPopup.has_signal("retry_pressed"):
		resultPopup.retry_pressed.connect(_on_result_popup_retry_pressed)

	if resultPopup.has_signal("next_level_pressed"):
		resultPopup.next_level_pressed.connect(_on_result_popup_next_level_pressed)

	if resultPopup.has_signal("back_to_menu_pressed"):
		resultPopup.back_to_menu_pressed.connect(_on_result_popup_back_to_menu_pressed)

	if resultPopup.has_signal("popup_button_pressed"):
		resultPopup.popup_button_pressed.connect(_on_result_popup_button_pressed)


# Creates fade overlay for retry/menu/next transitions.
func setupTransitionOverlay() -> void:
	if transitionOverlay != null:
		return

	transitionOverlay = ColorRect.new()
	transitionOverlay.name = "ResultTransitionOverlay"
	transitionOverlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transitionOverlay.color = Color(0, 0, 0, 1)
	transitionOverlay.modulate.a = 0.0
	transitionOverlay.visible = false
	transitionOverlay.mouse_filter = Control.MOUSE_FILTER_STOP
	transitionOverlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(transitionOverlay)


# Opens the game over popup.
func openGameOverPopup(descriptionText: String = "") -> void:
	if resultPopup == null:
		setupResultPopup()

	if resultPopup == null:
		return

	isResultPopupOpen = true

	if descriptionText.strip_edges().is_empty():
		descriptionText = "Time has expired, or lives have been depleted."

	resultPopup.open_game_over(descriptionText)


# Opens the level completed popup.
func openLevelCompletedPopup(descriptionText: String = "") -> void:
	if resultPopup == null:
		setupResultPopup()

	if resultPopup == null:
		return

	isResultPopupOpen = true

	if descriptionText.strip_edges().is_empty():
		descriptionText = "The archive case has been resolved."

	resultPopup.open_level_completed(descriptionText)


# Plays generic select sound for result popup buttons.
func _on_result_popup_button_pressed() -> void:
	if audioSystem == null:
		return

	audioSystem.playFooterClickSound(pauseMenuClickSound)


# Retries current level with a local fade transition.
func _on_result_popup_retry_pressed() -> void:
	fadeTransitionToCallable(Callable(self, "retryCurrentLevel"))


# Loads next level with a local fade transition.
func _on_result_popup_next_level_pressed() -> void:
	fadeTransitionToCallable(Callable(self, "loadNextLevel"))


func _on_result_popup_back_to_menu_pressed() -> void:
	goBackToMenuWithGlobalFade()

func goBackToMenuWithGlobalFade() -> void:
	hideResultPopupImmediately()

	var transitionManager: Node = get_node_or_null("/root/SceneTransitionManager")

	if transitionManager != null and transitionManager.has_method("changeSceneWithFade"):
		transitionManager.call(
			"changeSceneWithFade",
			MAIN_MENU_SCENE_PATH,
			0.95,
			0.55
		)
		return

	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


# Reloads current level.
func retryCurrentLevel() -> void:
	hideResultPopupImmediately()
	playStartGameplayAgain()
	loadLevel(currentLevelNumber)


# Loads next level.
func loadNextLevel() -> void:
	hideResultPopupImmediately()
	playStartGameplayAgain()
	loadLevel(currentLevelNumber + 1)


# Plays the gameplay start sound again after retry or next level.
func playStartGameplayAgain() -> void:
	if startGameplaySound == null:
		return

	startGameplaySound.stop()
	startGameplaySound.play()


# Goes back to main menu.
func goBackToMenu() -> void:
	hideResultPopupImmediately()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


# Hides result popup during transition.
func hideResultPopupImmediately() -> void:
	isResultPopupOpen = false

	if resultPopup != null and resultPopup.has_method("force_hide"):
		resultPopup.force_hide()


# Runs a fade-out, performs action, then fades in.
func fadeTransitionToCallable(action: Callable) -> void:
	if isResultTransitioning:
		return

	isResultTransitioning = true

	if transitionOverlay == null:
		setupTransitionOverlay()

	if transitionOverlay == null:
		isResultTransitioning = false
		return

	transitionOverlay.visible = true
	transitionOverlay.move_to_front()
	transitionOverlay.modulate.a = 0.0

	var fadeOut := create_tween()
	fadeOut.tween_property(
		transitionOverlay,
		"modulate:a",
		1.0,
		0.95
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await fadeOut.finished

	if action.is_valid():
		action.call()

	if not is_inside_tree():
		return

	await get_tree().process_frame
	await get_tree().process_frame

	var fadeIn := create_tween()
	fadeIn.tween_property(
		transitionOverlay,
		"modulate:a",
		0.0,
		0.55
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await fadeIn.finished

	if transitionOverlay != null and is_instance_valid(transitionOverlay):
		transitionOverlay.visible = false

	isResultTransitioning = false


# Updates footer action button states.
func updateActionButtonsState() -> void:
	updateCheckButtonState()
	updateHintButtonState()


# Disables Check when no record is selected.
func updateCheckButtonState() -> void:
	var hasSelection := false

	if selectionSystem != null:
		hasSelection = selectionSystem.hasSelection()
	else:
		hasSelection = not selectedRecord.is_empty()

	if checkButton != null:
		checkButton.disabled = not hasSelection

	var color := ENABLED_BUTTON_COLOR if hasSelection else DISABLED_BUTTON_COLOR

	if checkIcon != null:
		checkIcon.modulate = color

	if checkLabel != null:
		checkLabel.modulate = color


# Greys out Hint after all hints are used.
func updateHintButtonState() -> void:
	var hints: Array = currentLevel.get("hints", [])
	var hintLimit: int = mini(MAX_HINT_COUNT, hints.size())
	var hasHintsLeft: bool = hintIndex < hintLimit

	if hintButton != null:
		hintButton.disabled = not hasHintsLeft

	var color := ENABLED_BUTTON_COLOR if hasHintsLeft else DISABLED_BUTTON_COLOR

	if hintIcon != null:
		hintIcon.modulate = color

	if hintLabel != null:
		hintLabel.modulate = color