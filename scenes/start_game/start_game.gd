extends Control

const CLICK_SOUND: AudioStream = preload("res://assets/sounds/ui/generic_select.wav")
const BACK_NEXT_SOUND: AudioStream = preload("res://assets/sounds/ui/start_game_next_back_button.wav")
const SELECT_SOUND: AudioStream = preload("res://assets/sounds/ui/start_game_select_chapter.wav")
const START_GAME_SHOW_SOUND: AudioStream = preload("res://assets/sounds/ui/start_game_show.wav")

const DIFFICULTY_POPUP_SCENE: PackedScene = preload("res://scenes/start_game/popups/difficulty/difficulty_popup.tscn")
const MAIN_MENU_SCENE := "res://scenes/main_menu/main_menu.tscn"

const DESIGN_WIDTH := 1080.0
const FOOTER_HEIGHT := 200.0

const SHARED_INTRO_TIME := 0.30
const SHARED_OUTRO_TIME := 0.30
const SELECT_INTRO_DELAY := 0.04

@onready var background: Control = $Background
@onready var chapter_carousel: Control = $ChapterCarousel
@onready var footer: Control = $Footer
@onready var popup_layer: Control = $PopupLayer

var click_player: AudioStreamPlayer
var back_next_player: AudioStreamPlayer
var select_player: AudioStreamPlayer
var start_game_show_player: AudioStreamPlayer

var is_leaving_page := false


func _ready() -> void:
	_setup_audio()
	_connect_component_signals()

	await get_tree().process_frame
	await get_tree().process_frame

	_force_start_game_layout()

	_prepare_intro_state()
	_play_start_game_show_sound()
	await _play_intro_animation()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_force_start_game_layout()
		call_deferred("_force_start_game_layout")


func _force_start_game_layout() -> void:
	_force_background_layout()
	_force_carousel_layout()
	_force_footer_layout()
	_force_popup_layer_layout()


func _force_background_layout() -> void:
	if background == null:
		return

	background.anchor_left = 0.0
	background.anchor_top = 0.0
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.offset_left = 0.0
	background.offset_top = 0.0
	background.offset_right = 0.0
	background.offset_bottom = 0.0
	background.scale = Vector2.ONE


func _force_carousel_layout() -> void:
	if chapter_carousel == null:
		return

	var viewport_height: float = get_viewport_rect().size.y
	var carousel_height: float = max(900.0, viewport_height - FOOTER_HEIGHT)

	chapter_carousel.anchor_left = 0.5
	chapter_carousel.anchor_right = 0.5
	chapter_carousel.anchor_top = 0.0
	chapter_carousel.anchor_bottom = 0.0

	chapter_carousel.offset_left = -DESIGN_WIDTH * 0.5
	chapter_carousel.offset_right = DESIGN_WIDTH * 0.5
	chapter_carousel.offset_top = 0.0
	chapter_carousel.offset_bottom = carousel_height
	chapter_carousel.scale = Vector2.ONE

	if chapter_carousel.has_method("force_design_layout"):
		chapter_carousel.call("force_design_layout", carousel_height)

	if chapter_carousel.has_method("force_navigation_visible"):
		chapter_carousel.call("force_navigation_visible")


func _force_footer_layout() -> void:
	if footer == null:
		return

	footer.anchor_left = 0.5
	footer.anchor_right = 0.5
	footer.anchor_top = 1.0
	footer.anchor_bottom = 1.0

	footer.offset_left = -DESIGN_WIDTH * 0.5
	footer.offset_right = DESIGN_WIDTH * 0.5
	footer.offset_top = -FOOTER_HEIGHT
	footer.offset_bottom = 0.0

	footer.scale = Vector2.ONE
	footer.grow_horizontal = Control.GROW_DIRECTION_BOTH
	footer.grow_vertical = Control.GROW_DIRECTION_BEGIN

	if footer.has_method("_force_bottom_layout"):
		footer.call("_force_bottom_layout")


func _force_popup_layer_layout() -> void:
	if popup_layer == null:
		return

	popup_layer.anchor_left = 0.0
	popup_layer.anchor_top = 0.0
	popup_layer.anchor_right = 1.0
	popup_layer.anchor_bottom = 1.0

	popup_layer.offset_left = 0.0
	popup_layer.offset_top = 0.0
	popup_layer.offset_right = 0.0
	popup_layer.offset_bottom = 0.0

	if popup_layer.get_child_count() == 0:
		popup_layer.visible = false
		popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _setup_audio() -> void:
	click_player = _create_audio_player(CLICK_SOUND)
	back_next_player = _create_audio_player(BACK_NEXT_SOUND)
	select_player = _create_audio_player(SELECT_SOUND)
	start_game_show_player = _create_audio_player(START_GAME_SHOW_SOUND)


func _create_audio_player(stream: AudioStream) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	return player


func _connect_component_signals() -> void:
	if chapter_carousel != null:
		if chapter_carousel.has_signal("back_next_pressed"):
			var back_next_callable := Callable(self, "_on_carousel_back_next_pressed")
			if not chapter_carousel.is_connected("back_next_pressed", back_next_callable):
				chapter_carousel.connect("back_next_pressed", back_next_callable)

		if chapter_carousel.has_signal("select_pressed"):
			var select_callable := Callable(self, "_on_carousel_select_pressed")
			if not chapter_carousel.is_connected("select_pressed", select_callable):
				chapter_carousel.connect("select_pressed", select_callable)

	if footer != null:
		if footer.has_signal("back_pressed"):
			var back_callable := Callable(self, "_on_footer_back_pressed")
			if not footer.is_connected("back_pressed", back_callable):
				footer.connect("back_pressed", back_callable)

		if footer.has_signal("settings_pressed"):
			var settings_callable := Callable(self, "_on_footer_settings_pressed")
			if not footer.is_connected("settings_pressed", settings_callable):
				footer.connect("settings_pressed", settings_callable)

		if footer.has_signal("achievements_pressed"):
			var achievements_callable := Callable(self, "_on_footer_achievements_pressed")
			if not footer.is_connected("achievements_pressed", achievements_callable):
				footer.connect("achievements_pressed", achievements_callable)


func _prepare_intro_state() -> void:
	if chapter_carousel != null and chapter_carousel.has_method("prepare_intro_state"):
		chapter_carousel.call("prepare_intro_state")

	if footer != null and footer.has_method("prepare_intro_state"):
		footer.call("prepare_intro_state")


func _play_start_game_show_sound() -> void:
	if start_game_show_player == null:
		return

	start_game_show_player.stop()
	start_game_show_player.play()


func _play_intro_animation() -> void:
	if chapter_carousel != null and chapter_carousel.has_method("play_intro_animation"):
		chapter_carousel.call("play_intro_animation")

	if footer != null and footer.has_method("play_intro_animation"):
		footer.call("play_intro_animation")

	await get_tree().create_timer(SHARED_INTRO_TIME).timeout

	if chapter_carousel != null and chapter_carousel.has_method("force_navigation_visible"):
		chapter_carousel.call("force_navigation_visible")


func _play_outro_animation() -> void:
	if chapter_carousel != null and chapter_carousel.has_method("play_outro_animation"):
		chapter_carousel.call("play_outro_animation")

	if footer != null and footer.has_method("play_outro_animation"):
		footer.call("play_outro_animation")

	await get_tree().create_timer(SHARED_OUTRO_TIME).timeout


func _on_carousel_back_next_pressed() -> void:
	_play_sound(back_next_player)


func _on_carousel_select_pressed(page_id: String) -> void:
	if is_leaving_page:
		return

	_play_sound(select_player)

	if chapter_carousel != null and chapter_carousel.has_method("play_select_intro_animation"):
		chapter_carousel.call("play_select_intro_animation")

	await get_tree().create_timer(SELECT_INTRO_DELAY).timeout
	_show_difficulty_popup(page_id)


func _show_difficulty_popup(page_id: String) -> void:
	if popup_layer == null:
		return

	_clear_popup_layer()

	var popup = DIFFICULTY_POPUP_SCENE.instantiate()
	popup_layer.add_child(popup)

	popup_layer.visible = true
	popup_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_layer.move_to_front()

	if popup.has_method("setup"):
		popup.call("setup", page_id)

	if popup.has_signal("closed"):
		var closed_callable := Callable(self, "_on_difficulty_popup_closed")
		if not popup.is_connected("closed", closed_callable):
			popup.connect("closed", closed_callable)

	if popup.has_signal("difficulty_selected"):
		var difficulty_callable := Callable(self, "_on_difficulty_selected")
		if not popup.is_connected("difficulty_selected", difficulty_callable):
			popup.connect("difficulty_selected", difficulty_callable)

	if popup.has_method("show_with_animation"):
		popup.call("show_with_animation")
	elif popup is Popup:
		popup.popup_centered(Vector2i(900, 1400))
	elif popup is Control:
		popup.show()


func _clear_popup_layer() -> void:
	if popup_layer == null:
		return

	for child in popup_layer.get_children():
		child.queue_free()


func _on_difficulty_popup_closed() -> void:
	if popup_layer != null:
		popup_layer.visible = false
		popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_clear_popup_layer()


func _on_difficulty_selected(page_id: String, difficulty: String) -> void:
	print("Selected chapter: ", page_id, " difficulty: ", difficulty)


func _on_footer_back_pressed() -> void:
	if is_leaving_page:
		return

	is_leaving_page = true
	_play_sound(click_player)

	await _play_outro_animation()

	var transition_manager: Node = get_node_or_null("/root/SceneTransitionManager")

	if transition_manager != null and transition_manager.has_method("change_scene_with_fade"):
		transition_manager.call("change_scene_with_fade", MAIN_MENU_SCENE, 0.5, 0.3)
		return

	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _on_footer_settings_pressed() -> void:
	_play_sound(click_player)
	print("Settings pressed")


func _on_footer_achievements_pressed() -> void:
	_play_sound(click_player)
	print("Achievements pressed")


func _play_sound(player: AudioStreamPlayer) -> void:
	if player == null:
		return

	player.stop()
	player.play()
