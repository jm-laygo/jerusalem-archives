extends Node

const MAIN_THEME: AudioStream = preload("res://assets/music/mx_main_theme.mp3")

# Ambient tracks.
const AMBIENT_TRACKS := [
	preload("res://assets/music/mx_music1.wav"),
	preload("res://assets/music/mx_music2.wav"),
	preload("res://assets/music/mx_music3.wav"),
	preload("res://assets/music/mx_music4.wav"),
	preload("res://assets/music/mx_music5.wav"),
	preload("res://assets/music/mx_music6.wav"),
	preload("res://assets/music/mx_music7.wav"),
	preload("res://assets/music/mx_music8.wav"),
	preload("res://assets/music/mx_music9.wav"),
	preload("res://assets/music/mx_music10.wav"),
	preload("res://assets/music/mx_music11.wav"),
	preload("res://assets/music/mx_music12.wav"),
	preload("res://assets/music/mx_music13.wav"),
	preload("res://assets/music/mx_music14.wav")
]

# Gameplay-specific tracks.
const GAMEPLAY_TRACKS := [
	preload("res://assets/music/mx_music14.wav"),
	preload("res://assets/music/mx_music5.wav"),
	preload("res://assets/music/mx_music12.wav")
]

const AMBIENT_START_DELAY := 5.0

const DEFAULT_MAIN_THEME_VOLUME := 1.0
const DUCKED_MAIN_THEME_VOLUME := 0.2
const VOLUME_DUCK_TIME := 0.35
const STOP_HOLD_TIME := 0.15

const RESULT_DEFAULT_VOLUME_DB := 0.0
const RESULT_SILENCE_DB := -80.0
const RESULT_FADE_OUT_DURATION := 1.25

var mainThemePlayer: AudioStreamPlayer
var resultMusicPlayer: AudioStreamPlayer
var ambientPlayer: AudioStreamPlayer
var gameplayPlayer: AudioStreamPlayer

var volumeTween: Tween
var resultMusicTween: Tween

var hasStarted := false
var ambientActive := false
var gameplayActive := false
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()

	mainThemePlayer = AudioStreamPlayer.new()
	mainThemePlayer.name = "MainThemePlayer"
	mainThemePlayer.stream = prepareStream(MAIN_THEME, false)
	mainThemePlayer.bus = "Master"
	mainThemePlayer.volume_db = linear_to_db(DEFAULT_MAIN_THEME_VOLUME)
	add_child(mainThemePlayer)

	ambientPlayer = AudioStreamPlayer.new()
	ambientPlayer.name = "AmbientPlayer"
	ambientPlayer.bus = "Master"
	ambientPlayer.volume_db = linear_to_db(DEFAULT_MAIN_THEME_VOLUME)
	ambientPlayer.stream = null
	add_child(ambientPlayer)

	if not ambientPlayer.finished.is_connected(_onAmbientFinished):
		ambientPlayer.finished.connect(_onAmbientFinished)

	gameplayPlayer = AudioStreamPlayer.new()
	gameplayPlayer.name = "GameplayPlayer"
	gameplayPlayer.bus = "Master"
	gameplayPlayer.volume_db = linear_to_db(DEFAULT_MAIN_THEME_VOLUME)
	gameplayPlayer.stream = null
	add_child(gameplayPlayer)

	resultMusicPlayer = AudioStreamPlayer.new()
	resultMusicPlayer.name = "ResultMusicPlayer"
	resultMusicPlayer.bus = "Master"
	resultMusicPlayer.volume_db = RESULT_DEFAULT_VOLUME_DB
	resultMusicPlayer.stream = null
	add_child(resultMusicPlayer)


func prepareStream(sourceStream: AudioStream, shouldLoop: bool) -> AudioStream:
	if sourceStream == null:
		return null

	var newStream: AudioStream = sourceStream.duplicate()
	setStreamLoop(newStream, shouldLoop)
	return newStream


func setStreamLoop(targetStream: AudioStream, shouldLoop: bool) -> void:
	if targetStream == null:
		return

	if targetStream is AudioStreamMP3:
		(targetStream as AudioStreamMP3).loop = shouldLoop

	elif targetStream is AudioStreamWAV:
		if shouldLoop:
			(targetStream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		else:
			(targetStream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED

	elif targetStream is AudioStreamOggVorbis:
		(targetStream as AudioStreamOggVorbis).loop = shouldLoop


func playMainThemeOnce() -> void:
	if hasStarted:
		return

	hasStarted = true

	if mainThemePlayer == null:
		return

	mainThemePlayer.stop()
	mainThemePlayer.stream = prepareStream(MAIN_THEME, false)
	mainThemePlayer.volume_db = linear_to_db(DEFAULT_MAIN_THEME_VOLUME)
	mainThemePlayer.play()

	if not mainThemePlayer.finished.is_connected(_onMainThemeFinished):
		mainThemePlayer.finished.connect(_onMainThemeFinished)


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


func playResultMusic(stream: AudioStream) -> void:
	if resultMusicPlayer == null:
		return

	killResultMusicTween()

	resultMusicPlayer.stop()
	resultMusicPlayer.stream = prepareStream(stream, false)
	resultMusicPlayer.volume_db = RESULT_DEFAULT_VOLUME_DB

	if resultMusicPlayer.stream != null:
		resultMusicPlayer.play()

	ambientActive = false


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


func stopResultMusic() -> void:
	killResultMusicTween()

	if resultMusicPlayer != null:
		resultMusicPlayer.stop()
		resultMusicPlayer.volume_db = RESULT_DEFAULT_VOLUME_DB

	ambientActive = false


func _onMainThemeFinished() -> void:
	ambientActive = false

	await get_tree().create_timer(AMBIENT_START_DELAY).timeout

	if not gameplayActive:
		startAmbientLoop()


func startAmbientLoop() -> void:
	if ambientPlayer == null:
		return

	if gameplayActive:
		return

	ambientActive = true
	playRandomAmbient()


func playRandomAmbient() -> void:
	if ambientPlayer == null:
		return

	if not ambientActive:
		return

	if gameplayActive:
		return

	if AMBIENT_TRACKS.size() == 0:
		return

	var index := rng.randi_range(0, AMBIENT_TRACKS.size() - 1)

	ambientPlayer.stop()
	ambientPlayer.stream = prepareStream(AMBIENT_TRACKS[index], false)
	ambientPlayer.volume_db = linear_to_db(DEFAULT_MAIN_THEME_VOLUME)
	ambientPlayer.play()


func _onAmbientFinished() -> void:
	if not ambientActive:
		return

	if gameplayActive:
		return

	await get_tree().create_timer(0.5).timeout

	if ambientActive and not gameplayActive:
		playRandomAmbient()


func stopAmbientLoop() -> void:
	ambientActive = false

	if ambientPlayer != null:
		ambientPlayer.stop()


func enterGameplay(preferred: AudioStream = null) -> void:
	gameplayActive = true
	ambientActive = false

	if ambientPlayer != null:
		ambientPlayer.stop()

	if mainThemePlayer != null:
		mainThemePlayer.stop()

	stopResultMusic()

	var selectedStream := preferred

	if selectedStream == null and GAMEPLAY_TRACKS.size() > 0:
		selectedStream = GAMEPLAY_TRACKS[rng.randi_range(0, GAMEPLAY_TRACKS.size() - 1)]

	if selectedStream == null:
		return

	gameplayPlayer.stop()
	gameplayPlayer.stream = prepareStream(selectedStream, true)
	gameplayPlayer.volume_db = linear_to_db(DEFAULT_MAIN_THEME_VOLUME)
	gameplayPlayer.play()


func exitGameplay() -> void:
	gameplayActive = false

	if gameplayPlayer != null:
		gameplayPlayer.stop()

	await get_tree().create_timer(AMBIENT_START_DELAY).timeout

	if not gameplayActive:
		startAmbientLoop()


func getVolumeDb(volume: float) -> float:
	var clampedVolume := clampf(volume, 0.0, 1.0)
	return linear_to_db(max(clampedVolume, 0.001))


func killVolumeTween() -> void:
	if volumeTween != null and volumeTween.is_valid():
		volumeTween.kill()


func killResultMusicTween() -> void:
	if resultMusicTween != null and resultMusicTween.is_valid():
		resultMusicTween.kill()