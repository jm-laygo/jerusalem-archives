extends RefCounted

var gameplay: Control


# Stores the gameplay screen reference used by this audio system.
func _init(gameplayOwner: Control) -> void:
	gameplay = gameplayOwner


# Allows important audio players to continue while the game is paused.
func setupAudioProcessMode() -> void:
	var audioPlayers := [
		gameplay.pauseClickSound,
		gameplay.pauseMenuClickSound,
		gameplay.hintClickSound,
		gameplay.checkCorrectSound,
		gameplay.checkIncorrectSound,
		gameplay.infoClickSound,
		gameplay.rowClickSound,
		gameplay.titleHeaderClickSound
	]

	for player in audioPlayers:
		if player != null:
			player.process_mode = Node.PROCESS_MODE_ALWAYS

	if gameplay.startGameplaySound != null:
		gameplay.startGameplaySound.process_mode = Node.PROCESS_MODE_ALWAYS
		gameplay.startGameplaySound.stream = gameplay.START_GAMEPLAY_SOUND


# Plays the start gameplay sound.
func playStartGameplaySound() -> void:
	if gameplay.startGameplaySound == null:
		gameplay.startGameplaySound = AudioStreamPlayer.new()
		gameplay.startGameplaySound.name = "StartGameplaySound"
		gameplay.startGameplaySound.stream = gameplay.START_GAMEPLAY_SOUND
		gameplay.startGameplaySound.bus = "Master"
		gameplay.startGameplaySound.process_mode = Node.PROCESS_MODE_ALWAYS
		gameplay.add_child(gameplay.startGameplaySound)

	gameplay.startGameplaySound.stop()
	gameplay.startGameplaySound.play()


# Plays a footer-related sound as a persistent sound.
func playFooterClickSound(soundPlayer: AudioStreamPlayer) -> void:
	if soundPlayer == null or soundPlayer.stream == null:
		return

	playPersistentSound(soundPlayer.stream)


# Plays the pause button click sound.
func playPauseClickSound() -> void:
	playSound(gameplay.pauseClickSound)


# Plays a pause menu click sound.
func playPauseMenuClickSound() -> void:
	playSound(gameplay.pauseMenuClickSound)


# Plays a reusable audio player from the start.
func playSound(player: AudioStreamPlayer) -> void:
	if player == null:
		return

	player.stop()
	player.play()


# Plays a sound that can continue even if the scene changes or pauses.
func playPersistentSound(sound: AudioStream) -> void:
	if sound == null:
		return

	var soundPlayer := AudioStreamPlayer.new()
	soundPlayer.stream = sound
	soundPlayer.bus = "Master"
	soundPlayer.process_mode = Node.PROCESS_MODE_ALWAYS

	gameplay.get_tree().root.add_child(soundPlayer)
	soundPlayer.play()
	soundPlayer.finished.connect(soundPlayer.queue_free)