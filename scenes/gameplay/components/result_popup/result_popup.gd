extends Control

signal retry_pressed
signal next_level_pressed
signal back_to_menu_pressed
signal popup_button_pressed

const MODE_GAME_OVER := "game_over"
const MODE_LEVEL_COMPLETED := "level_completed"

const TITLE_GAME_OVER := "GAME OVER"
const TITLE_LEVEL_COMPLETED := "LEVEL\nCOMPLETED"

const DESCRIPTION_GAME_OVER := "Time has expired, or lives have been depleted."
const DESCRIPTION_LEVEL_COMPLETED := "The archive case has been resolved."

const TITLE_GAME_OVER_COLOR := Color("#F64505")
const TITLE_LEVEL_COMPLETED_COLOR := Color("#C9E472")
const DESCRIPTION_COLOR := Color("#D5D0B5")

const TITLE_FONT_SIZE := 120
const DESCRIPTION_FONT_SIZE := 40
const BUTTON_FONT_SIZE := 34

const FADE_IN_DURATION := 0.28
const FADE_OUT_DURATION := 0.22

const MUSIC_STAGE_ONE_DB := -14.0
const MUSIC_SILENCE_DB := -60.0
const MUSIC_STAGE_ONE_DURATION := 0.35
const MUSIC_STAGE_TWO_DURATION := 0.45

@export var game_over_background: Texture2D
@export var level_completed_background: Texture2D
@export var game_over_music: AudioStream
@export var victory_music: AudioStream

@onready var dim: ColorRect = $Dim
@onready var popup_background: TextureRect = $PopupBackground
@onready var title_label: Label = $PopupBackground/TitleLabel
@onready var description_label: Label = $PopupBackground/DescriptionLabel

@onready var buttons: VBoxContainer = $PopupBackground/Buttons
@onready var primary_button: TextureButton = $PopupBackground/Buttons/PrimaryButton
@onready var menu_button: TextureButton = $PopupBackground/Buttons/MenuButton

@onready var primary_label: Label = $PopupBackground/Buttons/PrimaryButton/Label
@onready var menu_label: Label = $PopupBackground/Buttons/MenuButton/Label

@onready var music_player: AudioStreamPlayer = $MusicPlayer

var mode := MODE_GAME_OVER
var animation_tween: Tween = null
var is_closing := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 2000
	z_as_relative = false
	modulate.a = 0.0

	if dim != null:
		dim.mouse_filter = Control.MOUSE_FILTER_STOP
		dim.modulate.a = 0.0

	if popup_background != null:
		popup_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		popup_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		popup_background.stretch_mode = TextureRect.STRETCH_SCALE

	setup_labels()
	setup_buttons()


func setup_labels() -> void:
	if title_label != null:
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title_label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
		title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if description_label != null:
		description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.clip_text = false
		description_label.add_theme_font_size_override("font_size", DESCRIPTION_FONT_SIZE)
		description_label.add_theme_color_override("font_color", DESCRIPTION_COLOR)
		description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	setup_button_label(primary_label, "RETRY")
	setup_button_label(menu_label, "BACK TO MENU")


func setup_button_label(label: Label, text_value: String) -> void:
	if label == null:
		return

	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	label.add_theme_color_override("font_color", Color(0.972549, 0.909804, 0.74902, 1))


func setup_buttons() -> void:
	setup_one_button(primary_button)
	setup_one_button(menu_button)

	if primary_button != null and not primary_button.pressed.is_connected(on_primary_pressed):
		primary_button.pressed.connect(on_primary_pressed)

	if menu_button != null and not menu_button.pressed.is_connected(on_menu_pressed):
		menu_button.pressed.connect(on_menu_pressed)


func setup_one_button(button: TextureButton) -> void:
	if button == null:
		return

	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE


func open_game_over(description_text: String = DESCRIPTION_GAME_OVER) -> void:
	mode = MODE_GAME_OVER

	if popup_background != null:
		popup_background.texture = game_over_background

	if title_label != null:
		title_label.text = TITLE_GAME_OVER
		title_label.add_theme_color_override("font_color", TITLE_GAME_OVER_COLOR)

	if description_label != null:
		description_label.text = description_text

	setup_button_label(primary_label, "RETRY")
	setup_button_label(menu_label, "BACK TO MENU")
	apply_game_over_layout()
	enable_buttons(true)

	play_music(game_over_music)
	show_popup()


func open_level_completed(description_text: String = DESCRIPTION_LEVEL_COMPLETED) -> void:
	mode = MODE_LEVEL_COMPLETED

	if popup_background != null:
		popup_background.texture = level_completed_background

	if title_label != null:
		title_label.text = TITLE_LEVEL_COMPLETED
		title_label.add_theme_color_override("font_color", TITLE_LEVEL_COMPLETED_COLOR)

	if description_label != null:
		description_label.text = description_text

	setup_button_label(primary_label, "NEXT LEVEL")
	setup_button_label(menu_label, "BACK TO MENU")
	apply_level_completed_layout()
	enable_buttons(true)

	play_music(victory_music)
	show_popup()


# Keeps Game Over title/description/button spacing polished.
func apply_game_over_layout() -> void:
	if title_label != null:
		title_label.offset_left = -480.0
		title_label.offset_top = 235.0
		title_label.offset_right = 480.0
		title_label.offset_bottom = 420.0

	if description_label != null:
		description_label.offset_left = -420.0
		description_label.offset_top = 420.0
		description_label.offset_right = 420.0
		description_label.offset_bottom = 520.0

	if buttons != null:
		buttons.offset_left = -260.0
		buttons.offset_top = 560.0
		buttons.offset_right = 260.0
		buttons.offset_bottom = 760.0


# Keeps Level Completed spacing consistent with Game Over.
func apply_level_completed_layout() -> void:
	if title_label != null:
		title_label.offset_left = -480.0
		title_label.offset_top = 185.0
		title_label.offset_right = 480.0
		title_label.offset_bottom = 430.0

	if description_label != null:
		description_label.offset_left = -420.0
		description_label.offset_top = 430.0
		description_label.offset_right = 420.0
		description_label.offset_bottom = 530.0

	if buttons != null:
		buttons.offset_left = -260.0
		buttons.offset_top = 570.0
		buttons.offset_right = 260.0
		buttons.offset_bottom = 770.0


func show_popup() -> void:
	visible = true
	is_closing = false
	move_to_front()
	play_open_animation()


func play_music(stream: AudioStream) -> void:
	var musicManager: Node = get_node_or_null("/root/MusicManager")

	if musicManager != null and musicManager.has_method("playResultMusic"):
		musicManager.call("playResultMusic", stream)
		return

	if music_player == null:
		return

	music_player.stop()
	music_player.stream = stream
	music_player.volume_db = 0.0

	if music_player.stream != null:
		music_player.play()

func fade_music_to_silence() -> void:
	var musicManager: Node = get_node_or_null("/root/MusicManager")

	if musicManager != null and musicManager.has_method("fadeOutResultMusic"):
		musicManager.call("fadeOutResultMusic", 1.25)
		return

	if music_player == null:
		return

	if not music_player.playing:
		return

	var musicTween := create_tween()

	musicTween.tween_property(
		music_player,
		"volume_db",
		MUSIC_SILENCE_DB,
		1.25
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await musicTween.finished

	music_player.stop()
	music_player.volume_db = 0.0


func stop_music() -> void:
	if music_player != null:
		music_player.stop()


func play_open_animation() -> void:
	kill_animation_tween()

	mouse_filter = Control.MOUSE_FILTER_STOP
	modulate.a = 0.0

	if dim != null:
		dim.modulate.a = 0.0

	animation_tween = create_tween()
	animation_tween.set_parallel(true)
	animation_tween.tween_property(self, "modulate:a", 1.0, FADE_IN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if dim != null:
		animation_tween.tween_property(dim, "modulate:a", 1.0, FADE_IN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func close_popup() -> void:
	if is_closing:
		return

	is_closing = true
	kill_animation_tween()

	animation_tween = create_tween()
	animation_tween.set_parallel(true)
	animation_tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	if dim != null:
		animation_tween.tween_property(dim, "modulate:a", 0.0, FADE_OUT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	animation_tween.finished.connect(finish_close)


func finish_close() -> void:
	visible = false
	is_closing = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	enable_buttons(true)


# Instantly hides popup during scene/level transition.
func force_hide() -> void:
	kill_animation_tween()

	visible = false
	is_closing = false
	modulate.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if dim != null:
		dim.modulate.a = 0.0

	enable_buttons(true)


func enable_buttons(enabled: bool) -> void:
	if primary_button != null:
		primary_button.disabled = not enabled

	if menu_button != null:
		menu_button.disabled = not enabled


func kill_animation_tween() -> void:
	if animation_tween != null and animation_tween.is_valid():
		animation_tween.kill()

	animation_tween = null


func on_primary_pressed() -> void:
	popup_button_pressed.emit()
	enable_buttons(false)

	fade_music_to_silence()

	if mode == MODE_GAME_OVER:
		retry_pressed.emit()
	else:
		next_level_pressed.emit()


func on_menu_pressed() -> void:
	popup_button_pressed.emit()
	enable_buttons(false)

	fade_music_to_silence()

	back_to_menu_pressed.emit()