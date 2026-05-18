extends Control

signal backNextPressed
signal selectPressed(pageId: String)

const ChapterSliderData = preload("res://scenes/start_game/chapter_slider/chapter_slider_data.gd")
const ChapterSliderAnimator = preload("res://scenes/start_game/chapter_slider/chapter_slider_animator.gd")

const DESIGN_WIDTH := 1080.0
const DEFAULT_DESIGN_HEIGHT := 1720.0
const MINIMUM_DESIGN_HEIGHT := 900.0

const ILLUSTRATION_EXTRA_HEIGHT := 350.0
const HEADER_HEIGHT := 171.0

const TITLE_POSITION_X := 60.0
const TITLE_POSITION_RATIO_Y := 0.60
const TITLE_SIZE := Vector2(960.0, 126.0)
const TITLE_FONT_SIZE := 90

const DESCRIPTION_POSITION_X := 90.0
const DESCRIPTION_POSITION_RATIO_Y := 0.70
const DESCRIPTION_SIZE := Vector2(900.0, 190.0)
const DESCRIPTION_FONT_SIZE := 40

const SELECT_BUTTON_POSITION_X := 240.0
const SELECT_BUTTON_BOTTOM_OFFSET := 180.0
const SELECT_BUTTON_SIZE := Vector2(600.0, 265.0)

const INTRO_NAVIGATION_DELAY := 0.32

@onready var chapterHeader: TextureRect = $ChapterHeader
@onready var chapterIllustration: TextureRect = $ChapterIllustration
@onready var chapterTitle: Label = $ChapterTitle
@onready var chapterDescription: Label = $ChapterDescription
@onready var chapterNavigation: Control = $ChapterNavigation

var currentPage := 0
var isChangingPage := false
var isLocked := false

var currentDesignHeight := DEFAULT_DESIGN_HEIGHT
var pages: Array[Dictionary] = []
var animator


# Loads chapter data, prepares layout, connects navigation, and caches animation values.
func _ready() -> void:
	pages = ChapterSliderData.getPages()

	forceDesignLayout(currentDesignHeight)
	createAnimator()
	connectNavigationSignals()
	updatePageInstant()

	await get_tree().process_frame

	forceDesignLayout(currentDesignHeight)

	if animator != null:
		animator.cacheOriginalValues()

	forceNavigationVisible()


# Creates and prepares the animation helper for the chapter slider.
func createAnimator() -> void:
	animator = ChapterSliderAnimator.new()
	animator.setup(
		chapterHeader,
		chapterIllustration,
		chapterTitle,
		chapterDescription
	)


# Locks or unlocks the chapter slider controls.
func setLocked(value: bool) -> void:
	isLocked = value

	if chapterNavigation != null and chapterNavigation.has_method("setLocked"):
		chapterNavigation.call("setLocked", value)


# Connects the chapter navigation component signals.
func connectNavigationSignals() -> void:
	if chapterNavigation == null:
		push_error("ChapterNavigation not found.")
		return

	connectSignalIfAvailable(chapterNavigation, "previousPressed", Callable(self, "onPreviousPressed"))
	connectSignalIfAvailable(chapterNavigation, "nextPressed", Callable(self, "onNextPressed"))
	connectSignalIfAvailable(chapterNavigation, "selectPressed", Callable(self, "onSelectPressed"))


# Connects a signal only when it exists and is not already connected.
func connectSignalIfAvailable(target: Object, signalName: String, callback: Callable) -> void:
	if target == null:
		return

	if not target.has_signal(signalName):
		return

	if not target.is_connected(signalName, callback):
		target.connect(signalName, callback)


# Sets this slider and its navigation component to their intro starting state.
func prepareIntroState() -> void:
	if animator != null:
		animator.prepareIntroState()

	if chapterNavigation != null and chapterNavigation.has_method("prepareIntroState"):
		chapterNavigation.call("prepareIntroState")


# Plays the slider intro animation.
func playIntroAnimation() -> void:
	if animator != null:
		animator.playIntroAnimation(self)

	if chapterNavigation != null and chapterNavigation.has_method("playIntroAnimation"):
		chapterNavigation.call("playIntroAnimation")

	await get_tree().create_timer(INTRO_NAVIGATION_DELAY).timeout
	forceNavigationVisible()


# Plays the select button intro animation before opening the difficulty popup.
func playSelectIntroAnimation() -> void:
	if chapterNavigation != null and chapterNavigation.has_method("playSelectIntroAnimation"):
		chapterNavigation.call("playSelectIntroAnimation")


# Plays the slider outro animation.
func playOutroAnimation() -> void:
	if animator != null:
		animator.playOutroAnimation(self)

	if chapterNavigation != null and chapterNavigation.has_method("playOutroAnimation"):
		chapterNavigation.call("playOutroAnimation")


# Updates the visible chapter content without animation.
func updatePageInstant() -> void:
	if pages.is_empty():
		return

	var page: Dictionary = pages[currentPage]

	if chapterHeader != null:
		chapterHeader.texture = page["header"]

	if chapterIllustration != null:
		chapterIllustration.texture = page["illustration"]
		chapterIllustration.visible = true
		chapterIllustration.modulate = Color(1, 1, 1, 1)

	if chapterTitle != null:
		chapterTitle.text = page["title"]

	if chapterDescription != null:
		chapterDescription.text = page["description"]


# Forces the slider and its children into the correct design layout.
func forceDesignLayout(designHeight: float = DEFAULT_DESIGN_HEIGHT) -> void:
	currentDesignHeight = max(MINIMUM_DESIGN_HEIGHT, designHeight)

	forceRootLayout()
	forceIllustrationLayout()
	forceHeaderLayout()
	forceTitleLayout()
	forceDescriptionLayout()
	forceNavigationLayout()
	forceNavigationVisible()


# Forces the root slider size.
func forceRootLayout() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0

	offset_left = 0.0
	offset_top = 0.0
	offset_right = DESIGN_WIDTH
	offset_bottom = currentDesignHeight

	position = Vector2.ZERO
	size = Vector2(DESIGN_WIDTH, currentDesignHeight)
	scale = Vector2.ONE


# Forces the chapter illustration to cover the available area.
func forceIllustrationLayout() -> void:
	if chapterIllustration == null:
		return

	chapterIllustration.anchor_left = 0.0
	chapterIllustration.anchor_top = 0.0
	chapterIllustration.anchor_right = 0.0
	chapterIllustration.anchor_bottom = 0.0
	chapterIllustration.position = Vector2.ZERO
	chapterIllustration.custom_minimum_size = Vector2(DESIGN_WIDTH, currentDesignHeight + ILLUSTRATION_EXTRA_HEIGHT)
	chapterIllustration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chapterIllustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED


# Forces the chapter header to stay at the top.
func forceHeaderLayout() -> void:
	if chapterHeader == null:
		return

	chapterHeader.anchor_left = 0.0
	chapterHeader.anchor_top = 0.0
	chapterHeader.anchor_right = 0.0
	chapterHeader.anchor_bottom = 0.0
	chapterHeader.position = Vector2.ZERO
	chapterHeader.custom_minimum_size = Vector2(DESIGN_WIDTH, HEADER_HEIGHT)
	chapterHeader.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chapterHeader.stretch_mode = TextureRect.STRETCH_SCALE


# Positions and formats the chapter title.
func forceTitleLayout() -> void:
	if chapterTitle == null:
		return

	chapterTitle.anchor_left = 0.0
	chapterTitle.anchor_top = 0.0
	chapterTitle.anchor_right = 0.0
	chapterTitle.anchor_bottom = 0.0
	chapterTitle.position = Vector2(TITLE_POSITION_X, currentDesignHeight * TITLE_POSITION_RATIO_Y)
	chapterTitle.size = TITLE_SIZE
	chapterTitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapterTitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chapterTitle.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)


# Positions and formats the chapter description.
func forceDescriptionLayout() -> void:
	if chapterDescription == null:
		return

	chapterDescription.anchor_left = 0.0
	chapterDescription.anchor_top = 0.0
	chapterDescription.anchor_right = 0.0
	chapterDescription.anchor_bottom = 0.0
	chapterDescription.position = Vector2(DESCRIPTION_POSITION_X, currentDesignHeight * DESCRIPTION_POSITION_RATIO_Y)
	chapterDescription.size = DESCRIPTION_SIZE
	chapterDescription.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapterDescription.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chapterDescription.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chapterDescription.add_theme_font_size_override("font_size", DESCRIPTION_FONT_SIZE)


# Forces the navigation component to cover the full slider area.
func forceNavigationLayout() -> void:
	if chapterNavigation == null:
		return

	chapterNavigation.anchor_left = 0.0
	chapterNavigation.anchor_top = 0.0
	chapterNavigation.anchor_right = 0.0
	chapterNavigation.anchor_bottom = 0.0
	chapterNavigation.position = Vector2.ZERO
	chapterNavigation.size = Vector2(DESIGN_WIDTH, currentDesignHeight)
	chapterNavigation.scale = Vector2.ONE

	if chapterNavigation.has_method("forceDesignLayout"):
		chapterNavigation.call("forceDesignLayout", currentDesignHeight)


# Restores the visibility and clickability of the navigation buttons.
func forceNavigationVisible() -> void:
	if chapterNavigation == null:
		return

	chapterNavigation.visible = true
	chapterNavigation.modulate = Color(1, 1, 1, 1)
	chapterNavigation.mouse_filter = Control.MOUSE_FILTER_IGNORE

	forceSelectButtonVisible()
	forcePreviousButtonVisible()
	forceNextButtonVisible()


# Restores the select button after layout or animation changes.
func forceSelectButtonVisible() -> void:
	var selectButton := chapterNavigation.find_child("SelectButton", true, false) as Control

	if selectButton == null:
		return

	selectButton.visible = true
	selectButton.modulate = Color(1, 1, 1, 1)
	selectButton.mouse_filter = Control.MOUSE_FILTER_STOP
	selectButton.position = Vector2(SELECT_BUTTON_POSITION_X, currentDesignHeight - SELECT_BUTTON_BOTTOM_OFFSET)
	selectButton.size = SELECT_BUTTON_SIZE
	selectButton.scale = Vector2.ONE


# Restores the previous button after layout or animation changes.
func forcePreviousButtonVisible() -> void:
	var previousButton := chapterNavigation.find_child("SelectChapterBackButton", true, false) as Control

	if previousButton == null:
		return

	previousButton.visible = true
	previousButton.modulate = Color(1, 1, 1, 1)


# Restores the next button after layout or animation changes.
func forceNextButtonVisible() -> void:
	var nextButton := chapterNavigation.find_child("SelectChapterNextButton", true, false) as Control

	if nextButton == null:
		return

	nextButton.visible = true
	nextButton.modulate = Color(1, 1, 1, 1)


# Changes the selected chapter page by direction.
func changePage(direction: int) -> void:
	if isChangingPage or isLocked:
		return

	if pages.is_empty():
		return

	isChangingPage = true
	backNextPressed.emit()

	if animator != null:
		await animator.playPageOut(self, direction)

	currentPage = wrapi(currentPage + direction, 0, pages.size())
	updatePageInstant()

	if animator != null:
		animator.preparePageIn(direction)
		await animator.playPageIn(self)
		animator.restoreTextState()

	forceNavigationVisible()
	isChangingPage = false


# Moves to the previous chapter.
func onPreviousPressed() -> void:
	changePage(-1)


# Moves to the next chapter.
func onNextPressed() -> void:
	changePage(1)


# Emits the selected chapter page id.
func onSelectPressed() -> void:
	if isLocked or isChangingPage:
		return

	if pages.is_empty():
		return

	var selectedPage: Dictionary = pages[currentPage]
	var pageId: String = selectedPage["id"]

	selectPressed.emit(pageId)