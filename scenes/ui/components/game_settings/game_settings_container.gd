extends Control

signal closePressed
signal settingChanged(setting_name: String, enabled: bool)

const CLOSE_NORMAL_MODULATE := Color(1, 1, 1, 1)
const CLOSE_PRESSED_MODULATE := Color(1.35, 1.15, 0.85, 1)

const TOGGLE_NORMAL_MODULATE := Color(1, 1, 1, 1)
const TOGGLE_PRESSED_MODULATE := Color(1.20, 1.12, 0.85, 1)
const TOGGLE_DISABLED_MODULATE := Color(0.68, 0.68, 0.68, 1)

const SETTINGS_PATH := "user://jerusalem_archives_settings.cfg"

const SOUND_ICON: Texture2D = preload("res://assets/interface/icons/icn_sound.png")
const SOUND_MUTED_ICON: Texture2D = preload("res://assets/interface/icons/icn_sound_muted.png")

const MUSIC_ICON: Texture2D = preload("res://assets/interface/icons/icn_music.png")
const MUSIC_MUTED_ICON: Texture2D = preload("res://assets/interface/icons/icn_music_muted.png")

const VIBRATION_ICON: Texture2D = preload("res://assets/interface/icons/icn_vibration.png")
const VIBRATION_MUTED_ICON: Texture2D = preload("res://assets/interface/icons/icn_vibration_muted.png")

@onready var closeButton: TextureButton = $CloseButton
@onready var soundButton: TextureButton = $SoundButton
@onready var musicButton: TextureButton = $MusicButton
@onready var vibrationButton: TextureButton = $VibrationButton

var soundEnabled := true
var musicEnabled := true
var vibrationEnabled := true


func _ready() -> void:
	await get_tree().process_frame

	loadSettings()

	setupCloseButton()
	setupToggleButton(soundButton, Callable(self, "onSoundPressed"))
	setupToggleButton(musicButton, Callable(self, "onMusicPressed"))
	setupToggleButton(vibrationButton, Callable(self, "onVibrationPressed"))

	applySettingsToGame()
	refreshIcons()


func setupCloseButton() -> void:
	if closeButton == null:
		push_error("CloseButton not found.")
		return

	closeButton.focus_mode = Control.FOCUS_NONE
	closeButton.mouse_filter = Control.MOUSE_FILTER_STOP
	closeButton.disabled = false
	closeButton.modulate = CLOSE_NORMAL_MODULATE

	if not closeButton.button_down.is_connected(onCloseButtonDown):
		closeButton.button_down.connect(onCloseButtonDown)

	if not closeButton.button_up.is_connected(onCloseButtonUp):
		closeButton.button_up.connect(onCloseButtonUp)

	if not closeButton.mouse_exited.is_connected(onCloseButtonUp):
		closeButton.mouse_exited.connect(onCloseButtonUp)

	if not closeButton.pressed.is_connected(onClosePressed):
		closeButton.pressed.connect(onClosePressed)

	ignoreChildrenMouse(closeButton)


func setupToggleButton(button: TextureButton, callback: Callable) -> void:
	if button == null:
		return

	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.disabled = false
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)

	if not button.button_down.is_connected(onToggleButtonDown.bind(button)):
		button.button_down.connect(onToggleButtonDown.bind(button))

	if not button.button_up.is_connected(onToggleButtonUp.bind(button)):
		button.button_up.connect(onToggleButtonUp.bind(button))

	if not button.mouse_exited.is_connected(onToggleButtonUp.bind(button)):
		button.mouse_exited.connect(onToggleButtonUp.bind(button))

	ignoreChildrenMouse(button)


func ignoreChildrenMouse(button: TextureButton) -> void:
	if button == null:
		return

	for child in button.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE


func onCloseButtonDown() -> void:
	if closeButton == null:
		return

	closeButton.modulate = CLOSE_PRESSED_MODULATE


func onCloseButtonUp() -> void:
	if closeButton == null:
		return

	closeButton.modulate = CLOSE_NORMAL_MODULATE


func onClosePressed() -> void:
	onCloseButtonUp()
	closePressed.emit()


func onToggleButtonDown(button: TextureButton) -> void:
	if button == null:
		return

	button.modulate = TOGGLE_PRESSED_MODULATE


func onToggleButtonUp(button: TextureButton) -> void:
	if button == null:
		return

	refreshButtonModulate(button)


func onSoundPressed() -> void:
	soundEnabled = not soundEnabled

	applySoundSetting()
	saveSettings()
	refreshIcons()

	settingChanged.emit("sound", soundEnabled)


func onMusicPressed() -> void:
	musicEnabled = not musicEnabled

	applyMusicSetting()
	saveSettings()
	refreshIcons()

	settingChanged.emit("music", musicEnabled)


func onVibrationPressed() -> void:
	vibrationEnabled = not vibrationEnabled

	saveSettings()
	refreshIcons()

	settingChanged.emit("vibration", vibrationEnabled)


func refreshIcons() -> void:
	if soundEnabled:
		setButtonIcon(soundButton, SOUND_ICON)
	else:
		setButtonIcon(soundButton, SOUND_MUTED_ICON)

	if musicEnabled:
		setButtonIcon(musicButton, MUSIC_ICON)
	else:
		setButtonIcon(musicButton, MUSIC_MUTED_ICON)

	if vibrationEnabled:
		setButtonIcon(vibrationButton, VIBRATION_ICON)
	else:
		setButtonIcon(vibrationButton, VIBRATION_MUTED_ICON)

	refreshButtonModulate(soundButton)
	refreshButtonModulate(musicButton)
	refreshButtonModulate(vibrationButton)


func setButtonIcon(button: TextureButton, texture: Texture2D) -> void:
	if button == null:
		return

	button.texture_normal = texture
	button.texture_pressed = texture
	button.texture_hover = texture
	button.texture_focused = texture


func refreshButtonModulate(button: TextureButton) -> void:
	if button == null:
		return

	if button == soundButton:
		if soundEnabled:
			button.modulate = TOGGLE_NORMAL_MODULATE
		else:
			button.modulate = TOGGLE_DISABLED_MODULATE

	elif button == musicButton:
		if musicEnabled:
			button.modulate = TOGGLE_NORMAL_MODULATE
		else:
			button.modulate = TOGGLE_DISABLED_MODULATE

	elif button == vibrationButton:
		if vibrationEnabled:
			button.modulate = TOGGLE_NORMAL_MODULATE
		else:
			button.modulate = TOGGLE_DISABLED_MODULATE


func applySettingsToGame() -> void:
	applySoundSetting()
	applyMusicSetting()


func applySoundSetting() -> void:
	setBusMutedIfExists("SFX", not soundEnabled)
	setBusMutedIfExists("Sound", not soundEnabled)


func applyMusicSetting() -> void:
	setBusMutedIfExists("Music", not musicEnabled)


func setBusMutedIfExists(busName: String, muted: bool) -> void:
	var busIndex := AudioServer.get_bus_index(busName)

	if busIndex >= 0:
		AudioServer.set_bus_mute(busIndex, muted)


func loadSettings() -> void:
	var config := ConfigFile.new()
	var error := config.load(SETTINGS_PATH)

	if error != OK:
		return

	soundEnabled = bool(config.get_value("audio", "sound", true))
	musicEnabled = bool(config.get_value("audio", "music", true))
	vibrationEnabled = bool(config.get_value("controls", "vibration", true))


func saveSettings() -> void:
	var config := ConfigFile.new()

	config.set_value("audio", "sound", soundEnabled)
	config.set_value("audio", "music", musicEnabled)
	config.set_value("controls", "vibration", vibrationEnabled)

	config.save(SETTINGS_PATH)


func isVibrationEnabled() -> bool:
	return vibrationEnabled