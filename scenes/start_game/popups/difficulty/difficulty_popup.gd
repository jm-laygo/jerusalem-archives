extends Popup

signal closed

const CONTAINER_SHOW_SOUND: AudioStream = preload("res://assets/sounds/ui/main_menu_container_show.wav")
const CLICK_SOUND: AudioStream = preload("res://assets/sounds/ui/generic_select.wav")
const LEVEL_SELECTION_SCENE := "res://scenes/level_selection/level_selection.tscn"

const POPUP_SIZE := Vector2i(900, 1400)
const OVERLAY_COLOR := Color(0, 0, 0, 0.62)

const SHOW_TIME := 0.28
const HIDE_TIME := 0.24

const SHOW_OFFSET := Vector2(0, 80)
const HIDE_OFFSET := Vector2(0, 80)

@onready var container: Control = $DifficultyContainer

var container_show_player: AudioStreamPlayer
var click_player: AudioStreamPlayer

var overlay: ColorRect
var popup_tween: Tween
var overlay_tween: Tween

var container_original_position := Vector2.ZERO

var is_showing := false
var is_closing := false
var allow_hide := false


func _ready() -> void:
	exclusive = true

	_setup_audio()
	_connect_component_signals()

	if container != null:
		container_original_position = container.position
		container.modulate = Color(1, 1, 1, 0)

	if not popup_hide.is_connected(_on_popup_hide):
		popup_hide.connect(_on_popup_hide)


func _setup_audio() -> void:
	container_show_player = AudioStreamPlayer.new()
	container_show_player.stream = CONTAINER_SHOW_SOUND
	container_show_player.bus = "Master"
	add_child(container_show_player)

	click_player = AudioStreamPlayer.new()
	click_player.stream = CLICK_SOUND
	click_player.bus = "Master"
	add_child(click_player)


func _connect_component_signals() -> void:
	if container == null:
		push_error("DifficultyContainer not found.")
		return

	if container.has_signal("close_pressed"):
		container.connect("close_pressed", _on_close_pressed)
	else:
		push_error("DifficultyContainer has no close_pressed signal.")

	if container.has_signal("difficulty_selected"):
		container.connect("difficulty_selected", _on_difficulty_selected)
	else:
		push_error("DifficultyContainer has no difficulty_selected signal.")


func show_with_animation() -> void:
	if is_showing or is_closing:
		return

	is_showing = true
	is_closing = false
	allow_hide = false

	_kill_tweens()
	_create_overlay()

	popup_centered(POPUP_SIZE)
	await get_tree().process_frame

	if container != null:
		container_original_position = container.position
		container.position = container_original_position + SHOW_OFFSET
		container.modulate = Color(1, 1, 1, 0)

	if container_show_player != null:
		container_show_player.stop()
		container_show_player.play()

	popup_tween = create_tween()
	popup_tween.set_parallel(true)

	if overlay != null:
		overlay.color = Color(0, 0, 0, 0)
		overlay.visible = true
		popup_tween.tween_property(
			overlay,
			"color",
			OVERLAY_COLOR,
			SHOW_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if container != null:
		popup_tween.tween_property(
			container,
			"position",
			container_original_position,
			SHOW_TIME
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		popup_tween.tween_property(
			container,
			"modulate",
			Color(1, 1, 1, 1),
			SHOW_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await popup_tween.finished
	is_showing = false


func close_with_animation() -> void:
	if is_closing:
		return

	is_closing = true
	is_showing = false
	allow_hide = true

	_kill_tweens()
	_play_click_sound()

	popup_tween = create_tween()
	popup_tween.set_parallel(true)

	if container != null:
		popup_tween.tween_property(
			container,
			"position",
			container_original_position + HIDE_OFFSET,
			HIDE_TIME
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

		popup_tween.tween_property(
			container,
			"modulate",
			Color(1, 1, 1, 0),
			HIDE_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if overlay != null:
		popup_tween.tween_property(
			overlay,
			"color",
			Color(0, 0, 0, 0),
			HIDE_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await popup_tween.finished

	hide()
	_remove_overlay()

	is_closing = false
	allow_hide = false

	closed.emit()
	queue_free()


func _create_overlay() -> void:
	if overlay != null and is_instance_valid(overlay):
		return

	var parent_node := get_parent()
	if parent_node == null:
		return

	overlay = ColorRect.new()
	overlay.name = "DifficultyDarkOverlay"
	overlay.color = Color(0, 0, 0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = true

	parent_node.add_child(overlay)
	parent_node.move_child(overlay, get_index())

	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.offset_left = 0
	overlay.offset_top = 0
	overlay.offset_right = 0
	overlay.offset_bottom = 0


func _remove_overlay() -> void:
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()

	overlay = null


func _kill_tweens() -> void:
	if popup_tween != null and popup_tween.is_valid():
		popup_tween.kill()

	if overlay_tween != null and overlay_tween.is_valid():
		overlay_tween.kill()


func _on_popup_hide() -> void:
	if allow_hide:
		return

	if is_closing:
		return

	call_deferred("_force_restore_popup")


func _force_restore_popup() -> void:
	if is_closing:
		return

	_create_overlay()

	if overlay != null:
		overlay.color = OVERLAY_COLOR
		overlay.visible = true

	popup_centered(POPUP_SIZE)

	await get_tree().process_frame

	if container != null:
		container.position = container_original_position
		container.modulate = Color(1, 1, 1, 1)


func _on_close_pressed() -> void:
	close_with_animation()


func _on_difficulty_selected(difficulty_name: String) -> void:
	print("Selected difficulty: ", difficulty_name)
	await close_with_animation()

	var transition_manager: Node = get_node_or_null("/root/SceneTransitionManager")

	if transition_manager != null and transition_manager.has_method("change_scene_with_fade"):
		transition_manager.call("change_scene_with_fade", LEVEL_SELECTION_SCENE, 0.5, 0.3)
		return

	get_tree().change_scene_to_file(LEVEL_SELECTION_SCENE)


func _play_click_sound() -> void:
	if click_player == null:
		return

	click_player.stop()
	click_player.play()
