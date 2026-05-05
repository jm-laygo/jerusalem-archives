extends TextureButton

@export var pressed_alpha: float = 0.8

var original_alpha: float = 1.0


func _ready() -> void:
	original_alpha = modulate.a


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			applyPressedFeedback()
		else:
			applyNormalFeedback()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		applyNormalFeedback()


func applyPressedFeedback() -> void:
	modulate.a = pressed_alpha


func applyNormalFeedback() -> void:
	modulate.a = original_alpha