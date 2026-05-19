extends Control

signal popup_closed
signal popup_button_pressed

const DEFAULT_TITLE := "CASE REPORT"
const EMPTY_REPORT_TEXT := "No case report available."

const FADE_IN_DURATION := 0.28
const FADE_OUT_DURATION := 0.22

@onready var dim: ColorRect = $Dim
@onready var popup_background: TextureRect = $PopupBackground
@onready var title_label: Label = $PopupBackground/TitleLabel
@onready var report_label: Label = $PopupBackground/ReportLabel

@onready var back_button: TextureButton = $PopupBackground/Buttons/BackButton
@onready var close_button: TextureButton = $PopupBackground/Buttons/CloseButton
@onready var next_button: TextureButton = $PopupBackground/Buttons/NextButton

@onready var back_label: Label = $PopupBackground/Buttons/BackButton/Label
@onready var close_label: Label = $PopupBackground/Buttons/CloseButton/Label
@onready var next_label: Label = $PopupBackground/Buttons/NextButton/Label

var pages: Array[String] = []
var currentPageIndex: int = 0
var animationTween: Tween = null
var isClosing := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	modulate.a = 0.0

	if dim != null:
		dim.mouse_filter = Control.MOUSE_FILTER_STOP
		dim.modulate.a = 0.0

	if popup_background != null:
		popup_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		popup_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		popup_background.stretch_mode = TextureRect.STRETCH_SCALE
		popup_background.modulate.a = 1.0
		popup_background.scale = Vector2.ONE

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

	setupButtonLabel(back_label, "BACK")
	setupButtonLabel(close_label, "CLOSE")
	setupButtonLabel(next_label, "NEXT")


# Sets up one button label.
func setupButtonLabel(label: Label, textValue: String) -> void:
	if label == null:
		return

	label.text = textValue
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE


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
func setupOneButton(button: TextureButton) -> void:
	if button == null:
		return

	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE


# Opens the case report popup.
func openPopup(caseTitle: String, caseReport: String) -> void:
	pages = buildPages(caseReport)

	if title_label != null:
		if caseTitle.strip_edges().is_empty():
			title_label.text = DEFAULT_TITLE
		else:
			title_label.text = caseTitle

	currentPageIndex = 0
	visible = true
	isClosing = false
	move_to_front()

	updatePage()
	updateButtons()
	playOpenAnimation()


# Splits the report into readable pages.
func buildPages(caseReport: String) -> Array[String]:
	var reportText := caseReport.strip_edges()

	if reportText.is_empty():
		return [EMPTY_REPORT_TEXT]

	var rawPages := reportText.split("|||", false)
	var builtPages: Array[String] = []

	for page in rawPages:
		var cleanPage := str(page).strip_edges()

		if not cleanPage.is_empty():
			builtPages.append(cleanPage)

	if builtPages.is_empty():
		builtPages.append(EMPTY_REPORT_TEXT)

	return builtPages


# Pure fade-in animation.
func playOpenAnimation() -> void:
	killAnimationTween()

	mouse_filter = Control.MOUSE_FILTER_STOP
	modulate.a = 0.0

	if dim != null:
		dim.modulate.a = 0.0

	if popup_background != null:
		popup_background.scale = Vector2.ONE
		popup_background.modulate.a = 1.0

	animationTween = create_tween()
	animationTween.set_parallel(true)

	animationTween.tween_property(self, "modulate:a", 1.0, FADE_IN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if dim != null:
		animationTween.tween_property(dim, "modulate:a", 1.0, FADE_IN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# Pure fade-out animation.
func playCloseAnimation() -> void:
	if isClosing:
		return

	isClosing = true
	killAnimationTween()

	animationTween = create_tween()
	animationTween.set_parallel(true)

	animationTween.tween_property(self, "modulate:a", 0.0, FADE_OUT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	if dim != null:
		animationTween.tween_property(dim, "modulate:a", 0.0, FADE_OUT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	animationTween.finished.connect(finishCloseAnimation)


# Finishes closing after fade-out.
func finishCloseAnimation() -> void:
	visible = false
	isClosing = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_closed.emit()


# Stops current animation tween safely.
func killAnimationTween() -> void:
	if animationTween != null and animationTween.is_valid():
		animationTween.kill()

	animationTween = null


# Closes the popup.
func closePopup() -> void:
	playCloseAnimation()


# Goes to previous page.
func onBackPressed() -> void:
	popup_button_pressed.emit()

	if currentPageIndex <= 0:
		currentPageIndex = 0
	else:
		currentPageIndex -= 1

	updatePage()
	updateButtons()


# Closes the popup.
func onClosePressed() -> void:
	popup_button_pressed.emit()
	closePopup()


# Goes to next page.
func onNextPressed() -> void:
	popup_button_pressed.emit()

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
		back_button.modulate.a = 0.45 if back_button.disabled else 1.0

	if next_button != null:
		next_button.disabled = pages.is_empty() or currentPageIndex >= pages.size() - 1
		next_button.modulate.a = 0.45 if next_button.disabled else 1.0

	if close_button != null:
		close_button.disabled = false
		close_button.modulate.a = 1.0