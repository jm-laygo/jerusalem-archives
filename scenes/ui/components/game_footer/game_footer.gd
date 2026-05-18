extends TextureRect

signal back_pressed
signal settings_pressed
signal achievements_pressed

const FOOTER_HEIGHT := 200.0
const FOOTER_HIDDEN_OFFSET := 170.0

const BUTTON_NORMAL_MODULATE := Color(1, 1, 1, 1)
const BUTTON_PRESSED_MODULATE := Color(0.88, 0.88, 0.88, 1)

const CHILD_PUSH_OFFSET := Vector2(0, 3)
const BUTTON_PUSH_TIME := 0.045
const BUTTON_RELEASE_TIME := 0.10

const INTRO_TIME := 0.30
const OUTRO_TIME := 0.30

@onready var back_button: TextureButton = $FooterButtons/BackButton
@onready var settings_button: TextureButton = $FooterButtons/SettingsButton
@onready var achievements_button: TextureButton = $FooterButtons/AchievementsButton

var footer_original_position := Vector2.ZERO
var intro_tween: Tween
var outro_tween: Tween

var active_button: TextureButton = null
var button_tweens := {}
var child_original_positions := {}


func _ready() -> void:
	await get_tree().process_frame

	_force_bottom_layout()
	_setup_buttons()
	cache_original_values()


func _force_bottom_layout() -> void:
	anchor_left = 0.5
	anchor_top = 1.0
	anchor_right = 0.5
	anchor_bottom = 1.0

	offset_left = -540.0
	offset_top = -FOOTER_HEIGHT
	offset_right = 540.0
	offset_bottom = 0.0

	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN


func _setup_buttons() -> void:
	_setup_footer_button(back_button)
	_setup_footer_button(settings_button)
	_setup_footer_button(achievements_button)


func _setup_footer_button(button: TextureButton) -> void:
	if button == null:
		return

	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.disabled = false
	button.modulate = BUTTON_NORMAL_MODULATE

	button.texture_hover = button.texture_normal
	button.texture_focused = button.texture_normal
	button.texture_disabled = button.texture_normal

	_cache_child_positions(button)

	for child in button.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if not button.button_down.is_connected(_on_button_down.bind(button)):
		button.button_down.connect(_on_button_down.bind(button))

	if not button.button_up.is_connected(_on_button_up.bind(button)):
		button.button_up.connect(_on_button_up.bind(button))

	if not button.mouse_exited.is_connected(_on_button_mouse_exited.bind(button)):
		button.mouse_exited.connect(_on_button_mouse_exited.bind(button))


func _cache_child_positions(button: TextureButton) -> void:
	if button == null:
		return

	child_original_positions[button] = {}

	for child in button.get_children():
		if child is Control:
			child_original_positions[button][child] = child.position


func _on_button_down(button: TextureButton) -> void:
	if button == null:
		return

	active_button = button
	_push_button_down(button)


func _on_button_up(button: TextureButton) -> void:
	if button == null:
		return

	var should_click := active_button == button and _is_mouse_inside_button(button)

	active_button = null
	_release_button(button)

	if not should_click:
		return

	if button == back_button:
		print("footer back pressed")
		back_pressed.emit()
	elif button == settings_button:
		print("footer settings pressed")
		settings_pressed.emit()
	elif button == achievements_button:
		print("footer achievements pressed")
		achievements_pressed.emit()


func _on_button_mouse_exited(button: TextureButton) -> void:
	if button == null:
		return

	if active_button != button:
		return

	active_button = null
	_release_button(button)


func _push_button_down(button: TextureButton) -> void:
	if button == null:
		return

	_kill_button_tween(button)

	var tween := create_tween()
	button_tweens[button] = tween
	tween.set_parallel(true)

	tween.tween_property(
		button,
		"modulate",
		BUTTON_PRESSED_MODULATE,
		BUTTON_PUSH_TIME
	)

	for child in button.get_children():
		if child is Control:
			var original_position: Vector2 = child_original_positions[button].get(child, child.position)

			tween.tween_property(
				child,
				"position",
				original_position + CHILD_PUSH_OFFSET,
				BUTTON_PUSH_TIME
			).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _release_button(button: TextureButton) -> void:
	if button == null:
		return

	_kill_button_tween(button)

	var tween := create_tween()
	button_tweens[button] = tween
	tween.set_parallel(true)

	tween.tween_property(
		button,
		"modulate",
		BUTTON_NORMAL_MODULATE,
		BUTTON_RELEASE_TIME
	)

	for child in button.get_children():
		if child is Control:
			var original_position: Vector2 = child_original_positions[button].get(child, child.position)

			tween.tween_property(
				child,
				"position",
				original_position,
				BUTTON_RELEASE_TIME
			).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _kill_button_tween(button: TextureButton) -> void:
	if button == null:
		return

	if not button_tweens.has(button):
		return

	var tween: Tween = button_tweens[button]

	if tween != null and tween.is_valid():
		tween.kill()

	button_tweens.erase(button)


func _is_mouse_inside_button(button: TextureButton) -> bool:
	if button == null:
		return false

	var mouse_position := get_global_mouse_position()
	var button_rect := Rect2(button.global_position, button.size)

	return button_rect.has_point(mouse_position)


func cache_original_values() -> void:
	_force_bottom_layout()
	footer_original_position = position


func prepare_intro_state() -> void:
	position = footer_original_position + Vector2(0, FOOTER_HIDDEN_OFFSET)


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

	var footer_out_position := footer_original_position + Vector2(0, FOOTER_HIDDEN_OFFSET)

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
