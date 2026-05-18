extends Control

const GameplayAudio = preload("res://scenes/gameplay/systems/gameplay_audio.gd")
const GameplayLayout = preload("res://scenes/gameplay/systems/gameplay_layout.gd")
const GameplayFooter = preload("res://scenes/gameplay/systems/gameplay_footer.gd")
const GameplayHud = preload("res://scenes/gameplay/systems/gameplay_hud.gd")
const GameplayTable = preload("res://scenes/gameplay/systems/gameplay_table.gd")
const GameplayScroll = preload("res://scenes/gameplay/systems/gameplay_scroll.gd")
const GameplayPause = preload("res://scenes/gameplay/systems/gameplay_pause.gd")
const GameplayRules = preload("res://scenes/gameplay/systems/gameplay_rules.gd")

const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu/main_menu.tscn"
const START_GAMEPLAY_SOUND: AudioStream = preload("res://assets/sounds/sfx/sfx_start_gameplay.wav")

const HEADER_CELL_SCENE := preload("res://scenes/gameplay/components/header_cell/header_cell.tscn")
const TABLE_ROW_SCENE := preload("res://scenes/gameplay/components/table_row/table_row.tscn")
const CHAPTER_1_LEVELS := preload("res://scripts/data/chapter_1_levels.gd")
const PAUSE_OVERLAY_SCENE := preload("res://scenes/gameplay/components/pause/pause_overlay.tscn")

const STAR_FILLED_TEXTURE: Texture2D = preload("res://assets/interface/icons/icon_star.png")
const STAR_EMPTY_TEXTURE: Texture2D = preload("res://assets/interface/icons/icon_empty_star.png")

const DESIGN_WIDTH := 1080.0
const FOOTER_HEIGHT := 217.0

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
	layoutSystem.setupObjectiveLabel()
	scrollSystem.setupCustomScrollbarPositions()
	call_deferred("refreshScrollLimits")


# Sends table drag and wheel input to the scroll system.
func _input(event: InputEvent) -> void:
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


# Runs startup setup for all gameplay systems.
func setupSystems() -> void:
	audioSystem.setupAudioProcessMode()
	audioSystem.playStartGameplaySound()

	layoutSystem.applyFixedPhoneLayout()
	layoutSystem.setupFooterButtonsLayout()
	layoutSystem.fixSearchButtonsLayout()
	layoutSystem.setupObjectiveLabel()

	tableSystem.setupManualTableNodes()
	scrollSystem.setupCustomScrollbarPositions()

	footerSystem.connectButtons()
	pauseSystem.connectPauseButton()


# Loads a level by number.
func loadLevel(levelNumber: int) -> void:
	rulesSystem.loadLevel(levelNumber)


# Sets the objective text safely.
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
	rulesSystem.onHintPressed()


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