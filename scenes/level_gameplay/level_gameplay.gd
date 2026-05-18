extends Control

const HEADER_CELL_SCENE := preload("res://scenes/level_gameplay/components/header_cell/header_cell.tscn")
const TABLE_ROW_SCENE := preload("res://scenes/level_gameplay/components/table_row/table_row.tscn")
const CHAPTER_1_LEVELS := preload("res://scripts/data/chapter_1_levels.gd")
const PAUSE_SCENE := preload("res://scenes/level_gameplay/pause.tscn")
const MAIN_MENU_SCENE := "res://scenes/main_menu/main_menu.tscn"

const CHECK_HEADER_WIDTH := 150
const HEADER_HEIGHT := 120

const NORMAL_WIDTH := 300
const LONG_WIDTH := 520
const TABLE_WIDTH := 1080

const HEADER_Y := 246
const ROWS_Y := 374
const ROWS_HEIGHT := 1250

const H_SCROLL_Y := 1090
const H_SCROLL_HEIGHT := 20
const V_SCROLL_X := 1060
const V_SCROLL_WIDTH := 20

const SCROLL_WHEEL_SPEED := 90.0
const DRAG_LOCK_THRESHOLD := 14.0

const FOOTER_HEIGHT := 217
const FOOTER_BUTTON_WIDTH := 360
const FOOTER_BUTTON_HEIGHT := 217
const FOOTER_CONTENT_Y_OFFSET := 14.0
const FOOTER_BUTTON_HIGHLIGHT_COLOR := Color(0.88, 0.88, 0.88, 1.0)
const FOOTER_BUTTON_TEXT_COLOR := Color(0.819608, 0.572549, 0.376471, 1.0)


@onready var header_node: TextureRect = get_node_or_null("Header") as TextureRect
@onready var header_level: TextureRect = get_node_or_null("HeaderLevel") as TextureRect
@onready var header_objective: TextureRect = get_node_or_null("HeaderObjective") as TextureRect
@onready var data_header: TextureRect = get_node_or_null("DataHeader") as TextureRect
@onready var search_bar: TextureRect = get_node_or_null("SearchBar") as TextureRect
@onready var search_buttons: Control = get_node_or_null("SearchButtons") as Control
@onready var footer: TextureRect = get_node_or_null("Footer") as TextureRect

@onready var level_text: Label = get_node_or_null("HeaderLevel/LevelText") as Label
@onready var objective_text: Label = get_node_or_null("HeaderObjective/ObjectiveText") as Label
@onready var lives_text: Label = get_node_or_null("Header/HudLayer/LivesText") as Label
@onready var time_text: Label = get_node_or_null("Header/HudLayer/TimeText") as Label

@onready var pause_button: Control = get_pause_button_node()

@onready var pause_click_sound: AudioStreamPlayer = get_node_or_null("PauseClickSound") as AudioStreamPlayer
@onready var pause_menu_click_sound: AudioStreamPlayer = get_node_or_null("PauseMenuClickSound") as AudioStreamPlayer
@onready var hint_click_sound: AudioStreamPlayer = get_node_or_null("HintClickSound") as AudioStreamPlayer
@onready var check_correct_sound: AudioStreamPlayer = get_node_or_null("CheckCorrectSound") as AudioStreamPlayer
@onready var check_incorrect_sound: AudioStreamPlayer = get_node_or_null("CheckIncorrectSound") as AudioStreamPlayer
@onready var info_click_sound: AudioStreamPlayer = get_node_or_null("InfoClickSound") as AudioStreamPlayer
@onready var row_click_sound: AudioStreamPlayer = get_node_or_null("RowClickSound") as AudioStreamPlayer
@onready var title_header_click_sound: AudioStreamPlayer = get_node_or_null("TitleHeaderClickSound") as AudioStreamPlayer

@onready var hint_button: TextureButton = get_node_or_null("Footer/FooterButtons/HintButton") as TextureButton
@onready var check_button: TextureButton = get_node_or_null("Footer/FooterButtons/CheckButton") as TextureButton
@onready var info_button: TextureButton = get_node_or_null("Footer/FooterButtons/InfoButton") as TextureButton

@onready var hint_content: HBoxContainer = get_node_or_null("Footer/FooterButtons/HintButton/HintContent") as HBoxContainer
@onready var check_content: HBoxContainer = get_node_or_null("Footer/FooterButtons/CheckButton/CheckContent") as HBoxContainer
@onready var info_content: HBoxContainer = get_node_or_null("Footer/FooterButtons/InfoButton/InfoContent") as HBoxContainer

@onready var hint_label_margin: MarginContainer = get_node_or_null("Footer/FooterButtons/HintButton/HintContent/HintLabelMargin") as MarginContainer
@onready var check_label_margin: MarginContainer = get_node_or_null("Footer/FooterButtons/CheckButton/CheckContent/CheckLabelMargin") as MarginContainer
@onready var info_label_margin: MarginContainer = get_node_or_null("Footer/FooterButtons/InfoButton/InfoContent/InfoLabelMargin") as MarginContainer

@onready var hint_icon: TextureRect = get_node_or_null("Footer/FooterButtons/HintButton/HintContent/HintIcon") as TextureRect
@onready var check_icon: TextureRect = get_node_or_null("Footer/FooterButtons/CheckButton/CheckContent/CheckIcon") as TextureRect
@onready var info_icon: TextureRect = get_node_or_null("Footer/FooterButtons/InfoButton/InfoContent/InfoIcon") as TextureRect

@onready var hint_label: Label = get_node_or_null("Footer/FooterButtons/HintButton/HintContent/HintLabelMargin/HintLabel") as Label
@onready var check_label: Label = get_node_or_null("Footer/FooterButtons/CheckButton/CheckContent/CheckLabelMargin/CheckLabel") as Label
@onready var info_label: Label = get_node_or_null("Footer/FooterButtons/InfoButton/InfoContent/InfoLabelMargin/InfoLabel") as Label

@onready var h_scroll_bg: TextureRect = get_node_or_null("DataHeader/HScrollBarBackground") as TextureRect
@onready var h_scroll_slider: TextureRect = get_node_or_null("DataHeader/HScrollBarSlider") as TextureRect
@onready var v_scroll_bg: TextureRect = get_node_or_null("DataHeader/ScrollBarBackground") as TextureRect
@onready var v_scroll_slider: TextureRect = get_node_or_null("DataHeader/ScrollBarSlider") as TextureRect


var table_header_viewport: Control
var table_rows_viewport: Control
var header_hbox: HBoxContainer
var rows_vbox: VBoxContainer

var current_level: Dictionary = {}
var current_columns: Array = []
var current_records: Array = []
var original_records: Array = []
var active_sort_column_key := ""

var selected_record: Dictionary = {}
var selected_row: Button = null

var pause_overlay: Control = null
var is_pause_opening := false
var pause_button_is_holding := false

var correct_record_id := ""
var hearts := 4
var hint_index := 0

var scroll_x := 0.0
var scroll_y := 0.0
var max_scroll_x := 0.0
var max_scroll_y := 0.0

var table_content_width := 0.0
var table_content_height := 0.0

var is_dragging_table := false
var last_drag_global_position := Vector2.ZERO
var drag_axis := ""


func _ready() -> void:
	print("LEVEL GAMEPLAY SCRIPT IS RUNNING")

	setup_audio_process_mode()
	apply_fixed_phone_layout()
	setup_footer_buttons_layout()
	fix_search_buttons_layout()
	setup_objective_label()
	setup_manual_table_nodes()
	setup_custom_scrollbar_positions()
	connect_buttons()
	load_level(1)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		apply_fixed_phone_layout()
		setup_footer_buttons_layout()
		fix_search_buttons_layout()
		setup_objective_label()
		setup_custom_scrollbar_positions()
		call_deferred("refresh_scroll_limits")


func setup_audio_process_mode() -> void:
	var audio_players := [
		pause_click_sound,
		pause_menu_click_sound,
		hint_click_sound,
		check_correct_sound,
		check_incorrect_sound,
		info_click_sound,
		row_click_sound,
		title_header_click_sound
	]

	for player in audio_players:
		if player != null:
			player.process_mode = Node.PROCESS_MODE_ALWAYS


func apply_fixed_phone_layout() -> void:
	position_centered_node(header_node, -540, 0, 540, 167)
	position_centered_node(header_level, -540, 68, 541, 404)
	position_centered_node(header_objective, -540, 302, 540, 564)

	position_centered_node(data_header, -540, 562, 540, 903)
	position_centered_node(search_bar, -524, 576, 202, 665)
	position_centered_node(search_buttons, 222, 576, 507, 665)

	position_centered_bottom_node(footer, -540, 540, FOOTER_HEIGHT)


func position_centered_node(node: Control, left: float, top: float, right: float, bottom: float) -> void:
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


func position_centered_bottom_node(node: Control, left: float, right: float, height: float) -> void:
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


func setup_objective_label() -> void:
	if objective_text == null:
		return

	objective_text.anchor_left = 0.0
	objective_text.anchor_right = 1.0
	objective_text.anchor_top = 0.0
	objective_text.anchor_bottom = 1.0

	objective_text.offset_left = 80.0
	objective_text.offset_right = -80.0
	objective_text.offset_top = 55.0
	objective_text.offset_bottom = -45.0

	objective_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	objective_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_text.clip_text = true
	objective_text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


func get_pause_button_node() -> Control:
	var pause_node := get_node_or_null("Header/HudLayer/PauseButton") as Control

	if pause_node != null:
		return pause_node

	return get_node_or_null("Header/HudLayer/PauseIcon") as Control


func fix_search_buttons_layout() -> void:
	if search_buttons == null:
		return

	search_buttons.size = Vector2(285, 89)

	var filter_icon := search_buttons.get_node_or_null("FilterIcon") as Control
	var sort_icon := search_buttons.get_node_or_null("SortIcon") as Control
	var clear_icon := search_buttons.get_node_or_null("ClearIcon") as Control

	if filter_icon != null:
		filter_icon.position = Vector2(0, 0)
		filter_icon.size = Vector2(89, 89)

	if sort_icon != null:
		sort_icon.position = Vector2(98, 0)
		sort_icon.size = Vector2(89, 89)

	if clear_icon != null:
		clear_icon.position = Vector2(196, 0)
		clear_icon.size = Vector2(89, 89)


func setup_footer_buttons_layout() -> void:
	if footer == null:
		return

	footer.size = Vector2(1080, FOOTER_HEIGHT)
	footer.custom_minimum_size = Vector2(1080, FOOTER_HEIGHT)
	footer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	footer.stretch_mode = TextureRect.STRETCH_SCALE
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var footer_buttons := footer.get_node_or_null("FooterButtons") as HBoxContainer
	if footer_buttons != null:
		footer_buttons.anchor_left = 0.0
		footer_buttons.anchor_top = 0.0
		footer_buttons.anchor_right = 1.0
		footer_buttons.anchor_bottom = 1.0

		footer_buttons.offset_left = 0.0
		footer_buttons.offset_top = 0.0
		footer_buttons.offset_right = 0.0
		footer_buttons.offset_bottom = 0.0

		footer_buttons.custom_minimum_size = Vector2(1080, FOOTER_HEIGHT)
		footer_buttons.alignment = BoxContainer.ALIGNMENT_BEGIN
		footer_buttons.add_theme_constant_override("separation", 0)

	setup_one_footer_button(hint_button, hint_content)
	setup_one_footer_button(check_button, check_content)
	setup_one_footer_button(info_button, info_content)

	var footer_frame_overlay := footer.get_node_or_null("FooterFrameOverlay") as TextureRect
	if footer_frame_overlay != null:
		footer_frame_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		footer_frame_overlay.move_to_front()


func setup_one_footer_button(button: TextureButton, content: HBoxContainer) -> void:
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

	if content != null:
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


func setup_manual_table_nodes() -> void:
	if data_header == null:
		return

	var old_table_viewport := data_header.get_node_or_null("TableViewport")
	if old_table_viewport != null:
		old_table_viewport.queue_free()

	table_header_viewport = data_header.get_node_or_null("TableHeaderViewport") as Control

	if table_header_viewport == null:
		table_header_viewport = Control.new()
		table_header_viewport.name = "TableHeaderViewport"
		data_header.add_child(table_header_viewport)

	table_header_viewport.position = Vector2(0, HEADER_Y)
	table_header_viewport.size = Vector2(TABLE_WIDTH, HEADER_HEIGHT)
	table_header_viewport.custom_minimum_size = Vector2(TABLE_WIDTH, HEADER_HEIGHT)
	table_header_viewport.clip_contents = true
	table_header_viewport.mouse_filter = Control.MOUSE_FILTER_IGNORE

	header_hbox = table_header_viewport.get_node_or_null("HeaderHBox") as HBoxContainer

	if header_hbox == null:
		header_hbox = HBoxContainer.new()
		header_hbox.name = "HeaderHBox"
		table_header_viewport.add_child(header_hbox)

	header_hbox.position = Vector2.ZERO
	header_hbox.add_theme_constant_override("separation", 0)

	table_rows_viewport = data_header.get_node_or_null("TableRowsViewport") as Control

	if table_rows_viewport == null:
		table_rows_viewport = Control.new()
		table_rows_viewport.name = "TableRowsViewport"
		data_header.add_child(table_rows_viewport)

	table_rows_viewport.position = Vector2(0, ROWS_Y)
	table_rows_viewport.size = Vector2(TABLE_WIDTH, ROWS_HEIGHT)
	table_rows_viewport.custom_minimum_size = Vector2(TABLE_WIDTH, ROWS_HEIGHT)
	table_rows_viewport.clip_contents = true
	table_rows_viewport.mouse_filter = Control.MOUSE_FILTER_PASS

	rows_vbox = table_rows_viewport.get_node_or_null("RowsVBox") as VBoxContainer

	if rows_vbox == null:
		rows_vbox = VBoxContainer.new()
		rows_vbox.name = "RowsVBox"
		table_rows_viewport.add_child(rows_vbox)

	rows_vbox.position = Vector2.ZERO
	rows_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	rows_vbox.add_theme_constant_override("separation", 0)

	table_header_viewport.move_to_front()
	table_rows_viewport.move_to_front()
	move_custom_scrollbars_to_front()


func setup_custom_scrollbar_positions() -> void:
	if h_scroll_bg != null:
		h_scroll_bg.visible = true
		h_scroll_bg.position = Vector2(0, H_SCROLL_Y)
		h_scroll_bg.size = Vector2(TABLE_WIDTH, H_SCROLL_HEIGHT)
		h_scroll_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h_scroll_bg.move_to_front()

	if h_scroll_slider != null:
		h_scroll_slider.visible = true
		h_scroll_slider.position = Vector2(10, H_SCROLL_Y + 4)
		h_scroll_slider.size = Vector2(200, 15)
		h_scroll_slider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h_scroll_slider.move_to_front()

	if v_scroll_bg != null:
		v_scroll_bg.visible = true
		v_scroll_bg.position = Vector2(V_SCROLL_X, ROWS_Y)
		v_scroll_bg.size = Vector2(V_SCROLL_WIDTH, ROWS_HEIGHT)
		v_scroll_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v_scroll_bg.move_to_front()

	if v_scroll_slider != null:
		v_scroll_slider.visible = true
		v_scroll_slider.position = Vector2(V_SCROLL_X - 1, ROWS_Y)
		v_scroll_slider.size = Vector2(26, 85)
		v_scroll_slider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v_scroll_slider.move_to_front()


func move_custom_scrollbars_to_front() -> void:
	if h_scroll_bg != null:
		h_scroll_bg.move_to_front()

	if h_scroll_slider != null:
		h_scroll_slider.move_to_front()

	if v_scroll_bg != null:
		v_scroll_bg.move_to_front()

	if v_scroll_slider != null:
		v_scroll_slider.move_to_front()


func connect_buttons() -> void:
	if pause_button != null:
		pause_button.focus_mode = Control.FOCUS_NONE
		pause_button.mouse_filter = Control.MOUSE_FILTER_STOP
		pause_button.scale = Vector2.ONE
		pause_button.modulate = Color(1, 1, 1, 1)

		if not pause_button.gui_input.is_connected(_on_pause_button_gui_input):
			pause_button.gui_input.connect(_on_pause_button_gui_input)

	setup_footer_button(hint_button, hint_icon, hint_label_margin, hint_label, hint_click_sound, _on_hint_pressed)

	# Do not pass check_correct_sound here.
	# The check sound is decided inside _on_check_pressed().
	setup_footer_button(check_button, check_icon, check_label_margin, check_label, null, _on_check_pressed)

	setup_footer_button(info_button, info_icon, info_label_margin, info_label, info_click_sound, _on_info_pressed)


func _on_pause_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return

		if event.pressed:
			pause_button_is_holding = true
			_apply_pause_button_hold()
			get_viewport().set_input_as_handled()
		else:
			var should_open := pause_button_is_holding and is_mouse_inside_pause_button()

			pause_button_is_holding = false
			_reset_pause_button_hold()

			if should_open:
				_on_pause_pressed()

			get_viewport().set_input_as_handled()

	if event is InputEventScreenTouch:
		if event.pressed:
			pause_button_is_holding = true
			_apply_pause_button_hold()
			get_viewport().set_input_as_handled()
		else:
			var should_open_touch := pause_button_is_holding and is_mouse_inside_pause_button()

			pause_button_is_holding = false
			_reset_pause_button_hold()

			if should_open_touch:
				_on_pause_pressed()

			get_viewport().set_input_as_handled()


func _apply_pause_button_hold() -> void:
	if pause_button == null:
		return

	pause_button.modulate = Color(1.25, 1.25, 1.25, 1.0)
	pause_button.scale = Vector2.ONE


func _reset_pause_button_hold() -> void:
	if pause_button == null:
		return

	pause_button.modulate = Color(1, 1, 1, 1)
	pause_button.scale = Vector2.ONE


func is_mouse_inside_pause_button() -> bool:
	if pause_button == null:
		return false

	return pause_button.get_global_rect().has_point(get_global_mouse_position())


func setup_footer_button(
	button: TextureButton,
	icon: TextureRect,
	label_margin: MarginContainer,
	label: Label,
	sound_player: AudioStreamPlayer,
	pressed_callback: Callable
) -> void:
	if button == null:
		return

	if icon == null or label_margin == null or label == null:
		return

	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.scale = Vector2.ONE
	button.modulate = Color(1, 1, 1, 1)

	var footer_button_down := Callable(self, "_on_footer_button_down").bind(button, icon, label_margin, label)
	var footer_button_up := Callable(self, "_on_footer_button_up").bind(button, icon, label_margin, label)
	var footer_button_mouse_exited := Callable(self, "_on_footer_button_mouse_exited").bind(button, icon, label_margin, label)
	var footer_button_pressed := Callable(self, "_on_footer_button_pressed").bind(sound_player, pressed_callback)

	if not button.button_down.is_connected(footer_button_down):
		button.button_down.connect(footer_button_down)

	if not button.button_up.is_connected(footer_button_up):
		button.button_up.connect(footer_button_up)

	if not button.mouse_exited.is_connected(footer_button_mouse_exited):
		button.mouse_exited.connect(footer_button_mouse_exited)

	if not button.pressed.is_connected(footer_button_pressed):
		button.pressed.connect(footer_button_pressed)

	_apply_footer_button_idle_state(button, icon, label_margin, label)


func _on_footer_button_down(button: TextureButton, icon: TextureRect, label_margin: MarginContainer, label: Label) -> void:
	_apply_footer_button_pressed_state(button, icon, label_margin, label)


func _on_footer_button_up(button: TextureButton, icon: TextureRect, label_margin: MarginContainer, label: Label) -> void:
	_apply_footer_button_idle_state(button, icon, label_margin, label)


func _on_footer_button_mouse_exited(button: TextureButton, icon: TextureRect, label_margin: MarginContainer, label: Label) -> void:
	if button == null or not button.button_pressed:
		return

	_apply_footer_button_idle_state(button, icon, label_margin, label)


func _on_footer_button_pressed(sound_player: AudioStreamPlayer, pressed_callback: Callable) -> void:
	play_footer_click_sound(sound_player)

	if pressed_callback.is_valid():
		pressed_callback.call()


func _apply_footer_button_pressed_state(button: TextureButton, icon: TextureRect, _label_margin: MarginContainer, label: Label) -> void:
	if button == null:
		return

	button.scale = Vector2.ONE
	button.modulate = Color(1, 1, 1, 1)

	if icon != null:
		icon.modulate = FOOTER_BUTTON_HIGHLIGHT_COLOR

	if label != null:
		label.add_theme_color_override("font_color", FOOTER_BUTTON_TEXT_COLOR)


func _apply_footer_button_idle_state(button: TextureButton, icon: TextureRect, _label_margin: MarginContainer, label: Label) -> void:
	if button == null:
		return

	button.scale = Vector2.ONE
	button.modulate = Color(1, 1, 1, 1)

	if icon != null:
		icon.modulate = Color(1, 1, 1, 1)

	if label != null:
		label.add_theme_color_override("font_color", Color(1, 1, 1, 1))


func play_footer_click_sound(sound_player: AudioStreamPlayer) -> void:
	if sound_player == null:
		return

	sound_player.stop()
	sound_player.play()


func load_level(level_number: int) -> void:
	current_level = CHAPTER_1_LEVELS.get_level(level_number)

	if current_level.is_empty():
		push_error("Level data not found: %s" % level_number)
		return

	current_columns = current_level.get("columns", [])
	current_records = current_level.get("records", [])
	original_records = current_records.duplicate(true)
	active_sort_column_key = ""
	correct_record_id = str(current_level.get("correct_record_id", ""))
	hearts = int(current_level.get("hearts", 4))
	hint_index = 0

	print("DEBUG load_level - Level %d loaded with %d records" % [level_number, current_records.size()])

	selected_record = {}
	selected_row = null

	scroll_x = 0.0
	scroll_y = 0.0
	drag_axis = ""

	if level_text != null:
		level_text.text = "Level %s" % str(current_level.get("level_number", level_number))

	if objective_text != null:
		objective_text.text = str(current_level.get("objective", "Objective"))
		objective_text.add_theme_font_size_override("font_size", 42)

	if lives_text != null:
		lives_text.text = "%s/4" % hearts

	if time_text != null:
		var time_limit := int(current_level.get("time_limit", 240))
		time_text.text = format_time(time_limit)

	build_table()


func format_time(seconds: int) -> String:
	var minutes := int(seconds / 60.0)
	var remaining_seconds := seconds % 60
	return "%02d:%02d" % [minutes, remaining_seconds]


func build_table() -> void:
	clear_container(header_hbox)
	clear_container(rows_vbox)

	build_headers()
	build_rows()

	call_deferred("refresh_scroll_limits")


func clear_container(container: Node) -> void:
	if container == null:
		return

	for child in container.get_children():
		child.queue_free()


func build_headers() -> void:
	if header_hbox == null:
		return

	var check_spacer := Control.new()
	check_spacer.custom_minimum_size = Vector2(CHECK_HEADER_WIDTH, HEADER_HEIGHT)
	header_hbox.add_child(check_spacer)

	for column in current_columns:
		var header_cell = HEADER_CELL_SCENE.instantiate()
		header_hbox.add_child(header_cell)

		var key := str(column.get("key", ""))
		header_cell.setup(column, key == active_sort_column_key)
		header_cell.header_pressed.connect(_on_header_pressed)


func build_rows() -> void:
	if rows_vbox == null:
		return

	var row_count := 0

	for record in current_records:
		var row = TABLE_ROW_SCENE.instantiate()
		rows_vbox.add_child(row)

		row.setup(current_columns, record, false)
		row.row_selected.connect(_on_row_selected.bind(row))
		row_count += 1

	print("Built %d rows. Total records: %d" % [row_count, current_records.size()])


func refresh_scroll_limits() -> void:
	if table_rows_viewport == null or rows_vbox == null:
		return

	table_content_width = calculate_table_width()
	table_content_height = get_real_rows_content_height()

	print("DEBUG - Content height: %f, Viewport height: %f, Rows: %d" % [table_content_height, table_rows_viewport.size.y, rows_vbox.get_child_count()])

	max_scroll_x = max(0.0, table_content_width - table_rows_viewport.size.x)
	max_scroll_y = max(0.0, table_content_height - table_rows_viewport.size.y)

	scroll_x = clamp(scroll_x, 0.0, max_scroll_x)
	scroll_y = clamp(scroll_y, 0.0, max_scroll_y)

	apply_table_scroll()
	setup_custom_scrollbar_positions()
	update_custom_scrollbars()


func get_real_rows_content_height() -> float:
	if rows_vbox == null:
		return 0.0

	var total_height := 0.0

	for child in rows_vbox.get_children():
		if child is Control:
			total_height += child.custom_minimum_size.y

	return total_height


func calculate_table_width() -> float:
	var total := CHECK_HEADER_WIDTH

	for column in current_columns:
		var type := str(column.get("type", "normal"))

		if type == "long":
			total += LONG_WIDTH
		else:
			total += NORMAL_WIDTH

	return float(total)


func apply_table_scroll() -> void:
	if header_hbox != null:
		header_hbox.position = Vector2(-scroll_x, 0)

	if rows_vbox != null:
		rows_vbox.position = Vector2(-scroll_x, -scroll_y)

	update_custom_scrollbars()


func scroll_table(delta: Vector2) -> void:
	scroll_x = clamp(scroll_x + delta.x, 0.0, max_scroll_x)
	scroll_y = clamp(scroll_y + delta.y, 0.0, max_scroll_y)
	apply_table_scroll()


func _input(event: InputEvent) -> void:
	if pause_overlay != null and is_instance_valid(pause_overlay):
		return

	if table_rows_viewport == null or table_header_viewport == null:
		return

	var table_rect: Rect2 = table_rows_viewport.get_global_rect()
	var header_rect: Rect2 = table_header_viewport.get_global_rect()

	if event is InputEventMouseButton:
		var mouse_position: Vector2 = get_global_mouse_position()
		var inside_table: bool = table_rect.has_point(mouse_position)
		var inside_header: bool = header_rect.has_point(mouse_position)

		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and (inside_table or inside_header):
				is_dragging_table = true
				last_drag_global_position = mouse_position
				drag_axis = ""
			elif not event.pressed:
				is_dragging_table = false
				drag_axis = ""

		if event.pressed and (inside_table or inside_header):
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				if Input.is_key_pressed(KEY_SHIFT):
					scroll_table(Vector2(-SCROLL_WHEEL_SPEED, 0))
				else:
					scroll_table(Vector2(0, -SCROLL_WHEEL_SPEED))

			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if Input.is_key_pressed(KEY_SHIFT):
					scroll_table(Vector2(SCROLL_WHEEL_SPEED, 0))
				else:
					scroll_table(Vector2(0, SCROLL_WHEEL_SPEED))

	if event is InputEventMouseMotion and is_dragging_table:
		var mouse_position: Vector2 = get_global_mouse_position()
		var raw_delta: Vector2 = last_drag_global_position - mouse_position
		last_drag_global_position = mouse_position
		scroll_table(get_locked_drag_delta(raw_delta))

	if event is InputEventScreenTouch:
		var touch_position: Vector2 = event.position
		var inside_table_touch: bool = table_rect.has_point(touch_position)
		var inside_header_touch: bool = header_rect.has_point(touch_position)

		if event.pressed and (inside_table_touch or inside_header_touch):
			is_dragging_table = true
			last_drag_global_position = touch_position
			drag_axis = ""
		else:
			is_dragging_table = false
			drag_axis = ""

	if event is InputEventScreenDrag and is_dragging_table:
		var raw_touch_delta: Vector2 = Vector2(-event.relative.x, -event.relative.y)
		scroll_table(get_locked_drag_delta(raw_touch_delta))


func get_locked_drag_delta(raw_delta: Vector2) -> Vector2:
	if drag_axis == "":
		if abs(raw_delta.x) < DRAG_LOCK_THRESHOLD and abs(raw_delta.y) < DRAG_LOCK_THRESHOLD:
			return Vector2.ZERO

		if abs(raw_delta.x) > abs(raw_delta.y):
			drag_axis = "horizontal"
		else:
			drag_axis = "vertical"

	if drag_axis == "horizontal":
		return Vector2(raw_delta.x, 0)

	return Vector2(0, raw_delta.y)


func update_custom_scrollbars() -> void:
	update_horizontal_scrollbar()
	update_vertical_scrollbar()
	move_custom_scrollbars_to_front()


func update_horizontal_scrollbar() -> void:
	if h_scroll_bg == null or h_scroll_slider == null or table_rows_viewport == null:
		return

	h_scroll_bg.visible = true
	h_scroll_bg.position = Vector2(0, H_SCROLL_Y)
	h_scroll_bg.size = Vector2(TABLE_WIDTH, H_SCROLL_HEIGHT)
	h_scroll_bg.move_to_front()

	var track_left: float = h_scroll_bg.position.x + 10.0
	var track_width: float = h_scroll_bg.size.x - 20.0

	if max_scroll_x <= 0.0:
		h_scroll_slider.visible = false
		return

	h_scroll_slider.visible = true

	var visible_ratio: float = clampf(table_rows_viewport.size.x / table_content_width, 0.08, 1.0)
	var slider_width: float = track_width * visible_ratio
	var progress: float = scroll_x / max_scroll_x
	var slider_x: float = track_left + ((track_width - slider_width) * progress)

	h_scroll_slider.position.x = slider_x
	h_scroll_slider.position.y = H_SCROLL_Y + 4
	h_scroll_slider.size.x = slider_width
	h_scroll_slider.size.y = 15
	h_scroll_slider.move_to_front()


func update_vertical_scrollbar() -> void:
	if v_scroll_bg == null or v_scroll_slider == null or table_rows_viewport == null:
		return

	v_scroll_bg.visible = true
	v_scroll_bg.position = Vector2(V_SCROLL_X, ROWS_Y)
	v_scroll_bg.size = Vector2(V_SCROLL_WIDTH, ROWS_HEIGHT)
	v_scroll_bg.move_to_front()

	var track_top: float = v_scroll_bg.position.y
	var track_height: float = v_scroll_bg.size.y

	if max_scroll_y <= 0.0:
		v_scroll_slider.visible = false
		return

	v_scroll_slider.visible = true

	var visible_ratio: float = clampf(table_rows_viewport.size.y / table_content_height, 0.08, 1.0)
	var slider_height: float = track_height * visible_ratio
	var progress: float = scroll_y / max_scroll_y
	var slider_y: float = track_top + ((track_height - slider_height) * progress)

	v_scroll_slider.position.x = V_SCROLL_X - 1
	v_scroll_slider.position.y = slider_y
	v_scroll_slider.size.x = 26
	v_scroll_slider.size.y = slider_height
	v_scroll_slider.move_to_front()


func _on_row_selected(record: Dictionary, row: Button) -> void:
	play_footer_click_sound(row_click_sound)

	if selected_row != null and selected_row.has_method("set_selected"):
		selected_row.set_selected(false)

	selected_record = record
	selected_row = row

	if selected_row != null and selected_row.has_method("set_selected"):
		selected_row.set_selected(true)

	var record_id := str(selected_record.get("record_id", ""))
	var record_name := str(selected_record.get("name", ""))
	var surname := str(selected_record.get("surname", ""))

	if objective_text != null:
		objective_text.text = "Selected: %s — %s %s" % [record_id, record_name, surname]
		objective_text.add_theme_font_size_override("font_size", 46)


func _on_check_pressed() -> void:
	if objective_text == null:
		return

	if selected_record.is_empty():
		objective_text.text = "Select a record first."
		objective_text.add_theme_font_size_override("font_size", 50)
		return

	var selected_id := str(selected_record.get("record_id", ""))

	if selected_id == correct_record_id:
		play_footer_click_sound(check_correct_sound)
		objective_text.text = "Case Solved! Correct record: %s" % selected_id
		objective_text.add_theme_font_size_override("font_size", 50)
	else:
		play_footer_click_sound(check_incorrect_sound)
		hearts -= 1

		if lives_text != null:
			lives_text.text = "%s/4" % max(hearts, 0)

		if hearts <= 0:
			objective_text.text = "Case Failed. Try again."
		else:
			objective_text.text = "Wrong record. Check the archive clues again."

		objective_text.add_theme_font_size_override("font_size", 48)


func _on_hint_pressed() -> void:
	if objective_text == null:
		return

	var hints: Array = current_level.get("hints", [])

	if hints.is_empty():
		objective_text.text = "No hints available."
		return

	if hint_index >= hints.size():
		hint_index = hints.size() - 1

	objective_text.text = str(hints[hint_index])
	objective_text.add_theme_font_size_override("font_size", 46)

	hint_index += 1


func _on_info_pressed() -> void:
	if objective_text == null:
		return

	objective_text.text = str(current_level.get("story", "No story available."))
	objective_text.add_theme_font_size_override("font_size", 36)


func _on_pause_pressed() -> void:
	if is_pause_opening:
		return

	if pause_overlay != null and is_instance_valid(pause_overlay):
		return

	is_pause_opening = true
	play_pause_click_sound()

	pause_overlay = PAUSE_SCENE.instantiate()
	add_child(pause_overlay)

	pause_overlay.modulate = Color(1, 1, 1, 0)
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.visible = true

	configure_pause_overlay()
	connect_pause_overlay_buttons()

	var fade_tween := create_tween()
	fade_tween.set_trans(Tween.TRANS_SINE)
	fade_tween.set_ease(Tween.EASE_OUT)
	fade_tween.tween_property(pause_overlay, "modulate", Color(1, 1, 1, 1), 0.12)

	await fade_tween.finished
	get_tree().paused = true

	is_pause_opening = false


func configure_pause_overlay() -> void:
	if pause_overlay == null or not is_instance_valid(pause_overlay):
		return

	pause_overlay.visible = true
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.offset_left = 0.0
	pause_overlay.offset_top = 0.0
	pause_overlay.offset_right = 0.0
	pause_overlay.offset_bottom = 0.0
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS

	var dim := pause_overlay.get_node_or_null("Dim") as ColorRect
	if dim != null:
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		dim.offset_left = 0.0
		dim.offset_top = 0.0
		dim.offset_right = 0.0
		dim.offset_bottom = 0.0
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dim.color = Color(0, 0, 0, 0.72)

	var pause_panel := pause_overlay.get_node_or_null("PausePanel") as TextureRect
	if pause_panel != null:
		pause_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		pause_panel.offset_left = 0.0
		pause_panel.offset_top = 0.0
		pause_panel.offset_right = 0.0
		pause_panel.offset_bottom = 0.0
		pause_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pause_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pause_panel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED


func connect_pause_overlay_buttons() -> void:
	if pause_overlay == null or not is_instance_valid(pause_overlay):
		return

	if pause_overlay.has_signal("resume_pressed"):
		if not pause_overlay.resume_pressed.is_connected(_on_pause_resume_pressed):
			pause_overlay.resume_pressed.connect(_on_pause_resume_pressed)

	if pause_overlay.has_signal("achievements_pressed"):
		if not pause_overlay.achievements_pressed.is_connected(_on_pause_achievements_pressed):
			pause_overlay.achievements_pressed.connect(_on_pause_achievements_pressed)

	if pause_overlay.has_signal("settings_pressed"):
		if not pause_overlay.settings_pressed.is_connected(_on_pause_settings_pressed):
			pause_overlay.settings_pressed.connect(_on_pause_settings_pressed)

	if pause_overlay.has_signal("back_to_menu_pressed"):
		if not pause_overlay.back_to_menu_pressed.is_connected(_on_pause_back_to_menu_pressed):
			pause_overlay.back_to_menu_pressed.connect(_on_pause_back_to_menu_pressed)


func _on_pause_resume_pressed() -> void:
	play_pause_menu_click_sound()
	get_tree().paused = false

	if pause_overlay != null and is_instance_valid(pause_overlay):
		pause_overlay.queue_free()
		pause_overlay = null


func _on_pause_achievements_pressed() -> void:
	play_pause_menu_click_sound()


func _on_pause_settings_pressed() -> void:
	play_pause_menu_click_sound()


func _on_pause_back_to_menu_pressed() -> void:
	play_pause_menu_click_sound()
	get_tree().paused = false

	var transition_manager: Node = get_node_or_null("/root/SceneTransitionManager")

	if transition_manager != null and transition_manager.has_method("change_scene_with_fade"):
		await get_tree().create_timer(0.08).timeout
		transition_manager.call("change_scene_with_fade", MAIN_MENU_SCENE, 0.5, 0.3)
		return

	await get_tree().create_timer(0.08).timeout
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func play_pause_click_sound() -> void:
	if pause_click_sound == null:
		return

	pause_click_sound.stop()
	pause_click_sound.play()


func play_pause_menu_click_sound() -> void:
	if pause_menu_click_sound == null:
		return

	pause_menu_click_sound.stop()
	pause_menu_click_sound.play()


func _on_header_pressed(column_key: String) -> void:
	play_footer_click_sound(title_header_click_sound)

	if column_key == "":
		return

	if active_sort_column_key == column_key:
		active_sort_column_key = ""
		current_records = original_records.duplicate(true)
	else:
		active_sort_column_key = column_key
		sort_records_by_column(column_key)

	rebuild_table_keep_scroll()


func sort_records_by_column(column_key: String) -> void:
	current_records = original_records.duplicate(true)

	if column_key == "record_id":
		current_records.sort_custom(func(a, b) -> bool:
			return get_record_id_number(a) > get_record_id_number(b)
		)
		return

	current_records.sort_custom(func(a, b) -> bool:
		var value_a := str(a.get(column_key, "")).to_lower()
		var value_b := str(b.get(column_key, "")).to_lower()

		if value_a == value_b:
			return get_record_id_number(a) < get_record_id_number(b)

		return value_a < value_b
	)


func get_record_id_number(record: Dictionary) -> int:
	var raw_id := str(record.get("record_id", ""))
	var digits := ""

	for character in raw_id:
		if character >= "0" and character <= "9":
			digits += character

	if digits == "":
		return 0

	return int(digits)


func rebuild_table_keep_scroll() -> void:
	var old_scroll_x := scroll_x
	var old_scroll_y := scroll_y

	clear_container(header_hbox)
	clear_container(rows_vbox)
	build_headers()
	build_rows()

	scroll_x = old_scroll_x
	scroll_y = old_scroll_y
	call_deferred("refresh_scroll_limits")
