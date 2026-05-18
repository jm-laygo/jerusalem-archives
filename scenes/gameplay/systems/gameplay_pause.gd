extends RefCounted

const PAUSE_FADE_TIME := 0.12
const BACK_TO_MENU_DELAY := 0.08
const MAIN_MENU_FADE_OUT_TIME := 0.50
const MAIN_MENU_FADE_IN_TIME := 0.30

const PAUSE_BUTTON_NORMAL_MODULATE := Color(1, 1, 1, 1)
const PAUSE_BUTTON_HOLD_MODULATE := Color(1.25, 1.25, 1.25, 1.0)

var gameplay: Control


# Stores the gameplay screen reference used by this pause system.
func _init(gameplayOwner: Control) -> void:
	gameplay = gameplayOwner


# Connects the top HUD pause button.
func connectPauseButton() -> void:
	if gameplay.pauseButton == null:
		return

	gameplay.pauseButton.focus_mode = Control.FOCUS_NONE
	gameplay.pauseButton.mouse_filter = Control.MOUSE_FILTER_STOP
	gameplay.pauseButton.scale = Vector2.ONE
	gameplay.pauseButton.modulate = PAUSE_BUTTON_NORMAL_MODULATE

	if not gameplay.pauseButton.gui_input.is_connected(onPauseButtonGuiInput):
		gameplay.pauseButton.gui_input.connect(onPauseButtonGuiInput)


# Handles mouse/touch input for the pause button.
func onPauseButtonGuiInput(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		handlePauseMouseButton(event)
		return

	if event is InputEventScreenTouch:
		handlePauseScreenTouch(event)


# Handles mouse pause button press/release.
func handlePauseMouseButton(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		gameplay.isPauseButtonHolding = true
		applyPauseButtonHold()
		gameplay.get_viewport().set_input_as_handled()
		return

	var shouldOpen: bool = gameplay.isPauseButtonHolding and isMouseInsidePauseButton()

	gameplay.isPauseButtonHolding = false
	resetPauseButtonHold()

	if shouldOpen:
		openPauseOverlay()

	gameplay.get_viewport().set_input_as_handled()


# Handles touch pause button press/release.
func handlePauseScreenTouch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		gameplay.isPauseButtonHolding = true
		applyPauseButtonHold()
		gameplay.get_viewport().set_input_as_handled()
		return

	var shouldOpen: bool = gameplay.isPauseButtonHolding and isMouseInsidePauseButton()

	gameplay.isPauseButtonHolding = false
	resetPauseButtonHold()

	if shouldOpen:
		openPauseOverlay()

	gameplay.get_viewport().set_input_as_handled()


# Applies pause button hold feedback.
func applyPauseButtonHold() -> void:
	if gameplay.pauseButton == null:
		return

	gameplay.pauseButton.modulate = PAUSE_BUTTON_HOLD_MODULATE
	gameplay.pauseButton.scale = Vector2.ONE


# Restores pause button feedback.
func resetPauseButtonHold() -> void:
	if gameplay.pauseButton == null:
		return

	gameplay.pauseButton.modulate = PAUSE_BUTTON_NORMAL_MODULATE
	gameplay.pauseButton.scale = Vector2.ONE


# Checks if pointer is still inside the pause button.
func isMouseInsidePauseButton() -> bool:
	if gameplay.pauseButton == null:
		return false

	return gameplay.pauseButton.get_global_rect().has_point(gameplay.get_global_mouse_position())


# Opens and fades in the pause overlay.
func openPauseOverlay() -> void:
	if gameplay.isPauseOpening:
		return

	if gameplay.pauseOverlay != null and is_instance_valid(gameplay.pauseOverlay):
		return

	gameplay.isPauseOpening = true
	gameplay.audioSystem.playPauseClickSound()

	gameplay.pauseOverlay = gameplay.PAUSE_OVERLAY_SCENE.instantiate()
	gameplay.add_child(gameplay.pauseOverlay)

	configurePauseOverlay()
	connectPauseOverlaySignals()

	gameplay.pauseOverlay.modulate = Color(1, 1, 1, 0)
	gameplay.pauseOverlay.visible = true

	var fadeTween := gameplay.create_tween()
	fadeTween.set_trans(Tween.TRANS_SINE)
	fadeTween.set_ease(Tween.EASE_OUT)
	fadeTween.tween_property(gameplay.pauseOverlay, "modulate", Color(1, 1, 1, 1), PAUSE_FADE_TIME)

	await fadeTween.finished

	gameplay.get_tree().paused = true
	gameplay.isPauseOpening = false


# Configures the pause overlay after instancing.
func configurePauseOverlay() -> void:
	if gameplay.pauseOverlay == null or not is_instance_valid(gameplay.pauseOverlay):
		return

	gameplay.pauseOverlay.visible = true
	gameplay.pauseOverlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	gameplay.pauseOverlay.offset_left = 0.0
	gameplay.pauseOverlay.offset_top = 0.0
	gameplay.pauseOverlay.offset_right = 0.0
	gameplay.pauseOverlay.offset_bottom = 0.0
	gameplay.pauseOverlay.mouse_filter = Control.MOUSE_FILTER_STOP
	gameplay.pauseOverlay.process_mode = Node.PROCESS_MODE_ALWAYS


# Connects pause overlay button signals.
func connectPauseOverlaySignals() -> void:
	if gameplay.pauseOverlay == null or not is_instance_valid(gameplay.pauseOverlay):
		return

	connectSignalIfAvailable(gameplay.pauseOverlay, "resumePressed", Callable(gameplay, "onPauseResumePressed"))
	connectSignalIfAvailable(gameplay.pauseOverlay, "achievementsPressed", Callable(gameplay, "onPauseAchievementsPressed"))
	connectSignalIfAvailable(gameplay.pauseOverlay, "settingsPressed", Callable(gameplay, "onPauseSettingsPressed"))
	connectSignalIfAvailable(gameplay.pauseOverlay, "backToMenuPressed", Callable(gameplay, "onPauseBackToMenuPressed"))


# Connects a signal only when available.
func connectSignalIfAvailable(target: Object, signalName: String, callback: Callable) -> void:
	if target == null:
		return

	if not target.has_signal(signalName):
		push_error("%s has no %s signal." % [target.name, signalName])
		return

	if not target.is_connected(signalName, callback):
		target.connect(signalName, callback)


# Resumes gameplay and removes the overlay.
func resumeGameplay() -> void:
	gameplay.audioSystem.playPauseMenuClickSound()
	gameplay.get_tree().paused = false

	if gameplay.pauseOverlay != null and is_instance_valid(gameplay.pauseOverlay):
		gameplay.pauseOverlay.queue_free()
		gameplay.pauseOverlay = null


# Returns to the main menu from the pause overlay.
func backToMainMenu() -> void:
	gameplay.audioSystem.playPauseMenuClickSound()
	gameplay.get_tree().paused = false

	await gameplay.get_tree().create_timer(BACK_TO_MENU_DELAY).timeout
	changeSceneToMainMenu()


# Changes scene to the main menu.
func changeSceneToMainMenu() -> void:
	var transitionManager: Node = gameplay.get_node_or_null("/root/SceneTransitionManager")

	if transitionManager != null and transitionManager.has_method("changeSceneWithFade"):
		transitionManager.call(
			"changeSceneWithFade",
			gameplay.MAIN_MENU_SCENE_PATH,
			MAIN_MENU_FADE_OUT_TIME,
			MAIN_MENU_FADE_IN_TIME
		)
		return

	gameplay.get_tree().change_scene_to_file(gameplay.MAIN_MENU_SCENE_PATH)