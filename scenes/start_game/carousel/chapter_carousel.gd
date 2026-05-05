extends Control

signal back_next_pressed
signal select_pressed(page_id: String)

const ChapterCarouselData = preload("res://scenes/start_game/carousel/chapter_carousel_data.gd")
const ChapterCarouselAnimator = preload("res://scenes/start_game/carousel/chapter_carousel_animator.gd")

@onready var chapter_header: TextureRect = $ChapterHeader
@onready var chapter_illustration: TextureRect = $ChapterIllustration
@onready var chapter_title: Label = $ChapterTitle
@onready var chapter_description: Label = $ChapterDescription
@onready var chapter_navigation: Control = $ChapterNavigation

var current_page := 0
var is_changing_page := false
var is_locked := false

var pages: Array[Dictionary] = []
var animator


func _ready() -> void:
	pages = ChapterCarouselData.get_pages()

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

	animator.cache_original_values()


func set_locked(value: bool) -> void:
	is_locked = value

	if chapter_navigation != null and chapter_navigation.has_method("set_locked"):
		chapter_navigation.call("set_locked", value)


func _connect_navigation_signals() -> void:
	if chapter_navigation == null:
		push_error("ChapterNavigation not found.")
		return

	if chapter_navigation.has_signal("previous_pressed"):
		chapter_navigation.connect("previous_pressed", _on_previous_pressed)

	if chapter_navigation.has_signal("next_pressed"):
		chapter_navigation.connect("next_pressed", _on_next_pressed)

	if chapter_navigation.has_signal("select_pressed"):
		chapter_navigation.connect("select_pressed", _on_select_pressed)


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
