extends Control

const CLICK_SOUND: AudioStream = preload("res://assets/sounds/ui/generic_select.wav")
const START_GAME_SOUND: AudioStream = preload("res://assets/sounds/ui/main_menu_start_game.wav")
const CONTAINER_SHOW_SOUND: AudioStream = preload("res://assets/sounds/ui/main_menu_container_show.wav")

const MAIN_NORMAL_TEXTURE: Texture2D = preload("res://assets/interface/buttons/generic_button.png")
const MAIN_CLICKED_TEXTURE: Texture2D = preload("res://assets/interface/buttons/generic_button_clicked.png")

const CLICK_FEEDBACK_TIME := 0.045

const MENU_SLIDE_OFFSET := Vector2(0, -220)
const MENU_INTRO_TIME := 0.28
const MENU_OUTRO_TIME := 0.36
const MENU_INTRO_FADE_TIME := 0.28
const MENU_OUTRO_FADE_TIME := 0.26

const TEXT_NORMAL := Color(0.81960785, 0.57254905, 0.3764706, 1)
const TEXT_CLICKED := Color(0.90, 0.62, 0.39, 1)

const FOOTER_NORMAL_MODULATE := Color(1, 1, 1, 1)
const FOOTER_CLICK_MODULATE := Color(0.55, 0.55, 0.55, 1)

@onready var menu_content: Control = $MenuContent

@onready var start_game_button: Button = $MenuContent/MainMenuButtons/StartGameButton
@onready var profile_button: Button = $MenuContent/MainMenuButtons/ProfileButton
@onready var settings_button: Button = $MenuContent/MainMenuButtons/SettingsButton
@onready var exit_game_button: Button = $MenuContent/MainMenuButtons/ExitGameButton

@onready var credits_icon: TextureButton = $MenuContent/MainMenuFooter/CreditsIcon
@onready var ranking_icon: TextureButton = $MenuContent/MainMenuFooter/RankingIcon
@onready var achievements_icon: TextureButton = $MenuContent/MainMenuFooter/AchievementsIcon

var click_player: AudioStreamPlayer
var start_game_player: AudioStreamPlayer
var container_show_player: AudioStreamPlayer

var main_style_normal: StyleBoxTexture
var main_style_clicked: StyleBoxTexture

var main_button_tokens := {}

var menu_content_original_position := Vector2.ZERO
var menu_tween: Tween
var is_leaving_page := false


func _ready() -> void:
	_create_audio_players()
	_create_main_button_styles()
	_setup_buttons()

	await get_tree().process_frame

	menu_content_original_position = menu_content.position
	_play_menu_content_intro()


func _create_audio_players() -> void:
	click_player = AudioStreamPlayer.new()
	click_player.stream = CLICK_SOUND
	click_player.bus = "Master"
	add_child(click_player)

	start_game_player = AudioStreamPlayer.new()
	start_game_player.stream = START_GAME_SOUND
	start_game_player.bus = "Master"
	add_child(start_game_player)

	container_show_player = AudioStreamPlayer.new()
	container_show_player.stream = CONTAINER_SHOW_SOUND
	container_show_player.bus = "Master"
	add_child(container_show_player)


func _setup_buttons() -> void:
	_setup_main_button(start_game_button)
	_setup_main_button(profile_button)
	_setup_main_button(settings_button)
	_setup_main_button(exit_game_button)

	_setup_footer_button(credits_icon)
	_setup_footer_button(ranking_icon)
	_setup_footer_button(achievements_icon)

	start_game_button.pressed.connect(_on_start_game_pressed)
	profile_button.pressed.connect(_on_profile_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_game_button.pressed.connect(_on_exit_game_pressed)

	credits_icon.pressed.connect(_on_credits_pressed)
	ranking_icon.pressed.connect(_on_ranking_pressed)
	achievements_icon.pressed.connect(_on_achievements_pressed)


func _kill_menu_tween() -> void:
	if menu_tween != null and menu_tween.is_valid():
		menu_tween.kill()


func _play_menu_content_intro() -> void:
	if menu_content == null:
		return

	_kill_menu_tween()

	menu_content.position = menu_content_original_position + MENU_SLIDE_OFFSET
	menu_content.modulate = Color(1, 1, 1, 0)

	if container_show_player != null:
		container_show_player.stop()
		container_show_player.play()

	menu_tween = create_tween()
	menu_tween.set_parallel(true)

	menu_tween.tween_property(
		menu_content,
		"position",
		menu_content_original_position,
		MENU_INTRO_TIME
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	menu_tween.tween_property(
		menu_content,
		"modulate",
		Color(1, 1, 1, 1),
		MENU_INTRO_FADE_TIME
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _play_menu_content_outro() -> void:
	if menu_content == null:
		return

	_kill_menu_tween()

	menu_content.position = menu_content_original_position
	menu_content.modulate = Color(1, 1, 1, 1)

	menu_tween = create_tween()
	menu_tween.set_parallel(true)

	menu_tween.tween_property(
		menu_content,
		"position",
		menu_content_original_position + MENU_SLIDE_OFFSET,
		MENU_OUTRO_TIME
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	menu_tween.tween_property(
		menu_content,
		"modulate",
		Color(1, 1, 1, 0),
		MENU_OUTRO_FADE_TIME
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	await menu_tween.finished


func _create_main_button_styles() -> void:
	main_style_normal = _make_main_style(MAIN_NORMAL_TEXTURE)
	main_style_clicked = _make_main_style(MAIN_CLICKED_TEXTURE)


func _make_main_style(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 48.0
	style.texture_margin_top = 18.0
	style.texture_margin_right = 48.0
	style.texture_margin_bottom = 18.0
	return style


func _setup_main_button(button: Button) -> void:
	if button == null:
		return

	button.focus_mode = Control.FOCUS_NONE
	main_button_tokens[button] = 0

	_apply_main_button_normal(button)

	if not button.button_down.is_connected(_on_main_button_down.bind(button)):
		button.button_down.connect(_on_main_button_down.bind(button))

	if not button.button_up.is_connected(_on_main_button_up.bind(button)):
		button.button_up.connect(_on_main_button_up.bind(button))

	if not button.mouse_exited.is_connected(_on_main_button_mouse_exited.bind(button)):
		button.mouse_exited.connect(_on_main_button_mouse_exited.bind(button))


func _apply_main_button_normal(button: Button) -> void:
	_apply_main_button_style(button, main_style_normal, TEXT_NORMAL)


func _apply_main_button_clicked(button: Button) -> void:
	_apply_main_button_style(button, main_style_clicked, TEXT_CLICKED)


func _apply_main_button_style(button: Button, style: StyleBoxTexture, text_color: Color) -> void:
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("focus", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("disabled", style)

	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_focus_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)


func _on_main_button_down(button: Button) -> void:
	main_button_tokens[button] = int(main_button_tokens.get(button, 0)) + 1
	_apply_main_button_clicked(button)


func _on_main_button_up(button: Button) -> void:
	var token := int(main_button_tokens.get(button, 0)) + 1
	main_button_tokens[button] = token

	await get_tree().create_timer(CLICK_FEEDBACK_TIME).timeout

	if int(main_button_tokens.get(button, 0)) == token and not button.button_pressed:
		_apply_main_button_normal(button)


func _on_main_button_mouse_exited(button: Button) -> void:
	if button.button_pressed:
		return

	main_button_tokens[button] = int(main_button_tokens.get(button, 0)) + 1
	_apply_main_button_normal(button)


func _setup_footer_button(button: TextureButton) -> void:
	if button == null:
		return

	button.focus_mode = Control.FOCUS_NONE
	button.texture_hover = button.texture_normal
	button.texture_focused = button.texture_normal
	button.texture_pressed = button.texture_normal
	button.modulate = FOOTER_NORMAL_MODULATE

	if not button.button_down.is_connected(_on_footer_button_down.bind(button)):
		button.button_down.connect(_on_footer_button_down.bind(button))

	if not button.button_up.is_connected(_on_footer_button_up.bind(button)):
		button.button_up.connect(_on_footer_button_up.bind(button))

	if not button.mouse_exited.is_connected(_on_footer_button_mouse_exited.bind(button)):
		button.mouse_exited.connect(_on_footer_button_mouse_exited.bind(button))


func _on_footer_button_down(button: TextureButton) -> void:
	button.modulate = FOOTER_CLICK_MODULATE


func _on_footer_button_up(button: TextureButton) -> void:
	button.modulate = FOOTER_NORMAL_MODULATE


func _on_footer_button_mouse_exited(button: TextureButton) -> void:
	if button.button_pressed:
		return

	button.modulate = FOOTER_NORMAL_MODULATE


func _on_start_game_pressed() -> void:
	if is_leaving_page:
		return

	is_leaving_page = true

	if start_game_player != null:
		start_game_player.stop()
		start_game_player.play()

	await get_tree().create_timer(0.04).timeout
	await _play_menu_content_outro()

	var transition_manager: Node = get_node_or_null("/root/SceneTransitionManager")

	if transition_manager != null and transition_manager.has_method("change_scene_with_fade"):
		transition_manager.call(
			"change_scene_with_fade",
			"res://scenes/start_game/start_game.tscn",
			0.5,
			0.3
		)
		return

	get_tree().change_scene_to_file("res://scenes/start_game/start_game.tscn")


func _on_profile_pressed() -> void:
	if is_leaving_page:
		return

	_play_click_sound()


func _on_settings_pressed() -> void:
	if is_leaving_page:
		return

	_play_click_sound()


func _on_exit_game_pressed() -> void:
	if is_leaving_page:
		return

	is_leaving_page = true

	_play_click_sound()

	await get_tree().create_timer(0.08).timeout
	await _play_menu_content_outro()

	get_tree().quit()


func _on_credits_pressed() -> void:
	if is_leaving_page:
		return

	_play_click_sound()
	print("Credits pressed")


func _on_ranking_pressed() -> void:
	if is_leaving_page:
		return

	_play_click_sound()
	print("Ranking pressed")


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
