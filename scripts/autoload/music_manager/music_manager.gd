extends Node

const MAIN_THEME: AudioStream = preload("res://assets/music/mx_main_theme.mp3")

const DEFAULT_MAIN_THEME_VOLUME := 1.0
const DUCKED_MAIN_THEME_VOLUME := 0.2
const VOLUME_DUCK_TIME := 0.35
const STOP_HOLD_TIME := 0.15

const RESULT_DEFAULT_VOLUME_DB := 0.0
const RESULT_SILENCE_DB := -80.0
const RESULT_FADE_OUT_DURATION := 1.25

var mainThemePlayer: AudioStreamPlayer
var resultMusicPlayer: AudioStreamPlayer

var volumeTween: Tween
var resultMusicTween: Tween

var hasStarted := false


# Creates music players and prepares the music streams.
func _ready() -> void:
	mainThemePlayer = AudioStreamPlayer.new()
	mainThemePlayer.name = "MainThemePlayer"
	mainThemePlayer.stream = MAIN_THEME
	mainThemePlayer.bus = "Master"
	mainThemePlayer.volume_db = linear_to_db(DEFAULT_MAIN_THEME_VOLUME)

	if mainThemePlayer.stream is AudioStreamMP3:
		(mainThemePlayer.stream as AudioStreamMP3).loop = false

	add_child(mainThemePlayer)

	resultMusicPlayer = AudioStreamPlayer.new()
	resultMusicPlayer.name = "ResultMusicPlayer"
	resultMusicPlayer.bus = "Master"
	resultMusicPlayer.volume_db = RESULT_DEFAULT_VOLUME_DB
	add_child(resultMusicPlayer)


# Plays the main theme only once.
func playMainThemeOnce() -> void:
	if hasStarted:
		return

	hasStarted = true
	mainThemePlayer.play()


# Lowers the main theme volume smoothly.
func duckMainTheme(
	targetVolume: float = DUCKED_MAIN_THEME_VOLUME,
	duration: float = VOLUME_DUCK_TIME
) -> void:
	if mainThemePlayer == null:
		return

	killVolumeTween()

	var targetDb := getVolumeDb(targetVolume)

	volumeTween = create_tween()
	volumeTween.tween_property(
		mainThemePlayer,
		"volume_db",
		targetDb,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# Lowers the main theme volume, waits briefly, then stops it.
func duckMainThemeThenStop(
	targetVolume: float = DUCKED_MAIN_THEME_VOLUME,
	duration: float = VOLUME_DUCK_TIME,
	holdTime: float = STOP_HOLD_TIME
) -> void:
	if mainThemePlayer == null:
		return

	killVolumeTween()

	var targetDb := getVolumeDb(targetVolume)

	volumeTween = create_tween()
	volumeTween.tween_property(
		mainThemePlayer,
		"volume_db",
		targetDb,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await volumeTween.finished

	if holdTime > 0.0:
		await get_tree().create_timer(holdTime).timeout

	if mainThemePlayer != null:
		mainThemePlayer.stop()


# Plays game over / level complete result music from the autoload.
func playResultMusic(stream: AudioStream) -> void:
	if resultMusicPlayer == null:
		return

	killResultMusicTween()

	resultMusicPlayer.stop()
	resultMusicPlayer.stream = stream
	resultMusicPlayer.volume_db = RESULT_DEFAULT_VOLUME_DB

	if resultMusicPlayer.stream != null:
		resultMusicPlayer.play()


# Fades result music while the next scene/gameplay starts.
func fadeOutResultMusic(duration: float = RESULT_FADE_OUT_DURATION) -> void:
	if resultMusicPlayer == null:
		return

	if not resultMusicPlayer.playing:
		return

	killResultMusicTween()

	resultMusicTween = create_tween()
	resultMusicTween.tween_property(
		resultMusicPlayer,
		"volume_db",
		RESULT_SILENCE_DB,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await resultMusicTween.finished

	if resultMusicPlayer != null:
		resultMusicPlayer.stop()
		resultMusicPlayer.volume_db = RESULT_DEFAULT_VOLUME_DB


# Immediately stops result music.
func stopResultMusic() -> void:
	killResultMusicTween()

	if resultMusicPlayer != null:
		resultMusicPlayer.stop()
		resultMusicPlayer.volume_db = RESULT_DEFAULT_VOLUME_DB


# Converts a linear volume value into decibels safely.
func getVolumeDb(volume: float) -> float:
	var clampedVolume := clampf(volume, 0.0, 1.0)
	return linear_to_db(max(clampedVolume, 0.001))


# Stops the active main theme volume tween.
func killVolumeTween() -> void:
	if volumeTween != null and volumeTween.is_valid():
		volumeTween.kill()


# Stops the active result music tween.
func killResultMusicTween() -> void:
	if resultMusicTween != null and resultMusicTween.is_valid():
		resultMusicTween.kill()
