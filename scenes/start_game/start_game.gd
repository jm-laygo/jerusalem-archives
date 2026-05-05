extends Control

const CLICK_SOUND: AudioStream = preload("res://assets/sounds/ui/generic_select.wav")
const BACK_NEXT_SOUND: AudioStream = preload("res://assets/sounds/ui/start_game_next_back_button.wav")
const SELECT_SOUND: AudioStream = preload("res://assets/sounds/ui/start_game_select_chapter.wav")
const START_GAME_SHOW_SOUND: AudioStream = preload("res://assets/sounds/ui/start_game_show.wav")

const DIFFICULTY_POPUP_SCENE: PackedScene = preload("res://scenes/start_game/popups/difficulty/difficulty_popup.tscn")
const MAIN_MENU_SCENE := "res://scenes/main_menu/main_menu.tscn"

const SHARED_INTRO_TIME := 0.30
const SHARED_OUTRO_TIME := 0.30
const SELECT_INTRO_DELAY := 0.04

@onready var chapter_carousel: Control = get_node_or_null("ChapterCarousel") as Control
@onready var footer: Control = get_node_or_null("Footer") as Control
@onready var popup_layer: Control = get_node_or_null("PopupLayer") as Control

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

	_prepare_intro_state()
	_play_start_game_show_sound()
	await _play_intro_animation()


func _setup_audio() -> void:
	click_player = _create_audio_player(CLICK_SOUND)
	back_next_player = _create_audio_player(BACK_NEXT_SOUND)
	select_player = _create_audio_player(SELECT_SOUND)
	start_game_show_player = _create_audio_player(START_GAME_SHOW_SOUND)


func _create_audio_player(stream: AudioStream) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Master"
	add_child(player)
	return player


func _connect_component_signals() -> void:
	if chapter_carousel != null:
		if chapter_carousel.has_signal("back_next_pressed"):
			chapter_carousel.connect("back_next_pressed", _on_carousel_back_next_pressed)

		if chapter_carousel.has_signal("select_pressed"):
			chapter_carousel.connect("select_pressed", _on_carousel_select_pressed)
	else:
		push_error("ChapterCarousel not found in start_game.gd")

	if footer != null:
		if footer.has_signal("back_pressed"):
			footer.connect("back_pressed", _on_back_pressed)

		if footer.has_signal("settings_pressed"):
			footer.connect("settings_pressed", _on_settings_pressed)

		if footer.has_signal("achievements_pressed"):
			footer.connect("achievements_pressed", _on_achievements_pressed)
	else:
		push_error("Footer not found in start_game.gd")


func _prepare_intro_state() -> void:
	if chapter_carousel != null and chapter_carousel.has_method("prepare_intro_state"):
		chapter_carousel.call("prepare_intro_state")

	if footer != null and footer.has_method("prepare_intro_state"):
		footer.call("prepare_intro_state")





func _play_intro_animation() -> void:
	if chapter_carousel != null and chapter_carousel.has_method("play_intro_animation"):
		chapter_carousel.call("play_intro_animation")

	if footer != null and footer.has_method("play_intro_animation"):
		footer.call("play_intro_animation")

	await get_tree().create_timer(SELECT_INTRO_DELAY).timeout

	if chapter_carousel != null and chapter_carousel.has_method("play_select_intro_animation"):
		chapter_carousel.call("play_select_intro_animation")

	await get_tree().create_timer(SHARED_INTRO_TIME).timeout


func _play_outro_animation() -> void:
	if chapter_carousel != null and chapter_carousel.has_method("play_outro_animation"):
		chapter_carousel.call("play_outro_animation")

	if footer != null and footer.has_method("play_outro_animation"):
		footer.call("play_outro_animation")

	await get_tree().create_timer(SHARED_OUTRO_TIME).timeout


func _set_components_locked(value: bool) -> void:
	if chapter_carousel != null and chapter_carousel.has_method("set_locked"):
		chapter_carousel.call("set_locked", value)


func _on_carousel_back_next_pressed() -> void:
	if is_leaving_page:
		return

	_play_back_next_sound()


func _on_carousel_select_pressed(page_id: String) -> void:
	if is_leaving_page:
		return

	_play_select_sound()
	print("Selected carousel page: ", page_id)

	var popup_instance := DIFFICULTY_POPUP_SCENE.instantiate()

	if popup_layer != null:
		popup_layer.visible = true
		popup_layer.add_child(popup_instance)
	else:
		add_child(popup_instance)

	if popup_instance.has_method("show_with_animation"):
		popup_instance.call("show_with_animation")
	else:
		popup_instance.popup_centered()


func _on_back_pressed() -> void:
	print("start game back pressed")

	if is_leaving_page:
		return

	is_leaving_page = true
	_set_components_locked(true)

	_play_click_sound()

	await get_tree().create_timer(0.04).timeout
	await _play_outro_animation()

	var transition_manager: Node = get_node_or_null("/root/SceneTransitionManager")

	if transition_manager != null and transition_manager.has_method("change_scene_with_fade"):
		transition_manager.call(
			"change_scene_with_fade",
			MAIN_MENU_SCENE,
			0.65,
			0.35
		)
		return

	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _on_settings_pressed() -> void:
	if is_leaving_page:
		return

	_play_click_sound()
	print("Settings pressed")


func _on_achievements_pressed() -> void:
	if is_leaving_page:
		return

	_play_click_sound()
	print("Achievements pressed")


func _play_click_sound() -> void:
	if click_player == null:
		return

	click_player.stop()
	click_player.play()


func _play_back_next_sound() -> void:
	if back_next_player == null:
		return

	back_next_player.stop()
	back_next_player.play()


func _play_select_sound() -> void:
	if select_player == null:
		return

	select_player.stop()
	select_player.play()


func _play_start_game_show_sound() -> void:
	if start_game_show_player == null:
		return

	start_game_show_player.stop()
	start_game_show_player.play()
