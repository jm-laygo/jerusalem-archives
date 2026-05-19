extends Control

signal back_next_pressed
signal select_pressed(page_id: String)

const ChapterCarouselData = preload("res://scenes/start_game/carousel/chapter_carousel_data.gd")
const ChapterCarouselAnimator = preload("res://scenes/start_game/carousel/chapter_carousel_animator.gd")

const DESIGN_WIDTH := 1080.0
const DEFAULT_DESIGN_HEIGHT := 1720.0

@onready var chapter_header: TextureRect = $ChapterHeader
@onready var chapter_illustration: TextureRect = $ChapterIllustration
@onready var chapter_title: Label = $ChapterTitle
@onready var chapter_description: Label = $ChapterDescription
@onready var chapter_navigation: Control = $ChapterNavigation

var current_page := 0
var is_changing_page := false
var is_locked := false

var current_design_height := DEFAULT_DESIGN_HEIGHT
var pages: Array[Dictionary] = []
var animator


func _ready() -> void:
	pages = ChapterCarouselData.get_pages()

	force_design_layout(current_design_height)

	animator = ChapterCarouselAnimator.new()
	animator.setup(
		chapter_header,
		chapter_illustration,
		chapter_title,
		chapter_description
	)

	_connect_navigation_signals()
	update_page_instant()

	await get_tree().process_frame

	force_design_layout(current_design_height)

	if animator != null:
		animator.cache_original_values()

	force_navigation_visible()


func set_locked(value: bool) -> void:
	is_locked = value

	if chapter_navigation != null and chapter_navigation.has_method("set_locked"):
		chapter_navigation.call("set_locked", value)


func _connect_navigation_signals() -> void:
	if chapter_navigation == null:
		push_error("ChapterNavigation not found.")
		return

	if chapter_navigation.has_signal("previous_pressed"):
		var previous_callable := Callable(self, "_on_previous_pressed")
		if not chapter_navigation.is_connected("previous_pressed", previous_callable):
			chapter_navigation.connect("previous_pressed", previous_callable)

	if chapter_navigation.has_signal("next_pressed"):
		var next_callable := Callable(self, "_on_next_pressed")
		if not chapter_navigation.is_connected("next_pressed", next_callable):
			chapter_navigation.connect("next_pressed", next_callable)

	if chapter_navigation.has_signal("select_pressed"):
		var select_callable := Callable(self, "_on_select_pressed")
		if not chapter_navigation.is_connected("select_pressed", select_callable):
			chapter_navigation.connect("select_pressed", select_callable)


func prepare_intro_state() -> void:
	if animator != null:
		animator.prepare_intro_state()

	if chapter_navigation != null and chapter_navigation.has_method("prepare_intro_state"):
		chapter_navigation.call("prepare_intro_state")


func play_intro_animation() -> void:
	if animator != null:
		animator.play_intro_animation(self)

	if chapter_navigation != null and chapter_navigation.has_method("play_intro_animation"):
		chapter_navigation.call("play_intro_animation")

	await get_tree().create_timer(0.32).timeout
	force_navigation_visible()


func play_select_intro_animation() -> void:
	if chapter_navigation != null and chapter_navigation.has_method("play_select_intro_animation"):
		chapter_navigation.call("play_select_intro_animation")


func play_outro_animation() -> void:
	if animator != null:
		animator.play_outro_animation(self)

	if chapter_navigation != null and chapter_navigation.has_method("play_outro_animation"):
		chapter_navigation.call("play_outro_animation")


func update_page_instant() -> void:
	if pages.is_empty():
		return

	var page: Dictionary = pages[current_page]

	if chapter_header != null:
		chapter_header.texture = page["header"]

	if chapter_illustration != null:
		chapter_illustration.texture = page["illustration"]
		chapter_illustration.visible = true
		chapter_illustration.modulate = Color(1, 1, 1, 1)

	if chapter_title != null:
		chapter_title.text = page["title"]

	if chapter_description != null:
		chapter_description.text = page["description"]


func force_design_layout(design_height: float = DEFAULT_DESIGN_HEIGHT) -> void:
	current_design_height = max(900.0, design_height)

	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0

	offset_left = 0.0
	offset_top = 0.0
	offset_right = DESIGN_WIDTH
	offset_bottom = current_design_height

	position = Vector2.ZERO
	size = Vector2(DESIGN_WIDTH, current_design_height)
	scale = Vector2.ONE

	if chapter_illustration != null:
		chapter_illustration.anchor_left = 0.0
		chapter_illustration.anchor_top = 0.0
		chapter_illustration.anchor_right = 0.0
		chapter_illustration.anchor_bottom = 0.0
		chapter_illustration.position = Vector2(0.0, 0.0)
		chapter_illustration.custom_minimum_size = Vector2(DESIGN_WIDTH, current_design_height + 350.0)
		chapter_illustration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		chapter_illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	if chapter_header != null:
		chapter_header.anchor_left = 0.0
		chapter_header.anchor_top = 0.0
		chapter_header.anchor_right = 0.0
		chapter_header.anchor_bottom = 0.0
		chapter_header.position = Vector2.ZERO
		chapter_header.custom_minimum_size = Vector2(DESIGN_WIDTH, 171.0)
		chapter_header.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		chapter_header.stretch_mode = TextureRect.STRETCH_SCALE

	if chapter_title != null:
		chapter_title.anchor_left = 0.0
		chapter_title.anchor_top = 0.0
		chapter_title.anchor_right = 0.0
		chapter_title.anchor_bottom = 0.0
		chapter_title.position = Vector2(60.0, current_design_height * 0.60)
		chapter_title.size = Vector2(960.0, 126.0)
		chapter_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chapter_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		chapter_title.add_theme_font_size_override("font_size", 90)

	if chapter_description != null:
		chapter_description.anchor_left = 0.0
		chapter_description.anchor_top = 0.0
		chapter_description.anchor_right = 0.0
		chapter_description.anchor_bottom = 0.0
		chapter_description.position = Vector2(90.0, current_design_height * 0.70)
		chapter_description.size = Vector2(900.0, 190.0)
		chapter_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chapter_description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		chapter_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		chapter_description.add_theme_font_size_override("font_size", 40)

	if chapter_navigation != null:
		chapter_navigation.anchor_left = 0.0
		chapter_navigation.anchor_top = 0.0
		chapter_navigation.anchor_right = 0.0
		chapter_navigation.anchor_bottom = 0.0
		chapter_navigation.position = Vector2.ZERO
		chapter_navigation.size = Vector2(DESIGN_WIDTH, current_design_height)
		chapter_navigation.scale = Vector2.ONE

		if chapter_navigation.has_method("force_design_layout"):
			chapter_navigation.call("force_design_layout", current_design_height)

	force_navigation_visible()


func force_navigation_visible() -> void:
	if chapter_navigation == null:
		return

	chapter_navigation.visible = true
	chapter_navigation.modulate = Color(1, 1, 1, 1)
	chapter_navigation.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var select_button := chapter_navigation.find_child("SelectButton", true, false) as Control

	if select_button != null:
		select_button.visible = true
		select_button.modulate = Color(1, 1, 1, 1)
		select_button.mouse_filter = Control.MOUSE_FILTER_STOP
		select_button.position = Vector2(240.0, current_design_height - 180.0)
		select_button.size = Vector2(600.0, 265.0)
		select_button.scale = Vector2.ONE

	var previous_button := chapter_navigation.find_child("SelectChapterBackButton", true, false) as Control
	if previous_button != null:
		previous_button.visible = true
		previous_button.modulate = Color(1, 1, 1, 1)

	var next_button := chapter_navigation.find_child("SelectChapterNextButton", true, false) as Control
	if next_button != null:
		next_button.visible = true
		next_button.modulate = Color(1, 1, 1, 1)


func _change_page(direction: int) -> void:
	if is_changing_page or is_locked:
		return

	is_changing_page = true
	back_next_pressed.emit()

	if animator != null:
		await animator.play_page_out(self, direction)

	current_page += direction

	if current_page < 0:
		current_page = pages.size() - 1

	if current_page >= pages.size():
		current_page = 0

	update_page_instant()

	if animator != null:
		animator.prepare_page_in(direction)
		await animator.play_page_in(self)
		animator.restore_text_state()

	force_navigation_visible()
	is_changing_page = false


func _on_previous_pressed() -> void:
	_change_page(-1)


func _on_next_pressed() -> void:
	_change_page(1)


func _on_select_pressed() -> void:
	if is_locked or is_changing_page:
		return

	if pages.is_empty():
		return

	var selected_page: Dictionary = pages[current_page]
	var page_id: String = selected_page["id"]

	select_pressed.emit(page_id)
