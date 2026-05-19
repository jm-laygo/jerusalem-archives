extends CanvasLayer

const OVERLAY_COLOR := Color(0, 0, 0, 1)
const TRANSITION_LAYER := 9999

var overlay: ColorRect
var isTransitioning := false


# Creates the full-screen fade overlay.
func _ready() -> void:
	layer = TRANSITION_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS

	overlay = ColorRect.new()
	overlay.name = "Overlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.color = OVERLAY_COLOR
	overlay.modulate.a = 0.0
	overlay.visible = false

	add_child(overlay)


# Changes scene using a fade-out and fade-in transition.
func changeSceneWithFade(
	scenePath: String,
	fadeOutDuration: float = 0.95,
	fadeInDuration: float = 0.55
) -> void:
	if isTransitioning:
		return

	isTransitioning = true
	overlay.visible = true

	await fadeOverlay(1.0, fadeOutDuration, Tween.EASE_IN)

	get_tree().change_scene_to_file(scenePath)

	await get_tree().process_frame
	await get_tree().process_frame

	await fadeOverlay(0.0, fadeInDuration, Tween.EASE_OUT)

	overlay.visible = false
	isTransitioning = false


# Fades the overlay alpha to the target value.
func fadeOverlay(targetAlpha: float, duration: float, easeType: Tween.EaseType) -> void:
	var fadeTween := create_tween()

	fadeTween.tween_property(
		overlay,
		"modulate:a",
		targetAlpha,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(easeType)

	await fadeTween.finished
