extends Control

signal difficulty_selected(difficulty_name: String)

const INTRO_OFFSET := Vector2(0, -60)
const INTRO_TIME := 0.28

const BUTTON_PRESSED_SCALE := Vector2(0.97, 0.94)
const BUTTON_PUSH_TIME := 0.045
const BUTTON_RELEASE_TIME := 0.10

@onready var buttons_container: VBoxContainer = $DifficultyButtons
@onready var easy_button: TextureButton = $DifficultyButtons/EasyButton
@onready var normal_button: TextureButton = $DifficultyButtons/NormalButton
@onready var hard_button: TextureButton = $DifficultyButtons/HardButton

var intro_tween: Tween
var intro_target_position := Vector2.ZERO

var button_original_scales := {}
var button_tweens := {}
var active_button: TextureButton = null


func _ready() -> void:
	await get_tree().process_frame

	_setup_buttons()
	prepare_intro_state()


func prepare_intro_state() -> void:
	intro_target_position = position
	position = intro_target_position + INTRO_OFFSET


func play_intro_animation() -> void:
	if intro_tween != null and intro_tween.is_valid():
		intro_tween.kill()

	intro_tween = create_tween()
	intro_tween.tween_property(
		self,
		"position",
		intro_target_position,
		INTRO_TIME
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _setup_buttons() -> void:
	_setup_difficulty_button(easy_button)
	_setup_difficulty_button(normal_button)
	_setup_difficulty_button(hard_button)


func _setup_difficulty_button(button: TextureButton) -> void:
	if button == null:
		return

	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.modulate = Color(1, 1, 1, 1)

	button_original_scales[button] = button.scale
	button.pivot_offset = button.size * 0.5

	for child in button.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if not button.button_down.is_connected(_on_button_down.bind(button)):
		button.button_down.connect(_on_button_down.bind(button))

	if not button.button_up.is_connected(_on_button_up.bind(button)):
		button.button_up.connect(_on_button_up.bind(button))

	if not button.mouse_exited.is_connected(_on_button_mouse_exited.bind(button)):
		button.mouse_exited.connect(_on_button_mouse_exited.bind(button))


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

	if button == easy_button:
		difficulty_selected.emit("Easy")
	elif button == normal_button:
		difficulty_selected.emit("Normal")
	elif button == hard_button:
		difficulty_selected.emit("Hard")


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

	var original_scale: Vector2 = button_original_scales.get(button, Vector2.ONE)
	var target_scale := original_scale * BUTTON_PRESSED_SCALE

	var tween := create_tween()
	button_tweens[button] = tween

	tween.tween_property(
		button,
		"scale",
		target_scale,
		BUTTON_PUSH_TIME
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _release_button(button: TextureButton) -> void:
	if button == null:
		return

	_kill_button_tween(button)

	var original_scale: Vector2 = button_original_scales.get(button, Vector2.ONE)

	var tween := create_tween()
	button_tweens[button] = tween

	tween.tween_property(
		button,
		"scale",
		original_scale,
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


func _is_mouse_inside_button(button: TextureButton) -> bool:
	if button == null:
		return false

	var mouse_position := get_global_mouse_position()
	var button_rect := Rect2(button.global_position, button.size)
	return button_rect.has_point(mouse_position)