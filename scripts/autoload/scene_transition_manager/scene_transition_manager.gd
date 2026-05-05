extends CanvasLayer

const OVERLAY_COLOR := Color(0, 0, 0, 1)

var _overlay: ColorRect
var _is_transitioning: bool = false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	_overlay = ColorRect.new()
	_overlay.name = "Overlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.color = OVERLAY_COLOR
	_overlay.modulate.a = 0.0
	_overlay.visible = false
	add_child(_overlay)


func change_scene_with_fade(scene_path: String, fade_out_duration: float = 0.95, fade_in_duration: float = 0.55) -> void:
	if _is_transitioning:
		return

	_is_transitioning = true
	_overlay.visible = true

	var fade_out: Tween = create_tween()
	fade_out.tween_property(_overlay, "modulate:a", 1.0, fade_out_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fade_out.finished

	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await get_tree().process_frame

	var fade_in: Tween = create_tween()
	fade_in.tween_property(_overlay, "modulate:a", 0.0, fade_in_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await fade_in.finished

	_overlay.visible = false
	_is_transitioning = false
