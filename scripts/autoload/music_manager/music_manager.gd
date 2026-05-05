extends Node

const MAIN_THEME: AudioStream = preload("res://assets/music/main_theme.mp3")

var _player: AudioStreamPlayer
var _has_started: bool = false


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.stream = MAIN_THEME
	_player.bus = "Master"

	if _player.stream is AudioStreamMP3:
		(_player.stream as AudioStreamMP3).loop = false

	add_child(_player)


func play_main_theme_once() -> void:
	if _has_started:
		return

	_has_started = true
	_player.play()