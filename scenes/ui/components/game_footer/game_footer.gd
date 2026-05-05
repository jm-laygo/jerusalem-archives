extends TextureRect

signal back_pressed
signal settings_pressed
signal achievements_pressed

const BUTTON_NORMAL_MODULATE := Color(1, 1, 1, 1)

const INTRO_TIME := 0.30
const OUTRO_TIME := 0.30

@onready var back_button: TextureButton = $FooterButtons/BackButton
@onready var settings_button: TextureButton = $FooterButtons/SettingsButton
@onready var achievements_button: TextureButton = $FooterButtons/AchievementsButton

var footer_original_position := Vector2.ZERO
var intro_tween: Tween
var outro_tween: Tween


func _ready() -> void:
	_setup_buttons()

	await get_tree().process_frame

	cache_original_values()


func _setup_buttons() -> void:
	if back_button != null and not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)
		_setup_button_style(back_button)

	if settings_button != null and not settings_button.pressed.is_connected(_on_settings_button_pressed):
		settings_button.pressed.connect(_on_settings_button_pressed)
		_setup_button_style(settings_button)

	if achievements_button != null and not achievements_button.pressed.is_connected(_on_achievements_button_pressed):
		achievements_button.pressed.connect(_on_achievements_button_pressed)
		_setup_button_style(achievements_button)


func _setup_button_style(button: TextureButton) -> void:
	if button == null:
		return

	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.disabled = false
	button.modulate = BUTTON_NORMAL_MODULATE
	button.texture_hover = button.texture_normal
	button.texture_focused = button.texture_normal
	button.texture_disabled = button.texture_normal


func _ignore_children_mouse(button: TextureButton) -> void:
	if button == null:
		return

	for child in button.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_back_button_pressed() -> void:
	print("footer back pressed")
	back_pressed.emit()


func _on_settings_button_pressed() -> void:
	print("footer settings pressed")
	settings_pressed.emit()


func _on_achievements_button_pressed() -> void:
	print("footer achievements pressed")
	achievements_pressed.emit()


func cache_original_values() -> void:
	footer_original_position = position


func prepare_intro_state() -> void:
	position = footer_original_position + Vector2(0, 170)


func play_intro_animation() -> void:
	_kill_tween(intro_tween)

	intro_tween = create_tween()

	intro_tween.tween_property(
		self,
		"position",
		footer_original_position,
		INTRO_TIME
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await intro_tween.finished


func play_outro_animation() -> void:
	_kill_tween(outro_tween)

	var footer_out_position := footer_original_position + Vector2(0, 170)

	outro_tween = create_tween()

	outro_tween.tween_property(
		self,
		"position",
		footer_out_position,
		OUTRO_TIME
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await outro_tween.finished


func _kill_tween(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
