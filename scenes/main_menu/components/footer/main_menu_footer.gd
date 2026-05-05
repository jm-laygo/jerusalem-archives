extends Control

signal creditsPressed
signal rankingPressed
signal achievementsPressed

const FOOTER_NORMAL_MODULATE := Color(1, 1, 1, 1)
const FOOTER_CLICK_MODULATE := Color(0.55, 0.55, 0.55, 1)

@onready var creditsIcon: TextureButton = $CreditsIcon
@onready var rankingIcon: TextureButton = $RankingIcon
@onready var achievementsIcon: TextureButton = $AchievementsIcon


func _ready() -> void:
	_setupFooterButton(creditsIcon)
	_setupFooterButton(rankingIcon)
	_setupFooterButton(achievementsIcon)

	creditsIcon.pressed.connect(creditsPressed.emit)
	rankingIcon.pressed.connect(rankingPressed.emit)
	achievementsIcon.pressed.connect(achievementsPressed.emit)


func _setupFooterButton(button: TextureButton) -> void:
	if button == null:
		return

	button.focus_mode = Control.FOCUS_NONE
	button.texture_hover = button.texture_normal
	button.texture_focused = button.texture_normal
	button.texture_pressed = button.texture_normal
	button.modulate = FOOTER_NORMAL_MODULATE

	if not button.button_down.is_connected(_onFooterButtonDown.bind(button)):
		button.button_down.connect(_onFooterButtonDown.bind(button))

	if not button.button_up.is_connected(_onFooterButtonUp.bind(button)):
		button.button_up.connect(_onFooterButtonUp.bind(button))

	if not button.mouse_exited.is_connected(_onFooterButtonMouseExited.bind(button)):
		button.mouse_exited.connect(_onFooterButtonMouseExited.bind(button))


func _onFooterButtonDown(button: TextureButton) -> void:
	button.modulate = FOOTER_CLICK_MODULATE


func _onFooterButtonUp(button: TextureButton) -> void:
	button.modulate = FOOTER_NORMAL_MODULATE


func _onFooterButtonMouseExited(button: TextureButton) -> void:
	if button.button_pressed:
		return

	button.modulate = FOOTER_NORMAL_MODULATE