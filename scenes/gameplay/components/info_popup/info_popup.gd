extends Control

signal popup_closed

const DEFAULT_TITLE := "CASE REPORT"
const EMPTY_REPORT_TEXT := "No case report available."

@onready var dim: ColorRect = $Dim
@onready var popup_background: TextureRect = $PopupBackground
@onready var title_label: Label = $PopupBackground/TitleLabel
@onready var report_label: Label = $PopupBackground/ReportLabel

@onready var back_button: Button = $PopupBackground/Buttons/BackButton
@onready var close_button: Button = $PopupBackground/Buttons/CloseButton
@onready var next_button: Button = $PopupBackground/Buttons/NextButton

var pages: Array[String] = []
var currentPageIndex: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	if dim != null:
		dim.mouse_filter = Control.MOUSE_FILTER_STOP

	if popup_background != null:
		popup_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		popup_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		popup_background.stretch_mode = TextureRect.STRETCH_SCALE

	setupLabels()
	setupButtons()


# Sets up the title and case report text.
func setupLabels() -> void:
	if title_label != null:
		title_label.text = DEFAULT_TITLE
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if report_label != null:
		report_label.text = EMPTY_REPORT_TEXT
		report_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		report_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		report_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		report_label.clip_text = false
		report_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


# Connects popup buttons.
func setupButtons() -> void:
	setupOneButton(back_button)
	setupOneButton(close_button)
	setupOneButton(next_button)

	if back_button != null and not back_button.pressed.is_connected(onBackPressed):
		back_button.pressed.connect(onBackPressed)

	if close_button != null and not close_button.pressed.is_connected(onClosePressed):
		close_button.pressed.connect(onClosePressed)

	if next_button != null and not next_button.pressed.is_connected(onNextPressed):
		next_button.pressed.connect(onNextPressed)


# Makes one popup button clean and clickable.
func setupOneButton(button: Button) -> void:
	if button == null:
		return

	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP


# Opens the case report popup.
func openPopup(caseTitle: String, caseReport: String) -> void:
	pages = buildPages(caseReport)

	if title_label != null:
		title_label.text = caseTitle if not caseTitle.strip_edges().is_empty() else DEFAULT_TITLE

	currentPageIndex = 0
	visible = true
	move_to_front()

	updatePage()
	updateButtons()


# Splits the report into readable pages.
func buildPages(caseReport: String) -> Array[String]:
	var reportText := caseReport.strip_edges()

	if reportText.is_empty():
		return [EMPTY_REPORT_TEXT]

	# Use this delimiter later if you want multiple pages from database:
	# Page 1 text|||Page 2 text|||Page 3 text
	var rawPages := reportText.split("|||", false)
	var builtPages: Array[String] = []

	for page in rawPages:
		var cleanPage := str(page).strip_edges()

		if not cleanPage.is_empty():
			builtPages.append(cleanPage)

	if builtPages.is_empty():
		builtPages.append(EMPTY_REPORT_TEXT)

	return builtPages


# Closes the popup.
func closePopup() -> void:
	visible = false
	popup_closed.emit()


# Goes to previous page.
func onBackPressed() -> void:
	if currentPageIndex <= 0:
		currentPageIndex = 0
	else:
		currentPageIndex -= 1

	updatePage()
	updateButtons()


# Closes the popup.
func onClosePressed() -> void:
	closePopup()


# Goes to next page.
func onNextPressed() -> void:
	if currentPageIndex >= pages.size() - 1:
		currentPageIndex = pages.size() - 1
	else:
		currentPageIndex += 1

	updatePage()
	updateButtons()


# Updates visible report text.
func updatePage() -> void:
	if report_label == null:
		return

	if pages.is_empty():
		report_label.text = EMPTY_REPORT_TEXT
		return

	report_label.text = pages[currentPageIndex]


# Updates button availability.
func updateButtons() -> void:
	if back_button != null:
		back_button.disabled = pages.is_empty() or currentPageIndex <= 0

	if next_button != null:
		next_button.disabled = pages.is_empty() or currentPageIndex >= pages.size() - 1

	if close_button != null:
		close_button.disabled = false