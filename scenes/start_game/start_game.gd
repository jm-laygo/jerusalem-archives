extends Control

const CLICK_SOUND: AudioStream = preload("res://assets/sounds/ui/generic_select.wav")
const BACK_NEXT_SOUND: AudioStream = preload("res://assets/sounds/ui/start_game_next_back_button.wav")
const SELECT_SOUND: AudioStream = preload("res://assets/sounds/ui/start_game_select_chapter.wav")
const START_GAME_SHOW_SOUND: AudioStream = preload("res://assets/sounds/ui/start_game_show.wav")

const DIFFICULTY_POPUP_SCENE: PackedScene = preload("res://scenes/start_game/difficulty/difficulty_popup.tscn")

const TUTORIAL_HEADER: Texture2D = preload("res://assets/interface/ui/start_game/tutorial_header.png")
const TUTORIAL_ILLUSTRATION: Texture2D = preload("res://assets/interface/illustrations/tutorial_illustration.png")

const CHAPTER_ONE_HEADER: Texture2D = preload("res://assets/interface/ui/start_game/chapter_one_header.png")
const CHAPTER_TWO_HEADER: Texture2D = preload("res://assets/interface/ui/start_game/chapter_two_header.png")
const CHAPTER_THREE_HEADER: Texture2D = preload("res://assets/interface/ui/start_game/chapter_three_header.png")

const CHAPTER_ONE_ILLUSTRATION: Texture2D = preload("res://assets/interface/illustrations/chapter_one_illustration.png")
const CHAPTER_TWO_ILLUSTRATION: Texture2D = preload("res://assets/interface/illustrations/chapter_two_illustration.png")
const CHAPTER_THREE_ILLUSTRATION: Texture2D = preload("res://assets/interface/illustrations/chapter_three_illustration.png")

const CHAPTER_BACK_NORMAL_TEXTURE: Texture2D = preload("res://assets/interface/buttons/start_game_back_button.png")
const CHAPTER_BACK_CLICKED_TEXTURE: Texture2D = preload("res://assets/interface/buttons/start_game_back_button_clicked.png")

const CHAPTER_NEXT_NORMAL_TEXTURE: Texture2D = preload("res://assets/interface/buttons/start_game_next_button.png")
const CHAPTER_NEXT_CLICKED_TEXTURE: Texture2D = preload("res://assets/interface/buttons/start_game_next_button_clicked.png")

const SELECT_NORMAL_TEXTURE: Texture2D = preload("res://assets/interface/buttons/start_game_select_button.png")
const SELECT_CLICKED_TEXTURE: Texture2D = preload("res://assets/interface/buttons/start_game_select_button_clicked.png")

const BUTTON_NORMAL_MODULATE := Color(1, 1, 1, 1)
const BUTTON_PRESSED_MODULATE := Color(0.92, 0.92, 0.92, 1)

const TEXT_VISIBLE := Color(1, 1, 1, 1)
const TEXT_HIDDEN := Color(1, 1, 1, 0)

const SELECT_PRESSED_SCALE_MULTIPLIER := Vector2(0.96, 0.92)
const ARROW_PRESSED_SCALE_MULTIPLIER := Vector2(0.94, 0.94)

const INTRO_TIME := 0.36
const OUTRO_TIME := 0.34

const BUTTON_PRESS_TIME := 0.06
const BUTTON_RELEASE_TIME := 0.10

const PAGE_TEXT_OUT_TIME := 0.06
const PAGE_TEXT_IN_TIME := 0.08
const PAGE_TEXT_MOVE_DISTANCE := 18.0

@onready var footer: TextureRect = get_node_or_null("Footer") as TextureRect

@onready var back_button: TextureButton = get_node_or_null("Footer/FooterButtons/BackButton") as TextureButton
@onready var settings_button: TextureButton = get_node_or_null("Footer/FooterButtons/SettingsButton") as TextureButton
@onready var achievements_button: TextureButton = get_node_or_null("Footer/FooterButtons/AchievementsButton") as TextureButton

@onready var page_header: TextureRect = get_node_or_null("TutorialPage/TutorialHeader") as TextureRect
@onready var page_illustration: TextureRect = get_node_or_null("TutorialPage/TutorialIllustration") as TextureRect
@onready var page_illustration_next: TextureRect = get_node_or_null("TutorialPage/TutorialIllustrationNext") as TextureRect

@onready var level_title: Label = get_node_or_null("TutorialPage/LevelTitle") as Label
@onready var level_description: Label = get_node_or_null("TutorialPage/LevelDescription") as Label

@onready var chapter_back_button: TextureButton = get_node_or_null("TutorialPage/SelectChapterBackButton") as TextureButton
@onready var chapter_next_button: TextureButton = get_node_or_null("TutorialPage/SelectChapterNextButton") as TextureButton
@onready var select_button: TextureButton = get_node_or_null("TutorialPage/SelectButton") as TextureButton

var click_player: AudioStreamPlayer
var back_next_player: AudioStreamPlayer
var select_player: AudioStreamPlayer
var start_game_show_player: AudioStreamPlayer

var current_page := 0
var is_changing_page := false
var is_leaving_page := false

var footer_original_position := Vector2.ZERO
var header_original_position := Vector2.ZERO
var title_original_position := Vector2.ZERO
var description_original_position := Vector2.ZERO
var left_arrow_original_position := Vector2.ZERO
var right_arrow_original_position := Vector2.ZERO
var select_original_position := Vector2.ZERO

var left_arrow_original_scale := Vector2.ONE
var right_arrow_original_scale := Vector2.ONE
var select_original_scale := Vector2.ONE

var intro_tween: Tween
var outro_tween: Tween
var page_tween: Tween
var chapter_back_tween: Tween
var chapter_next_tween: Tween
var select_tween: Tween

var pages: Array[Dictionary] = [
	{
		"id": "tutorial",
		"header": TUTORIAL_HEADER,
		"illustration": TUTORIAL_ILLUSTRATION,
		"title": "Tutorial",
		"description": "Before reaching the Port of Jaffa, the journey begins upon open waters, where the first lessons unfold aboard a weathered vessel bound for Jerusalem."
	},
	{
		"id": "chapter_one",
		"header": CHAPTER_ONE_HEADER,
		"illustration": CHAPTER_ONE_ILLUSTRATION,
		"title": "Level 1 / 15",
		"description": "At Jaffa, every arrival is recorded through customs ledgers, merchant manifests, and cargo inspections. Multiple overlapping records create inconsistencies in ownership and movement."
	},
	{
		"id": "chapter_two",
		"header": CHAPTER_TWO_HEADER,
		"illustration": CHAPTER_TWO_ILLUSTRATION,
		"title": "Level 16 / 30",
		"description": "Within Jerusalem, records form a dense civic system, tax registries, market transactions, and population archives interconnected across institutions."
	},
	{
		"id": "chapter_three",
		"header": CHAPTER_THREE_HEADER,
		"illustration": CHAPTER_THREE_ILLUSTRATION,
		"title": "Level 31 / 45",
		"description": "At the sacred center, the final records are sealed within restricted archives. Royal decrees, religious manuscripts, and hidden registries converge into a tightly controlled system of truth."
	}
]


func _ready() -> void:
	_setup_audio()
	_setup_buttons()
	_update_page_instant()

	await get_tree().process_frame

	_cache_original_values()
	_prepare_intro_state()
	_play_start_game_show_sound()
	_play_intro_animation()


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


func _setup_buttons() -> void:
	_setup_footer_button(back_button)
	_setup_footer_button(settings_button)
	_setup_footer_button(achievements_button)

	_setup_chapter_button(
		chapter_back_button,
		CHAPTER_BACK_NORMAL_TEXTURE,
		CHAPTER_BACK_CLICKED_TEXTURE,
		_on_chapter_back_button_down,
		_on_chapter_back_button_up
	)

	_setup_chapter_button(
		chapter_next_button,
		CHAPTER_NEXT_NORMAL_TEXTURE,
		CHAPTER_NEXT_CLICKED_TEXTURE,
		_on_chapter_next_button_down,
		_on_chapter_next_button_up
	)

	_setup_chapter_button(
		select_button,
		SELECT_NORMAL_TEXTURE,
		SELECT_CLICKED_TEXTURE,
		_on_select_button_down,
		_on_select_button_up
	)

	_ignore_children_mouse(back_button)
	_ignore_children_mouse(settings_button)
	_ignore_children_mouse(achievements_button)
	_ignore_children_mouse(chapter_back_button)
	_ignore_children_mouse(chapter_next_button)
	_ignore_children_mouse(select_button)

	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)

	if settings_button != null:
		settings_button.pressed.connect(_on_settings_pressed)

	if achievements_button != null:
		achievements_button.pressed.connect(_on_achievements_pressed)

	if chapter_back_button != null:
		chapter_back_button.pressed.connect(_on_chapter_back_pressed)

	if chapter_next_button != null:
		chapter_next_button.pressed.connect(_on_chapter_next_pressed)

	if select_button != null:
		select_button.pressed.connect(_on_select_pressed)


func _setup_footer_button(button: TextureButton) -> void:
	if button == null:
		return

	button.focus_mode = Control.FOCUS_NONE
	button.modulate = BUTTON_NORMAL_MODULATE
	button.texture_hover = button.texture_normal
	button.texture_focused = button.texture_normal
	button.texture_disabled = button.texture_normal


func _setup_chapter_button(
	button: TextureButton,
	normal_texture: Texture2D,
	clicked_texture: Texture2D,
	down_callable: Callable,
	up_callable: Callable
) -> void:
	if button == null:
		return

	button.focus_mode = Control.FOCUS_NONE
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

	if not button.mouse_exited.is_connected(up_callable):
		button.mouse_exited.connect(up_callable)


func _ignore_children_mouse(button: TextureButton) -> void:
	if button == null:
		return

	for child in button.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _cache_original_values() -> void:
	if footer != null:
		footer_original_position = footer.position

	if page_header != null:
		header_original_position = page_header.position

	if level_title != null:
		title_original_position = level_title.position

	if level_description != null:
		description_original_position = level_description.position

	if chapter_back_button != null:
		left_arrow_original_position = chapter_back_button.position
		left_arrow_original_scale = chapter_back_button.scale
		chapter_back_button.pivot_offset = chapter_back_button.size / 2.0

	if chapter_next_button != null:
		right_arrow_original_position = chapter_next_button.position
		right_arrow_original_scale = chapter_next_button.scale
		chapter_next_button.pivot_offset = chapter_next_button.size / 2.0

	if select_button != null:
		select_original_position = select_button.position
		select_original_scale = select_button.scale
		select_button.pivot_offset = select_button.size / 2.0


func _prepare_intro_state() -> void:
	if footer != null:
		footer.position = footer_original_position + Vector2(0, 170)

	if page_header != null:
		page_header.position = Vector2(header_original_position.x, -page_header.size.y - 20.0)

	if chapter_back_button != null:
		chapter_back_button.position = Vector2(-chapter_back_button.size.x - 40.0, left_arrow_original_position.y)
		chapter_back_button.modulate = Color(1, 1, 1, 0)

	if chapter_next_button != null:
		chapter_next_button.position = Vector2(get_viewport_rect().size.x + 40.0, right_arrow_original_position.y)
		chapter_next_button.modulate = Color(1, 1, 1, 0)

	if select_button != null:
		select_button.position = select_original_position + Vector2(0, 80)
		select_button.modulate = Color(1, 1, 1, 0)

	if level_title != null:
		level_title.position = title_original_position
		level_title.modulate = TEXT_HIDDEN

	if level_description != null:
		level_description.position = description_original_position
		level_description.modulate = TEXT_HIDDEN

	if page_illustration != null:
		page_illustration.visible = true
		page_illustration.modulate = Color(1, 1, 1, 1)

	if page_illustration_next != null:
		page_illustration_next.visible = false
		page_illustration_next.modulate = Color(1, 1, 1, 0)


func _play_intro_animation() -> void:
	_kill_tween(intro_tween)

	intro_tween = create_tween()
	intro_tween.set_parallel(true)

	if page_header != null:
		intro_tween.tween_property(
			page_header,
			"position",
			header_original_position,
			INTRO_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if footer != null:
		intro_tween.tween_property(
			footer,
			"position",
			footer_original_position,
			INTRO_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if chapter_back_button != null:
		intro_tween.tween_property(
			chapter_back_button,
			"position",
			left_arrow_original_position,
			0.28
		).set_delay(0.04).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		intro_tween.tween_property(
			chapter_back_button,
			"modulate",
			BUTTON_NORMAL_MODULATE,
			0.18
		).set_delay(0.04)

	if chapter_next_button != null:
		intro_tween.tween_property(
			chapter_next_button,
			"position",
			right_arrow_original_position,
			0.28
		).set_delay(0.04).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		intro_tween.tween_property(
			chapter_next_button,
			"modulate",
			BUTTON_NORMAL_MODULATE,
			0.18
		).set_delay(0.04)

	if select_button != null:
		intro_tween.tween_property(
			select_button,
			"position",
			select_original_position,
			0.28
		).set_delay(0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		intro_tween.tween_property(
			select_button,
			"modulate",
			BUTTON_NORMAL_MODULATE,
			0.18
		).set_delay(0.06)

	if level_title != null:
		intro_tween.tween_property(
			level_title,
			"modulate",
			TEXT_VISIBLE,
			0.16
		).set_delay(0.08)

	if level_description != null:
		intro_tween.tween_property(
			level_description,
			"modulate",
			TEXT_VISIBLE,
			0.16
		).set_delay(0.10)


func _play_outro_animation() -> void:
	_kill_tween(outro_tween)
	_kill_button_tween("chapter_back")
	_kill_button_tween("chapter_next")
	_kill_button_tween("select")

	outro_tween = create_tween()
	outro_tween.set_parallel(true)

	var screen_size := get_viewport_rect().size

	var header_out_position := Vector2(
		header_original_position.x,
		-page_header.size.y - 20.0
	) if page_header != null else Vector2.ZERO

	var footer_out_position := footer_original_position + Vector2(0, 170)

	var left_arrow_out_position := Vector2(
		-chapter_back_button.size.x - 60.0,
		left_arrow_original_position.y
	) if chapter_back_button != null else Vector2.ZERO

	var right_arrow_out_position := Vector2(
		screen_size.x + chapter_next_button.size.x + 60.0,
		right_arrow_original_position.y
	) if chapter_next_button != null else Vector2.ZERO

	var select_out_position := Vector2(
		select_original_position.x,
		screen_size.y + select_button.size.y + 80.0
	) if select_button != null else Vector2.ZERO

	if page_illustration != null:
		page_illustration.visible = true
		page_illustration.modulate = Color(1, 1, 1, 1)

	if page_illustration_next != null:
		page_illustration_next.visible = false
		page_illustration_next.modulate = Color(1, 1, 1, 0)

	if page_header != null:
		outro_tween.tween_property(
			page_header,
			"position",
			header_out_position,
			OUTRO_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if footer != null:
		outro_tween.tween_property(
			footer,
			"position",
			footer_out_position,
			OUTRO_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if chapter_back_button != null:
		chapter_back_button.modulate = BUTTON_NORMAL_MODULATE
		chapter_back_button.scale = left_arrow_original_scale

		outro_tween.tween_property(
			chapter_back_button,
			"position",
			left_arrow_out_position,
			0.30
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		outro_tween.tween_property(
			chapter_back_button,
			"modulate",
			Color(1, 1, 1, 0),
			0.16
		)

	if chapter_next_button != null:
		chapter_next_button.modulate = BUTTON_NORMAL_MODULATE
		chapter_next_button.scale = right_arrow_original_scale

		outro_tween.tween_property(
			chapter_next_button,
			"position",
			right_arrow_out_position,
			0.30
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		outro_tween.tween_property(
			chapter_next_button,
			"modulate",
			Color(1, 1, 1, 0),
			0.16
		)

	if select_button != null:
		select_button.modulate = BUTTON_NORMAL_MODULATE
		select_button.scale = select_original_scale

		outro_tween.tween_property(
			select_button,
			"position",
			select_out_position,
			0.32
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		outro_tween.tween_property(
			select_button,
			"modulate",
			Color(1, 1, 1, 0),
			0.16
		)

	if level_title != null:
		outro_tween.tween_property(
			level_title,
			"modulate",
			TEXT_HIDDEN,
			0.10
		)

	if level_description != null:
		outro_tween.tween_property(
			level_description,
			"modulate",
			TEXT_HIDDEN,
			0.10
		)

	await outro_tween.finished


func _update_page_instant() -> void:
	var page: Dictionary = pages[current_page]

	if page_header != null:
		page_header.texture = page["header"]

	if page_illustration != null:
		page_illustration.texture = page["illustration"]
		page_illustration.visible = true
		page_illustration.modulate = Color(1, 1, 1, 1)

	if page_illustration_next != null:
		page_illustration_next.visible = false
		page_illustration_next.modulate = Color(1, 1, 1, 0)

	if level_title != null:
		level_title.text = page["title"]

	if level_description != null:
		level_description.text = page["description"]


func _change_page(direction: int) -> void:
	if is_changing_page or is_leaving_page:
		return

	is_changing_page = true
	_play_back_next_sound()
	_kill_tween(page_tween)

	var out_offset := Vector2(-PAGE_TEXT_MOVE_DISTANCE * direction, 0)
	var in_offset := Vector2(PAGE_TEXT_MOVE_DISTANCE * direction, 0)

	page_tween = create_tween()
	page_tween.set_parallel(true)

	if level_title != null:
		page_tween.tween_property(
			level_title,
			"modulate",
			TEXT_HIDDEN,
			PAGE_TEXT_OUT_TIME
		)

		page_tween.tween_property(
			level_title,
			"position",
			title_original_position + out_offset,
			PAGE_TEXT_OUT_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	if level_description != null:
		page_tween.tween_property(
			level_description,
			"modulate",
			TEXT_HIDDEN,
			PAGE_TEXT_OUT_TIME
		)

		page_tween.tween_property(
			level_description,
			"position",
			description_original_position + out_offset,
			PAGE_TEXT_OUT_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await page_tween.finished

	current_page += direction

	if current_page < 0:
		current_page = pages.size() - 1

	if current_page >= pages.size():
		current_page = 0

	var page: Dictionary = pages[current_page]

	if page_header != null:
		page_header.texture = page["header"]

	if page_illustration != null:
		page_illustration.texture = page["illustration"]
		page_illustration.visible = true
		page_illustration.modulate = Color(1, 1, 1, 1)

	if page_illustration_next != null:
		page_illustration_next.visible = false
		page_illustration_next.modulate = Color(1, 1, 1, 0)

	if level_title != null:
		level_title.text = page["title"]
		level_title.position = title_original_position + in_offset
		level_title.modulate = TEXT_HIDDEN

	if level_description != null:
		level_description.text = page["description"]
		level_description.position = description_original_position + in_offset
		level_description.modulate = TEXT_HIDDEN

	page_tween = create_tween()
	page_tween.set_parallel(true)

	if level_title != null:
		page_tween.tween_property(
			level_title,
			"position",
			title_original_position,
			PAGE_TEXT_IN_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		page_tween.tween_property(
			level_title,
			"modulate",
			TEXT_VISIBLE,
			PAGE_TEXT_IN_TIME
		)

	if level_description != null:
		page_tween.tween_property(
			level_description,
			"position",
			description_original_position,
			PAGE_TEXT_IN_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		page_tween.tween_property(
			level_description,
			"modulate",
			TEXT_VISIBLE,
			PAGE_TEXT_IN_TIME
		)

	await page_tween.finished

	if level_title != null:
		level_title.position = title_original_position
		level_title.modulate = TEXT_VISIBLE

	if level_description != null:
		level_description.position = description_original_position
		level_description.modulate = TEXT_VISIBLE

	if page_illustration != null:
		page_illustration.visible = true
		page_illustration.modulate = Color(1, 1, 1, 1)

	is_changing_page = false


func _on_chapter_back_button_down() -> void:
	if chapter_back_button == null:
		return

	chapter_back_button.texture_normal = CHAPTER_BACK_CLICKED_TEXTURE
	chapter_back_button.texture_hover = CHAPTER_BACK_CLICKED_TEXTURE

	var pressed_scale := left_arrow_original_scale * ARROW_PRESSED_SCALE_MULTIPLIER
	_press_button_animation(chapter_back_button, "chapter_back", pressed_scale)


func _on_chapter_back_button_up() -> void:
	if chapter_back_button == null:
		return

	chapter_back_button.texture_normal = CHAPTER_BACK_NORMAL_TEXTURE
	chapter_back_button.texture_hover = CHAPTER_BACK_NORMAL_TEXTURE

	_reset_button_animation(chapter_back_button, "chapter_back", left_arrow_original_scale)


func _on_chapter_next_button_down() -> void:
	if chapter_next_button == null:
		return

	chapter_next_button.texture_normal = CHAPTER_NEXT_CLICKED_TEXTURE
	chapter_next_button.texture_hover = CHAPTER_NEXT_CLICKED_TEXTURE

	var pressed_scale := right_arrow_original_scale * ARROW_PRESSED_SCALE_MULTIPLIER
	_press_button_animation(chapter_next_button, "chapter_next", pressed_scale)


func _on_chapter_next_button_up() -> void:
	if chapter_next_button == null:
		return

	chapter_next_button.texture_normal = CHAPTER_NEXT_NORMAL_TEXTURE
	chapter_next_button.texture_hover = CHAPTER_NEXT_NORMAL_TEXTURE

	_reset_button_animation(chapter_next_button, "chapter_next", right_arrow_original_scale)


func _on_select_button_down() -> void:
	if select_button == null:
		return

	select_button.texture_normal = SELECT_CLICKED_TEXTURE
	select_button.texture_hover = SELECT_CLICKED_TEXTURE

	var pressed_scale := select_original_scale * SELECT_PRESSED_SCALE_MULTIPLIER
	_press_button_animation(select_button, "select", pressed_scale)


func _on_select_button_up() -> void:
	if select_button == null:
		return

	select_button.texture_normal = SELECT_NORMAL_TEXTURE
	select_button.texture_hover = SELECT_NORMAL_TEXTURE

	_reset_button_animation(select_button, "select", select_original_scale)


func _press_button_animation(button: TextureButton, tween_name: String, pressed_scale: Vector2) -> void:
	if button == null:
		return

	_kill_button_tween(tween_name)

	var tween := create_tween()
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

	var tween := create_tween()
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


func _on_chapter_back_pressed() -> void:
	if is_leaving_page:
		return

	_on_chapter_back_button_up()
	_change_page(-1)


func _on_chapter_next_pressed() -> void:
	if is_leaving_page:
		return

	_on_chapter_next_button_up()
	_change_page(1)


func _on_select_pressed() -> void:
	if is_leaving_page or is_changing_page:
		return

	_on_select_button_up()
	_play_select_sound()

	var selected_page: Dictionary = pages[current_page]
	var page_id: String = selected_page["id"]

	print("Selected page: ", page_id)

	var popup_instance := DIFFICULTY_POPUP_SCENE.instantiate()
	add_child(popup_instance)

	if popup_instance.has_method("show_with_animation"):
		popup_instance.call("show_with_animation")
	else:
		popup_instance.popup_centered()


func _on_back_pressed() -> void:
	if is_leaving_page:
		return

	is_leaving_page = true

	_play_click_sound()

	await get_tree().create_timer(0.04).timeout
	await _play_outro_animation()

	var transition_manager: Node = get_node_or_null("/root/SceneTransitionManager")

	if transition_manager != null and transition_manager.has_method("change_scene_with_fade"):
		transition_manager.call(
			"change_scene_with_fade",
			"res://scenes/main_menu/main_menu.tscn",
			0.35,
			0.20
		)
		return

	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")


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
