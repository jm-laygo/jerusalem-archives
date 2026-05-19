extends Control

signal popup_closed

const EMPTY_REPORT_TEXT := "No message report available."

const FADE_IN_DURATION := 0.28
const FADE_OUT_DURATION := 0.22

const CLUE_COLOR := "#C9E472"

const SHOW_SOUND_PATH := "res://assets/sounds/ui/ui_info_show.wav"
const CLOSE_SOUND_PATH := "res://assets/sounds/ui/ui_info_close.wav"
const NEXT_BACK_SOUND_PATH := "res://assets/sounds/ui/ui_info_next_back.wav"

@onready var dim: ColorRect = $Dim
@onready var popup_background: TextureRect = $PopupBackground
@onready var title_label: Label = $PopupBackground/TitleLabel
@onready var report_label: RichTextLabel = $PopupBackground/ReportLabel

@onready var next_button: TextureButton = $PopupBackground/Buttons/NextButton
@onready var close_button: TextureButton = $PopupBackground/Buttons/CloseButton

@onready var next_label: Label = $PopupBackground/Buttons/NextButton/Label
@onready var close_label: Label = $PopupBackground/Buttons/CloseButton/Label

var pages: Array[String] = []
var cluePhrases: Array = []
var revealedClueCount := 0
var currentPageIndex := 0
var animationTween: Tween = null
var isClosing := false

var audioPlayer: AudioStreamPlayer = null
var showSound: AudioStream = null
var closeSound: AudioStream = null
var nextBackSound: AudioStream = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	modulate.a = 0.0
	z_index = 1500
	z_as_relative = false

	setupAudio()

	if dim != null:
		dim.mouse_filter = Control.MOUSE_FILTER_STOP
		dim.modulate.a = 0.0

	if popup_background != null:
		popup_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		popup_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		popup_background.stretch_mode = TextureRect.STRETCH_SCALE

	setupLabels()
	setupButtons()


func setupAudio() -> void:
	audioPlayer = AudioStreamPlayer.new()
	audioPlayer.name = "InfoPopupAudioPlayer"
	audioPlayer.process_mode = Node.PROCESS_MODE_ALWAYS
	audioPlayer.bus = "Master"
	add_child(audioPlayer)

	if ResourceLoader.exists(SHOW_SOUND_PATH):
		showSound = load(SHOW_SOUND_PATH)

	if ResourceLoader.exists(CLOSE_SOUND_PATH):
		closeSound = load(CLOSE_SOUND_PATH)

	if ResourceLoader.exists(NEXT_BACK_SOUND_PATH):
		nextBackSound = load(NEXT_BACK_SOUND_PATH)


func playPopupSound(sound: AudioStream) -> void:
	if audioPlayer == null:
		return

	if sound == null:
		return

	audioPlayer.stop()
	audioPlayer.stream = sound
	audioPlayer.play()


func setupLabels() -> void:
	if title_label != null:
		title_label.visible = false
		title_label.text = ""
		title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if report_label != null:
		report_label.bbcode_enabled = true
		report_label.scroll_active = false
		report_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		report_label.text = "[left]%s[/left]" % EMPTY_REPORT_TEXT

	setupButtonLabel(next_label, "NEXT")
	setupButtonLabel(close_label, "CLOSE")


func setupButtonLabel(label: Label, textValue: String) -> void:
	if label == null:
		return

	label.text = textValue
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func setupButtons() -> void:
	setupOneButton(next_button)
	setupOneButton(close_button)

	if next_button != null and not next_button.pressed.is_connected(onNextPressed):
		next_button.pressed.connect(onNextPressed)

	if close_button != null and not close_button.pressed.is_connected(onClosePressed):
		close_button.pressed.connect(onClosePressed)


func setupOneButton(button: TextureButton) -> void:
	if button == null:
		return

	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.disabled = false
	button.modulate.a = 1.0


func openPopup(_caseTitle: String, caseReport: String, newCluePhrases: Array = [], newRevealedClueCount: int = 0) -> void:
	pages = buildPages(caseReport)
	cluePhrases = newCluePhrases.duplicate(true)
	revealedClueCount = clampi(newRevealedClueCount, 0, cluePhrases.size())

	if title_label != null:
		title_label.visible = false
		title_label.text = ""

	currentPageIndex = 0
	visible = true
	isClosing = false
	move_to_front()

	updatePage()
	updateButtons()
	playPopupSound(showSound)
	playOpenAnimation()


func setRevealedClueCount(newRevealedClueCount: int) -> void:
	revealedClueCount = clampi(newRevealedClueCount, 0, cluePhrases.size())
	updatePage()


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


func updatePage() -> void:
	if report_label == null:
		return

	if pages.is_empty():
		report_label.text = "[left]%s[/left]" % EMPTY_REPORT_TEXT
		return

	var pageText := pages[currentPageIndex]
	report_label.text = buildRichTextPage(pageText)


func buildRichTextPage(pageText: String) -> String:
	var markedText := escapeBBCode(pageText)

	for index in range(revealedClueCount):
		if index >= cluePhrases.size():
			break

		var phrase := str(cluePhrases[index]).strip_edges()

		if phrase.is_empty():
			continue

		var safePhrase := escapeBBCode(phrase)

		markedText = markedText.replace(
			safePhrase,
			"[color=%s][u]%s[/u][/color]" % [CLUE_COLOR, safePhrase]
		)

	return "[left]%s[/left]" % markedText


func escapeBBCode(value: String) -> String:
	return value.replace("[", "［").replace("]", "］")


func updateButtons() -> void:
	if next_button != null:
		next_button.disabled = false
		next_button.modulate.a = 1.0

	if close_button != null:
		close_button.disabled = false
		close_button.modulate.a = 1.0


func onNextPressed() -> void:
	playPopupSound(nextBackSound)

	if pages.is_empty():
		return

	currentPageIndex += 1

	if currentPageIndex >= pages.size():
		currentPageIndex = 0

	updatePage()
	updateButtons()


func onClosePressed() -> void:
	closePopup()


func playOpenAnimation() -> void:
	killAnimationTween()

	mouse_filter = Control.MOUSE_FILTER_STOP
	modulate.a = 0.0

	if dim != null:
		dim.modulate.a = 0.0

	animationTween = create_tween()
	animationTween.set_parallel(true)

	animationTween.tween_property(
		self,
		"modulate:a",
		1.0,
		FADE_IN_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if dim != null:
		animationTween.tween_property(
			dim,
			"modulate:a",
			1.0,
			FADE_IN_DURATION
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func closePopup() -> void:
	if isClosing:
		return

	playPopupSound(closeSound)

	isClosing = true
	killAnimationTween()

	animationTween = create_tween()
	animationTween.set_parallel(true)

	animationTween.tween_property(
		self,
		"modulate:a",
		0.0,
		FADE_OUT_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	if dim != null:
		animationTween.tween_property(
			dim,
			"modulate:a",
			0.0,
			FADE_OUT_DURATION
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	animationTween.finished.connect(finishCloseAnimation)


func finishCloseAnimation() -> void:
	visible = false
	isClosing = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0
	popup_closed.emit()


func killAnimationTween() -> void:
	if animationTween != null and animationTween.is_valid():
		animationTween.kill()

	animationTween = null
