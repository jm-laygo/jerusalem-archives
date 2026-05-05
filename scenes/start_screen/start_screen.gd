extends Control

@export var display_time: float = 4.0
@export var fade_out_duration: float = 0.95
@export var fade_in_duration: float = 0.55
@onready var start_timer: Timer = $StartTimer


func _ready() -> void:
	var music_manager: Node = get_node_or_null("/root/MusicManager")
	if music_manager != null and music_manager.has_method("play_main_theme_once"):
		music_manager.call("play_main_theme_once")

	start_timer.wait_time = display_time
	start_timer.start()


func _on_start_timer_timeout() -> void:
	var transition_manager: Node = get_node_or_null("/root/SceneTransitionManager")
	if transition_manager != null and transition_manager.has_method("change_scene_with_fade"):
		transition_manager.call("change_scene_with_fade", "res://scenes/main_menu/main_menu.tscn", fade_out_duration, fade_in_duration)
		return

	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
