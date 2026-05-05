extends Control

signal previous_pressed
signal next_pressed
signal select_pressed

const CHAPTER_BACK_NORMAL_TEXTURE: Texture2D = preload("res://assets/interface/buttons/start_game_back_button.png")
const CHAPTER_BACK_CLICKED_TEXTURE: Texture2D = preload("res://assets/interface/buttons/start_game_back_button_clicked.png")

const CHAPTER_NEXT_NORMAL_TEXTURE: Texture2D = preload("res://assets/interface/buttons/start_game_next_button.png")
const CHAPTER_NEXT_CLICKED_TEXTURE: Texture2D = preload("res://assets/interface/buttons/start_game_next_button_clicked.png")

const SELECT_NORMAL_TEXTURE: Texture2D = preload("res://assets/interface/buttons/start_game_select_button.png")
const SELECT_CLICKED_TEXTURE: Texture2D = preload("res://assets/interface/buttons/start_game_select_button_clicked.png")

const BUTTON_NORMAL_MODULATE := Color(1, 1, 1, 1)
const BUTTON_PRESSED_MODULATE := Color(0.92, 0.92, 0.92, 1)

const SELECT_PRESSED_SCALE_MULTIPLIER := Vector2(0.96, 0.92)
const ARROW_PRESSED_SCALE_MULTIPLIER := Vector2(0.94, 0.94)

const BUTTON_PRESS_TIME := 0.06
const BUTTON_RELEASE_TIME := 0.10

const INTRO_TIME := 0.30
const OUTRO_TIME := 0.30

const SELECT_INTRO_DELAY := 0.10
const SELECT_INTRO_TIME := 0.30

const SELECT_BELOW_SCREEN_EXTRA := 160.0
const SELECT_TARGET_BOTTOM_GAP := 120.0

@onready var chapter_back_button: TextureButton = $SelectChapterBackButton
@onready var chapter_next_button: TextureButton = $SelectChapterNextButton
@onready var select_button: TextureButton = $SelectButton

var is_locked := false
var active_button: TextureButton = null

var left_arrow_original_position := Vector2.ZERO
var right_arrow_original_position := Vector2.ZERO

var select_target_position := Vector2.ZERO
var select_start_position := Vector2.ZERO

var left_arrow_original_scale := Vector2.ONE
var right_arrow_original_scale := Vector2.ONE
var select_original_scale := Vector2.ONE

var intro_tween: Tween
var outro_tween: Tween
var chapter_back_tween: Tween
var chapter_next_tween: Tween
var select_tween: Tween


func _ready() -> void:
	_setup_buttons()

	await get_tree().process_frame

	cache_original_values()


func set_locked(value: bool) -> void:
	is_locked = value


func _setup_buttons() -> void:
	_setup_chapter_button(
		chapter_back_button,
		CHAPTER_BACK_NORMAL_TEXTURE,
		CHAPTER_BACK_CLICKED_TEXTURE,
		_on_chapter_back_button_down,
		_on_chapter_back_button_up,
		_on_chapter_back_button_exited
	)

	_setup_chapter_button(
		chapter_next_button,
		CHAPTER_NEXT_NORMAL_TEXTURE,
		CHAPTER_NEXT_CLICKED_TEXTURE,
		_on_chapter_next_button_down,
		_on_chapter_next_button_up,
		_on_chapter_next_button_exited
	)

	_setup_chapter_button(
		select_button,
		SELECT_NORMAL_TEXTURE,
		SELECT_CLICKED_TEXTURE,
		_on_select_button_down,
		_on_select_button_up,
		_on_select_button_exited
	)

	_ignore_children_mouse(chapter_back_button)
	_ignore_children_mouse(chapter_next_button)
	_ignore_children_mouse(select_button)


func _setup_chapter_button(
	button: TextureButton,
	normal_texture: Texture2D,
	clicked_texture: Texture2D,
	down_callable: Callable,
	up_callable: Callable,
	exit_callable: Callable
) -> void:
	if button == null:
		return

	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.modulate = BUTTON_NORMAL_MODULATE

	button.texture_normal = normal_texture
	button.texture_hover = normal_texture
	button.texture_pressed = clicked_texture
	button.texture_focused = normal_texture
	button.texture_disabled = normal_texture

	if not button.button_down.is_connected(down_callable):
		button.button_down.connect(down_callable)

	if not button.button_up.is_connected(up_callable):
		button.button_up.connect(up_callable)

	if not button.mouse_exited.is_connected(exit_callable):
		button.mouse_exited.connect(exit_callable)


func _ignore_children_mouse(button: TextureButton) -> void:
	if button == null:
		return

	for child in button.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE


func cache_original_values() -> void:
	var screen_size := get_viewport_rect().size

	if chapter_back_button != null:
		left_arrow_original_position = chapter_back_button.position
		left_arrow_original_scale = chapter_back_button.scale
		chapter_back_button.pivot_offset = chapter_back_button.size / 2.0

	if chapter_next_button != null:
		right_arrow_original_position = chapter_next_button.position
		right_arrow_original_scale = chapter_next_button.scale
		chapter_next_button.pivot_offset = chapter_next_button.size / 2.0

	if select_button != null:
		select_original_scale = select_button.scale
		select_button.pivot_offset = select_button.size / 2.0

		# this is the visible final position, even if you placed it outside in the editor
		select_target_position = Vector2(
			(screen_size.x - select_button.size.x) / 2.0,
			screen_size.y - select_button.size.y - SELECT_TARGET_BOTTOM_GAP
		)

		# this is the hidden start position below the phone
		select_start_position = Vector2(
			select_target_position.x,
			screen_size.y + select_button.size.y + SELECT_BELOW_SCREEN_EXTRA
		)


func prepare_intro_state() -> void:
	var screen_size := get_viewport_rect().size

	if chapter_back_button != null:
		chapter_back_button.position = Vector2(
			-chapter_back_button.size.x - 40.0,
			left_arrow_original_position.y
		)
		chapter_back_button.modulate = Color(1, 1, 1, 0)

	if chapter_next_button != null:
		chapter_next_button.position = Vector2(
			screen_size.x + 40.0,
			right_arrow_original_position.y
		)
		chapter_next_button.modulate = Color(1, 1, 1, 0)

	if select_button != null:
		select_button.position = select_start_position
		select_button.modulate = Color(1, 1, 1, 0)


func play_intro_animation() -> void:
	_kill_tween(intro_tween)

	intro_tween = get_tree().create_tween()
	intro_tween.set_parallel(true)

	if chapter_back_button != null:
		intro_tween.tween_property(
			chapter_back_button,
			"position",
			left_arrow_original_position,
			INTRO_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		intro_tween.tween_property(
			chapter_back_button,
			"modulate",
			BUTTON_NORMAL_MODULATE,
			0.20
		)

	if chapter_next_button != null:
		intro_tween.tween_property(
			chapter_next_button,
			"position",
			right_arrow_original_position,
			INTRO_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		intro_tween.tween_property(
			chapter_next_button,
			"modulate",
			BUTTON_NORMAL_MODULATE,
			0.20
		)

func play_select_intro_animation() -> void:
	if select_button == null:
		return

	_kill_button_tween("select")

	select_tween = get_tree().create_tween()
	select_tween.set_parallel(true)

	select_tween.tween_property(
		select_button,
		"position",
		select_target_position,
		SELECT_INTRO_TIME
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	select_tween.tween_property(
		select_button,
		"modulate",
		BUTTON_NORMAL_MODULATE,
		0.16
	)


func play_outro_animation() -> void:
	outro_tween = _create_outro_tween()

	if outro_tween != null:
		await outro_tween.finished


func _create_outro_tween() -> Tween:
	_kill_tween(outro_tween)
	_kill_button_tween("chapter_back")
	_kill_button_tween("chapter_next")
	_kill_button_tween("select")

	outro_tween = get_tree().create_tween()
	outro_tween.set_parallel(true)

	var screen_size := get_viewport_rect().size

	var left_arrow_out_position := Vector2.ZERO
	if chapter_back_button != null:
		left_arrow_out_position = Vector2(
			-chapter_back_button.size.x - 60.0,
			left_arrow_original_position.y
		)

	var right_arrow_out_position := Vector2.ZERO
	if chapter_next_button != null:
		right_arrow_out_position = Vector2(
			screen_size.x + chapter_next_button.size.x + 60.0,
			right_arrow_original_position.y
		)

	var select_out_position := Vector2.ZERO
	if select_button != null:
		select_out_position = Vector2(
			select_target_position.x,
			screen_size.y + select_button.size.y + SELECT_BELOW_SCREEN_EXTRA
		)

	if chapter_back_button != null:
		chapter_back_button.modulate = BUTTON_NORMAL_MODULATE
		chapter_back_button.scale = left_arrow_original_scale

		outro_tween.tween_property(
			chapter_back_button,
			"position",
			left_arrow_out_position,
			OUTRO_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		outro_tween.tween_property(
			chapter_back_button,
			"modulate",
			Color(1, 1, 1, 0),
			0.18
		)

	if chapter_next_button != null:
		chapter_next_button.modulate = BUTTON_NORMAL_MODULATE
		chapter_next_button.scale = right_arrow_original_scale

		outro_tween.tween_property(
			chapter_next_button,
			"position",
			right_arrow_out_position,
			OUTRO_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		outro_tween.tween_property(
			chapter_next_button,
			"modulate",
			Color(1, 1, 1, 0),
			0.18
		)

	if select_button != null:
		select_button.modulate = BUTTON_NORMAL_MODULATE
		select_button.scale = select_original_scale

		outro_tween.tween_property(
			select_button,
			"position",
			select_out_position,
			OUTRO_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		outro_tween.tween_property(
			select_button,
			"modulate",
			Color(1, 1, 1, 0),
			0.18
		)

	return outro_tween


func _on_chapter_back_button_down() -> void:
	if is_locked or chapter_back_button == null:
		return

	active_button = chapter_back_button

	chapter_back_button.texture_normal = CHAPTER_BACK_CLICKED_TEXTURE
	chapter_back_button.texture_hover = CHAPTER_BACK_CLICKED_TEXTURE

	var pressed_scale := left_arrow_original_scale * ARROW_PRESSED_SCALE_MULTIPLIER
	_press_button_animation(chapter_back_button, "chapter_back", pressed_scale)


func _on_chapter_back_button_up() -> void:
	if chapter_back_button == null:
		return

	var should_click := active_button == chapter_back_button and _is_mouse_inside_button(chapter_back_button)

	active_button = null
	_reset_chapter_back_button()

	if should_click and not is_locked:
		previous_pressed.emit()


func _on_chapter_back_button_exited() -> void:
	if active_button != chapter_back_button:
		return

	active_button = null
	_reset_chapter_back_button()


func _on_chapter_next_button_down() -> void:
	if is_locked or chapter_next_button == null:
		return

	active_button = chapter_next_button

	chapter_next_button.texture_normal = CHAPTER_NEXT_CLICKED_TEXTURE
	chapter_next_button.texture_hover = CHAPTER_NEXT_CLICKED_TEXTURE

	var pressed_scale := right_arrow_original_scale * ARROW_PRESSED_SCALE_MULTIPLIER
	_press_button_animation(chapter_next_button, "chapter_next", pressed_scale)


func _on_chapter_next_button_up() -> void:
	if chapter_next_button == null:
		return

	var should_click := active_button == chapter_next_button and _is_mouse_inside_button(chapter_next_button)

	active_button = null
	_reset_chapter_next_button()

	if should_click and not is_locked:
		next_pressed.emit()


func _on_chapter_next_button_exited() -> void:
	if active_button != chapter_next_button:
		return

	active_button = null
	_reset_chapter_next_button()


func _on_select_button_down() -> void:
	if is_locked or select_button == null:
		return

	active_button = select_button

	select_button.texture_normal = SELECT_CLICKED_TEXTURE
	select_button.texture_hover = SELECT_CLICKED_TEXTURE

	var pressed_scale := select_original_scale * SELECT_PRESSED_SCALE_MULTIPLIER
	_press_button_animation(select_button, "select", pressed_scale)


func _on_select_button_up() -> void:
	if select_button == null:
		return

	var should_click := active_button == select_button and _is_mouse_inside_button(select_button)

	active_button = null
	_reset_select_button()

	if should_click and not is_locked:
		select_pressed.emit()


func _on_select_button_exited() -> void:
	if active_button != select_button:
		return

	active_button = null
	_reset_select_button()


func _reset_chapter_back_button() -> void:
	if chapter_back_button == null:
		return

	chapter_back_button.texture_normal = CHAPTER_BACK_NORMAL_TEXTURE
	chapter_back_button.texture_hover = CHAPTER_BACK_NORMAL_TEXTURE
	_reset_button_animation(chapter_back_button, "chapter_back", left_arrow_original_scale)


func _reset_chapter_next_button() -> void:
	if chapter_next_button == null:
		return

	chapter_next_button.texture_normal = CHAPTER_NEXT_NORMAL_TEXTURE
	chapter_next_button.texture_hover = CHAPTER_NEXT_NORMAL_TEXTURE
	_reset_button_animation(chapter_next_button, "chapter_next", right_arrow_original_scale)


func _reset_select_button() -> void:
	if select_button == null:
		return

	select_button.texture_normal = SELECT_NORMAL_TEXTURE
	select_button.texture_hover = SELECT_NORMAL_TEXTURE
	_reset_button_animation(select_button, "select", select_original_scale)


func _is_mouse_inside_button(button: TextureButton) -> bool:
	if button == null:
		return false

	var mouse_position := get_global_mouse_position()
	var button_rect := Rect2(button.global_position, button.size)
	return button_rect.has_point(mouse_position)


func _press_button_animation(button: TextureButton, tween_name: String, pressed_scale: Vector2) -> void:
	if button == null:
		return

	_kill_button_tween(tween_name)

	var tween := get_tree().create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		button,
		"scale",
		pressed_scale,
		BUTTON_PRESS_TIME
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		button,
		"modulate",
		BUTTON_PRESSED_MODULATE,
		BUTTON_PRESS_TIME
	)

	_set_button_tween(tween_name, tween)


func _reset_button_animation(button: TextureButton, tween_name: String, original_scale: Vector2) -> void:
	if button == null:
		return

	_kill_button_tween(tween_name)

	var tween := get_tree().create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		button,
		"scale",
		original_scale,
		BUTTON_RELEASE_TIME
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		button,
		"modulate",
		BUTTON_NORMAL_MODULATE,
		BUTTON_RELEASE_TIME
	)

	_set_button_tween(tween_name, tween)


func _kill_button_tween(tween_name: String) -> void:
	if tween_name == "chapter_back":
		_kill_tween(chapter_back_tween)

	elif tween_name == "chapter_next":
		_kill_tween(chapter_next_tween)

	elif tween_name == "select":
		_kill_tween(select_tween)


func _set_button_tween(tween_name: String, tween: Tween) -> void:
	if tween_name == "chapter_back":
		chapter_back_tween = tween

	elif tween_name == "chapter_next":
		chapter_next_tween = tween

	elif tween_name == "select":
		select_tween = tween


func _kill_tween(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
