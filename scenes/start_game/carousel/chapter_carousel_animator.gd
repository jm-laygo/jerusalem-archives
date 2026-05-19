extends RefCounted

const TEXT_VISIBLE := Color(1, 1, 1, 1)
const TEXT_HIDDEN := Color(1, 1, 1, 0)

const INTRO_TIME := 0.22
const OUTRO_TIME := 0.34

const PAGE_TEXT_OUT_TIME := 0.06
const PAGE_TEXT_IN_TIME := 0.08
const PAGE_TEXT_MOVE_DISTANCE := 18.0

var chapter_header: TextureRect
var chapter_illustration: TextureRect
var chapter_title: Label
var chapter_description: Label

var header_original_position := Vector2.ZERO
var title_original_position := Vector2.ZERO
var description_original_position := Vector2.ZERO

var intro_tween: Tween
var outro_tween: Tween
var page_tween: Tween


func setup(
	header_node: TextureRect,
	illustration_node: TextureRect,
	title_node: Label,
	description_node: Label
) -> void:
	chapter_header = header_node
	chapter_illustration = illustration_node
	chapter_title = title_node
	chapter_description = description_node


func cache_original_values() -> void:
	if chapter_header != null:
		header_original_position = chapter_header.position

	if chapter_title != null:
		title_original_position = chapter_title.position

	if chapter_description != null:
		description_original_position = chapter_description.position


func prepare_intro_state() -> void:
	if chapter_header != null:
		chapter_header.position = Vector2(header_original_position.x, -chapter_header.size.y - 20.0)

	if chapter_title != null:
		chapter_title.position = title_original_position
		chapter_title.modulate = TEXT_HIDDEN

	if chapter_description != null:
		chapter_description.position = description_original_position
		chapter_description.modulate = TEXT_HIDDEN

	if chapter_illustration != null:
		chapter_illustration.visible = true
		chapter_illustration.modulate = TEXT_VISIBLE


func play_intro_animation(owner: Node) -> void:
	_kill_tween(intro_tween)

	intro_tween = owner.get_tree().create_tween()
	intro_tween.set_parallel(true)

	if chapter_header != null:
		intro_tween.tween_property(
			chapter_header,
			"position",
			header_original_position,
			0.30
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if chapter_title != null:
		intro_tween.tween_property(
			chapter_title,
			"modulate",
			TEXT_VISIBLE,
			0.20
		)

	if chapter_description != null:
		intro_tween.tween_property(
			chapter_description,
			"modulate",
			TEXT_VISIBLE,
			0.20
		)


func play_outro_animation(owner: Node) -> void:
	_kill_tween(outro_tween)

	outro_tween = owner.get_tree().create_tween()
	outro_tween.set_parallel(true)

	var header_out_position := Vector2(
		header_original_position.x,
		-chapter_header.size.y - 20.0
	) if chapter_header != null else Vector2.ZERO

	if chapter_header != null:
		outro_tween.tween_property(
			chapter_header,
			"position",
			header_out_position,
			0.30
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if chapter_title != null:
		outro_tween.tween_property(
			chapter_title,
			"modulate",
			TEXT_HIDDEN,
			0.16
		)

	if chapter_description != null:
		outro_tween.tween_property(
			chapter_description,
			"modulate",
			TEXT_HIDDEN,
			0.16
		)


func _create_outro_tween(owner: Node) -> Tween:
	_kill_tween(outro_tween)

	outro_tween = owner.create_tween()
	outro_tween.set_parallel(true)

	var header_out_position := Vector2(
		header_original_position.x,
		-chapter_header.size.y - 20.0
	) if chapter_header != null else Vector2.ZERO

	if chapter_header != null:
		outro_tween.tween_property(
			chapter_header,
			"position",
			header_out_position,
			OUTRO_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if chapter_title != null:
		outro_tween.tween_property(
			chapter_title,
			"modulate",
			TEXT_HIDDEN,
			0.10
		)

	if chapter_description != null:
		outro_tween.tween_property(
			chapter_description,
			"modulate",
			TEXT_HIDDEN,
			0.10
		)

	return outro_tween


func play_page_out(owner: Node, direction: int) -> void:
	_kill_tween(page_tween)

	var out_offset := Vector2(-PAGE_TEXT_MOVE_DISTANCE * direction, 0)

	page_tween = owner.create_tween()
	page_tween.set_parallel(true)

	if chapter_title != null:
		page_tween.tween_property(
			chapter_title,
			"modulate",
			TEXT_HIDDEN,
			PAGE_TEXT_OUT_TIME
		)

		page_tween.tween_property(
			chapter_title,
			"position",
			title_original_position + out_offset,
			PAGE_TEXT_OUT_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	if chapter_description != null:
		page_tween.tween_property(
			chapter_description,
			"modulate",
			TEXT_HIDDEN,
			PAGE_TEXT_OUT_TIME
		)

		page_tween.tween_property(
			chapter_description,
			"position",
			description_original_position + out_offset,
			PAGE_TEXT_OUT_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await page_tween.finished


func prepare_page_in(direction: int) -> void:
	var in_offset := Vector2(PAGE_TEXT_MOVE_DISTANCE * direction, 0)

	if chapter_title != null:
		chapter_title.position = title_original_position + in_offset
		chapter_title.modulate = TEXT_HIDDEN

	if chapter_description != null:
		chapter_description.position = description_original_position + in_offset
		chapter_description.modulate = TEXT_HIDDEN


func play_page_in(owner: Node) -> void:
	_kill_tween(page_tween)

	page_tween = owner.create_tween()
	page_tween.set_parallel(true)

	if chapter_title != null:
		page_tween.tween_property(
			chapter_title,
			"position",
			title_original_position,
			PAGE_TEXT_IN_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		page_tween.tween_property(
			chapter_title,
			"modulate",
			TEXT_VISIBLE,
			PAGE_TEXT_IN_TIME
		)

	if chapter_description != null:
		page_tween.tween_property(
			chapter_description,
			"position",
			description_original_position,
			PAGE_TEXT_IN_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		page_tween.tween_property(
			chapter_description,
			"modulate",
			TEXT_VISIBLE,
			PAGE_TEXT_IN_TIME
		)

	await page_tween.finished


func restore_text_state() -> void:
	if chapter_title != null:
		chapter_title.position = title_original_position
		chapter_title.modulate = TEXT_VISIBLE

	if chapter_description != null:
		chapter_description.position = description_original_position
		chapter_description.modulate = TEXT_VISIBLE

	if chapter_illustration != null:
		chapter_illustration.visible = true
		chapter_illustration.modulate = TEXT_VISIBLE


func _kill_tween(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
