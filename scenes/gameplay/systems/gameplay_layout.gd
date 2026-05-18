extends RefCounted

const DESIGN_WIDTH := 1080.0

const FOOTER_HEIGHT := 217.0
const FOOTER_BUTTON_WIDTH := 360.0
const FOOTER_BUTTON_HEIGHT := 217.0
const FOOTER_CONTENT_Y_OFFSET := 14.0

const OBJECTIVE_FONT_SIZE := 40
const OBJECTIVE_TEXT_OFFSET_LEFT := 55.0
const OBJECTIVE_TEXT_OFFSET_TOP := 20.0
const OBJECTIVE_TEXT_OFFSET_RIGHT := -120.0
const OBJECTIVE_TEXT_OFFSET_BOTTOM := -45.0

const SEARCH_BUTTONS_SIZE := Vector2(178.0, 89.0)
const SEARCH_BUTTON_SIZE := Vector2(89.0, 89.0)

var gameplay: Control


# Stores the gameplay screen reference used by this layout system.
func _init(gameplayOwner: Control) -> void:
	gameplay = gameplayOwner


# Applies the fixed 1080-width phone layout to the gameplay screen.
func applyFixedPhoneLayout() -> void:
	positionCenteredNode(gameplay.header, -540.0, 0.0, 540.0, 167.0)
	positionCenteredNode(gameplay.headerLevel, -540.0, 68.0, 541.0, 404.0)
	positionCenteredNode(gameplay.headerObjective, -583.0, 300.0, 644.0, 570.0)

	positionCenteredNode(gameplay.dataHeader, -540.0, 562.0, 540.0, 903.0)
	positionCenteredNode(gameplay.searchBar, -524.0, 576.0, 202.0, 665.0)
	positionCenteredNode(gameplay.searchButtons, 222.0, 576.0, 507.0, 665.0)

	positionCenteredBottomNode(gameplay.footer, -540.0, 540.0, FOOTER_HEIGHT)


# Positions a node horizontally around the center of the screen.
func positionCenteredNode(
	node: Control,
	left: float,
	top: float,
	right: float,
	bottom: float
) -> void:
	if node == null:
		return

	node.anchor_left = 0.5
	node.anchor_right = 0.5
	node.anchor_top = 0.0
	node.anchor_bottom = 0.0

	node.offset_left = left
	node.offset_top = top
	node.offset_right = right
	node.offset_bottom = bottom


# Positions a node at the bottom center of the screen.
func positionCenteredBottomNode(
	node: Control,
	left: float,
	right: float,
	height: float
) -> void:
	if node == null:
		return

	node.anchor_left = 0.5
	node.anchor_right = 0.5
	node.anchor_top = 1.0
	node.anchor_bottom = 1.0

	node.offset_left = left
	node.offset_right = right
	node.offset_top = -height
	node.offset_bottom = 0.0


# Fixes the objective text layout inside the objective header.
func setupObjectiveLabel() -> void:
	if gameplay.objectiveText == null:
		return

	gameplay.objectiveText.anchor_left = 0.0
	gameplay.objectiveText.anchor_top = 0.0
	gameplay.objectiveText.anchor_right = 1.0
	gameplay.objectiveText.anchor_bottom = 1.0

	gameplay.objectiveText.offset_left = OBJECTIVE_TEXT_OFFSET_LEFT
	gameplay.objectiveText.offset_top = OBJECTIVE_TEXT_OFFSET_TOP
	gameplay.objectiveText.offset_right = OBJECTIVE_TEXT_OFFSET_RIGHT
	gameplay.objectiveText.offset_bottom = OBJECTIVE_TEXT_OFFSET_BOTTOM

	gameplay.objectiveText.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gameplay.objectiveText.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gameplay.objectiveText.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gameplay.objectiveText.clip_text = false


# Fixes the filter and clear button positions beside the search bar.
func fixSearchButtonsLayout() -> void:
	if gameplay.searchButtons == null:
		return

	gameplay.searchButtons.size = SEARCH_BUTTONS_SIZE

	var filterIcon := gameplay.searchButtons.get_node_or_null("FilterIcon") as Control
	var clearIcon := gameplay.searchButtons.get_node_or_null("ClearIcon") as Control

	if filterIcon != null:
		filterIcon.position = Vector2.ZERO
		filterIcon.size = SEARCH_BUTTON_SIZE

	if clearIcon != null:
		clearIcon.position = Vector2(SEARCH_BUTTON_SIZE.x, 0.0)
		clearIcon.size = SEARCH_BUTTON_SIZE


# Fixes the gameplay footer and its three action buttons.
func setupFooterButtonsLayout() -> void:
	if gameplay.footer == null:
		return

	gameplay.footer.size = Vector2(DESIGN_WIDTH, FOOTER_HEIGHT)
	gameplay.footer.custom_minimum_size = Vector2(DESIGN_WIDTH, FOOTER_HEIGHT)
	gameplay.footer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gameplay.footer.stretch_mode = TextureRect.STRETCH_SCALE
	gameplay.footer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var footerButtons := gameplay.footer.get_node_or_null("FooterButtons") as HBoxContainer

	if footerButtons != null:
		footerButtons.anchor_left = 0.0
		footerButtons.anchor_top = 0.0
		footerButtons.anchor_right = 1.0
		footerButtons.anchor_bottom = 1.0

		footerButtons.offset_left = 0.0
		footerButtons.offset_top = 0.0
		footerButtons.offset_right = 0.0
		footerButtons.offset_bottom = 0.0

		footerButtons.custom_minimum_size = Vector2(DESIGN_WIDTH, FOOTER_HEIGHT)
		footerButtons.alignment = BoxContainer.ALIGNMENT_BEGIN
		footerButtons.add_theme_constant_override("separation", 0)

	setupOneFooterButton(gameplay.hintButton, gameplay.hintContent)
	setupOneFooterButton(gameplay.checkButton, gameplay.checkContent)
	setupOneFooterButton(gameplay.infoButton, gameplay.infoContent)

	var footerFrameOverlay := gameplay.footer.get_node_or_null("FooterFrameOverlay") as TextureRect

	if footerFrameOverlay != null:
		footerFrameOverlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		footerFrameOverlay.move_to_front()


# Fixes the size and content alignment of one footer action button.
func setupOneFooterButton(button: TextureButton, content: HBoxContainer) -> void:
	if button == null:
		return

	button.custom_minimum_size = Vector2(FOOTER_BUTTON_WIDTH, FOOTER_BUTTON_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_NONE
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.scale = Vector2.ONE
	button.modulate = Color(1, 1, 1, 1)

	if content == null:
		return

	content.anchor_left = 0.0
	content.anchor_top = 0.0
	content.anchor_right = 1.0
	content.anchor_bottom = 1.0

	content.offset_left = 0.0
	content.offset_top = FOOTER_CONTENT_Y_OFFSET
	content.offset_right = 0.0
	content.offset_bottom = FOOTER_CONTENT_Y_OFFSET

	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 20)