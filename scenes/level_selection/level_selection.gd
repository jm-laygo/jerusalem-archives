extends Control

const CLICK_SOUND: AudioStream = preload("res://assets/sounds/ui/generic_select.wav")
const START_GAME_SCENE := "res://scenes/start_game/start_game.tscn"
const LEVEL_GAMEPLAY_SCENE := "res://scenes/level_gameplay/level_gameplay.tscn"

const DESIGN_WIDTH := 1080.0
const DESIGN_HEIGHT := 1920.0

@onready var background: TextureRect = get_node_or_null("Background")
@onready var header: TextureRect = get_node_or_null("Header")
@onready var content_layer: Control = get_node_or_null("ContentLayer")
@onready var footer: Control = get_node_or_null("GameFooter")
@onready var play_button: TextureButton = get_node_or_null("ContentLayer/PlayButton")

var click_player: AudioStreamPlayer


func _ready() -> void:
	_setup_audio()
	connect_footer_signals()
	connect_play_button_signal()

	apply_phone_layout()

	await get_tree().process_frame
	apply_phone_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		apply_phone_layout()


func apply_phone_layout() -> void:
	var viewport_size := get_viewport_rect().size

	# IMPORTANT:
	# Use width scaling so the UI does not become too big or get cut.
	var scale_factor: float = viewport_size.x / DESIGN_WIDTH

	var phone_origin := Vector2(0.0, 0.0)

	# Root fills real viewport.
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0

	# Background fills the real screen.
	if background != null:
		background.anchor_left = 0.0
		background.anchor_top = 0.0
		background.anchor_right = 1.0
		background.anchor_bottom = 1.0
		background.offset_left = 0.0
		background.offset_top = 0.0
		background.offset_right = 0.0
		background.offset_bottom = 0.0
		background.scale = Vector2.ONE

	# Header: stick to top, scaled by width.
	place_design_node(header, phone_origin, scale_factor, -182, -31, 1342, 1263)

	# ContentLayer: design space scaled by width.
	if content_layer != null:
		content_layer.anchor_left = 0.0
		content_layer.anchor_top = 0.0
		content_layer.anchor_right = 0.0
		content_layer.anchor_bottom = 0.0
		content_layer.position = phone_origin
		content_layer.size = Vector2(DESIGN_WIDTH, DESIGN_HEIGHT)
		content_layer.scale = Vector2(scale_factor, scale_factor)

	# Play button: smaller and fully inside the 1080x1920 phone frame.
	if play_button != null:
		play_button.anchor_left = 0.0
		play_button.anchor_top = 0.0
		play_button.anchor_right = 0.0
		play_button.anchor_bottom = 0.0

		play_button.position = Vector2(735, 1060)
		play_button.size = Vector2(380, 145)
		play_button.scale = Vector2.ONE

		play_button.stretch_mode = TextureButton.STRETCH_SCALE
		play_button.ignore_texture_size = true

	# Footer: stick to actual bottom, not design bottom.
	place_bottom_design_node(footer, scale_factor, 0, 1080, 200)


func place_design_node(
	node: Control,
	phone_origin: Vector2,
	scale_factor: float,
	left: float,
	top: float,
	right: float,
	bottom: float
) -> void:
	if node == null:
		return

	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 0.0
	node.anchor_bottom = 0.0

	node.position = phone_origin + Vector2(left, top) * scale_factor
	node.size = Vector2(right - left, bottom - top)
	node.scale = Vector2(scale_factor, scale_factor)

func place_bottom_design_node(
	node: Control,
	scale_factor: float,
	left: float,
	right: float,
	height: float
) -> void:
	if node == null:
		return

	var viewport_size := get_viewport_rect().size
	var scaled_height := height * scale_factor

	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 0.0
	node.anchor_bottom = 0.0

	node.position = Vector2(left * scale_factor, viewport_size.y - scaled_height)
	node.size = Vector2((right - left), height)
	node.scale = Vector2(scale_factor, scale_factor)


func _setup_audio() -> void:
	click_player = AudioStreamPlayer.new()
	click_player.stream = CLICK_SOUND
	add_child(click_player)


func connect_footer_signals() -> void:
	if footer == null:
		print("GameFooter not found in LevelSelection.")
		return

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


func connect_play_button_signal() -> void:
	if play_button == null:
		print("PlayButton not found in LevelSelection.")
		return

	if not play_button.is_connected("pressed", Callable(self, "_on_play_button_pressed")):
		play_button.connect("pressed", Callable(self, "_on_play_button_pressed"))


func _on_footer_back_pressed() -> void:
	_play_click_sound()

	var transition_manager: Node = get_node_or_null("/root/SceneTransitionManager")

	if transition_manager != null and transition_manager.has_method("change_scene_with_fade"):
		transition_manager.call("change_scene_with_fade", START_GAME_SCENE, 0.5, 0.3)
		return

	get_tree().change_scene_to_file(START_GAME_SCENE)


func _on_footer_settings_pressed() -> void:
	print("Footer settings pressed in LevelSelection.")


func _on_footer_achievements_pressed() -> void:
	print("Footer achievements pressed in LevelSelection.")


func _play_click_sound() -> void:
	if click_player == null:
		return

	click_player.stop()
	click_player.play()


func _on_play_button_pressed() -> void:
	_play_click_sound()

	var transition_manager: Node = get_node_or_null("/root/SceneTransitionManager")

	if transition_manager != null and transition_manager.has_method("change_scene_with_fade"):
		transition_manager.call("change_scene_with_fade", LEVEL_GAMEPLAY_SCENE, 0.5, 0.3)
		return

	get_tree().change_scene_to_file(LEVEL_GAMEPLAY_SCENE)
