extends RefCounted

const TEXT_VISIBLE := Color(1, 1, 1, 1)
const TEXT_HIDDEN := Color(1, 1, 1, 0)

const INTRO_HEADER_TIME := 0.30
const INTRO_TEXT_TIME := 0.20

const OUTRO_HEADER_TIME := 0.30
const OUTRO_TEXT_TIME := 0.16

const PAGE_TEXT_OUT_TIME := 0.06
const PAGE_TEXT_IN_TIME := 0.08
const PAGE_TEXT_MOVE_DISTANCE := 18.0

const HEADER_OUT_OFFSET_Y := 20.0

var chapterHeader: TextureRect
var chapterIllustration: TextureRect
var chapterTitle: Label
var chapterDescription: Label

var headerOriginalPosition := Vector2.ZERO
var titleOriginalPosition := Vector2.ZERO
var descriptionOriginalPosition := Vector2.ZERO

var introTween: Tween
var outroTween: Tween
var pageTween: Tween


# Stores the nodes animated by this helper.
func setup(
	headerNode: TextureRect,
	illustrationNode: TextureRect,
	titleNode: Label,
	descriptionNode: Label
) -> void:
	chapterHeader = headerNode
	chapterIllustration = illustrationNode
	chapterTitle = titleNode
	chapterDescription = descriptionNode


# Saves the original positions used as animation targets.
func cacheOriginalValues() -> void:
	if chapterHeader != null:
		headerOriginalPosition = chapterHeader.position

	if chapterTitle != null:
		titleOriginalPosition = chapterTitle.position

	if chapterDescription != null:
		descriptionOriginalPosition = chapterDescription.position


# Sets the chapter slider elements to their hidden intro state.
func prepareIntroState() -> void:
	if chapterHeader != null:
		chapterHeader.position = getHeaderHiddenPosition()

	if chapterTitle != null:
		chapterTitle.position = titleOriginalPosition
		chapterTitle.modulate = TEXT_HIDDEN

	if chapterDescription != null:
		chapterDescription.position = descriptionOriginalPosition
		chapterDescription.modulate = TEXT_HIDDEN

	if chapterIllustration != null:
		chapterIllustration.visible = true
		chapterIllustration.modulate = TEXT_VISIBLE


# Plays the header and text intro animation.
func playIntroAnimation(owner: Node) -> void:
	killTween(introTween)

	introTween = owner.get_tree().create_tween()
	introTween.set_parallel(true)

	if chapterHeader != null:
		introTween.tween_property(
			chapterHeader,
			"position",
			headerOriginalPosition,
			INTRO_HEADER_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if chapterTitle != null:
		introTween.tween_property(
			chapterTitle,
			"modulate",
			TEXT_VISIBLE,
			INTRO_TEXT_TIME
		)

	if chapterDescription != null:
		introTween.tween_property(
			chapterDescription,
			"modulate",
			TEXT_VISIBLE,
			INTRO_TEXT_TIME
		)


# Plays the header and text outro animation.
func playOutroAnimation(owner: Node) -> void:
	killTween(outroTween)

	outroTween = owner.get_tree().create_tween()
	outroTween.set_parallel(true)

	if chapterHeader != null:
		outroTween.tween_property(
			chapterHeader,
			"position",
			getHeaderHiddenPosition(),
			OUTRO_HEADER_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if chapterTitle != null:
		outroTween.tween_property(
			chapterTitle,
			"modulate",
			TEXT_HIDDEN,
			OUTRO_TEXT_TIME
		)

	if chapterDescription != null:
		outroTween.tween_property(
			chapterDescription,
			"modulate",
			TEXT_HIDDEN,
			OUTRO_TEXT_TIME
		)


# Fades and moves the current page text out before the page changes.
func playPageOut(owner: Node, direction: int) -> void:
	killTween(pageTween)

	var outOffset := Vector2(-PAGE_TEXT_MOVE_DISTANCE * direction, 0)

	pageTween = owner.create_tween()
	pageTween.set_parallel(true)

	if chapterTitle != null:
		pageTween.tween_property(
			chapterTitle,
			"modulate",
			TEXT_HIDDEN,
			PAGE_TEXT_OUT_TIME
		)

		pageTween.tween_property(
			chapterTitle,
			"position",
			titleOriginalPosition + outOffset,
			PAGE_TEXT_OUT_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	if chapterDescription != null:
		pageTween.tween_property(
			chapterDescription,
			"modulate",
			TEXT_HIDDEN,
			PAGE_TEXT_OUT_TIME
		)

		pageTween.tween_property(
			chapterDescription,
			"position",
			descriptionOriginalPosition + outOffset,
			PAGE_TEXT_OUT_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await pageTween.finished


# Places the new page text before it animates in.
func preparePageIn(direction: int) -> void:
	var inOffset := Vector2(PAGE_TEXT_MOVE_DISTANCE * direction, 0)

	if chapterTitle != null:
		chapterTitle.position = titleOriginalPosition + inOffset
		chapterTitle.modulate = TEXT_HIDDEN

	if chapterDescription != null:
		chapterDescription.position = descriptionOriginalPosition + inOffset
		chapterDescription.modulate = TEXT_HIDDEN


# Fades and moves the new page text into view.
func playPageIn(owner: Node) -> void:
	killTween(pageTween)

	pageTween = owner.create_tween()
	pageTween.set_parallel(true)

	if chapterTitle != null:
		pageTween.tween_property(
			chapterTitle,
			"position",
			titleOriginalPosition,
			PAGE_TEXT_IN_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		pageTween.tween_property(
			chapterTitle,
			"modulate",
			TEXT_VISIBLE,
			PAGE_TEXT_IN_TIME
		)

	if chapterDescription != null:
		pageTween.tween_property(
			chapterDescription,
			"position",
			descriptionOriginalPosition,
			PAGE_TEXT_IN_TIME
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		pageTween.tween_property(
			chapterDescription,
			"modulate",
			TEXT_VISIBLE,
			PAGE_TEXT_IN_TIME
		)

	await pageTween.finished


# Restores the text and illustration to their normal visible state.
func restoreTextState() -> void:
	if chapterTitle != null:
		chapterTitle.position = titleOriginalPosition
		chapterTitle.modulate = TEXT_VISIBLE

	if chapterDescription != null:
		chapterDescription.position = descriptionOriginalPosition
		chapterDescription.modulate = TEXT_VISIBLE

	if chapterIllustration != null:
		chapterIllustration.visible = true
		chapterIllustration.modulate = TEXT_VISIBLE


# Returns the hidden header position used by intro and outro animations.
func getHeaderHiddenPosition() -> Vector2:
	if chapterHeader == null:
		return Vector2.ZERO

	return Vector2(
		headerOriginalPosition.x,
		-chapterHeader.size.y - HEADER_OUT_OFFSET_Y
	)


# Stops a tween before replacing it with a new one.
func killTween(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()