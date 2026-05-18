extends RefCounted

const LIVES_ICON_PATH_FORMAT := "res://assets/interface/icons/icon_lives0%s.png"

const LIVES_FULL_COLOR := Color(0.35, 1.0, 0.35, 1.0)
const LIVES_NORMAL_COLOR := Color(1, 1, 1, 1)
const LIVES_WARNING_COLOR := Color(1.0, 0.55, 0.15, 1.0)
const LIVES_CRITICAL_COLOR := Color(1.0, 0.12, 0.12, 1.0)

const TIMER_NORMAL_COLOR := Color(0.972549, 0.909804, 0.74902, 1)
const TIMER_WARNING_COLOR := Color(1.0, 0.72, 0.18, 1.0)
const TIMER_CRITICAL_COLOR := Color(1.0, 0.18, 0.12, 1.0)

const HUD_POP_SCALE := Vector2(1.18, 1.18)
const HUD_NORMAL_SCALE := Vector2.ONE
const HUD_POP_TIME := 0.08
const HUD_RETURN_TIME := 0.14

const STAR_POP_SCALE := Vector2(1.22, 1.22)
const STAR_NORMAL_SCALE := Vector2.ONE
const STAR_POP_TIME := 0.10
const STAR_RETURN_TIME := 0.16

var gameplay: Control

var previousHearts := -1
var previousStars := -1
var livesTween: Tween
var timerTween: Tween
var starTweens := {}


# Stores the gameplay screen reference used by this HUD system.
func _init(gameplayOwner: Control) -> void:
	gameplay = gameplayOwner


# Updates all HUD elements.
func updateHud() -> void:
	updateLivesDisplay()
	updateTimerDisplay()
	updateStarDisplay()


# Updates the lives icon and lives text.
func updateLivesDisplay() -> void:
	var safeHearts: int = clamp(gameplay.hearts, 0, gameplay.maxHearts)

	updateLivesIcon(safeHearts)
	updateLivesText(safeHearts)

	if previousHearts != -1 and safeHearts < previousHearts:
		animateLivesDamage()

	previousHearts = safeHearts


# Updates the lives icon based on the current heart count.
func updateLivesIcon(safeHearts: int) -> void:
	if gameplay.livesIcon == null:
		return

	var iconNumber: int = clamp(safeHearts, 1, 4)
	var iconTexture: Texture2D = load(LIVES_ICON_PATH_FORMAT % iconNumber)

	if iconTexture != null:
		gameplay.livesIcon.texture = iconTexture


# Updates the lives text and color.
func updateLivesText(safeHearts: int) -> void:
	if gameplay.livesText == null:
		return

	gameplay.livesText.text = "%s/%s" % [safeHearts, gameplay.maxHearts]
	gameplay.livesText.add_theme_color_override("font_color", getLivesTextColor(safeHearts))


# Returns the lives text color based on remaining hearts.
func getLivesTextColor(safeHearts: int) -> Color:
	if safeHearts >= 4:
		return LIVES_FULL_COLOR

	if safeHearts == 3:
		return LIVES_NORMAL_COLOR

	if safeHearts == 2:
		return LIVES_WARNING_COLOR

	return LIVES_CRITICAL_COLOR


# Animates lives icon and text when a life is lost.
func animateLivesDamage() -> void:
	if livesTween != null and livesTween.is_valid():
		livesTween.kill()

	if gameplay.livesIcon != null:
		gameplay.livesIcon.scale = HUD_NORMAL_SCALE
		gameplay.livesIcon.pivot_offset = gameplay.livesIcon.size * 0.5

	if gameplay.livesText != null:
		gameplay.livesText.scale = HUD_NORMAL_SCALE
		gameplay.livesText.pivot_offset = gameplay.livesText.size * 0.5

	livesTween = gameplay.create_tween()
	livesTween.set_parallel(true)

	if gameplay.livesIcon != null:
		livesTween.tween_property(gameplay.livesIcon, "scale", HUD_POP_SCALE, HUD_POP_TIME)
		livesTween.tween_property(gameplay.livesIcon, "scale", HUD_NORMAL_SCALE, HUD_RETURN_TIME).set_delay(HUD_POP_TIME)

	if gameplay.livesText != null:
		livesTween.tween_property(gameplay.livesText, "scale", HUD_POP_SCALE, HUD_POP_TIME)
		livesTween.tween_property(gameplay.livesText, "scale", HUD_NORMAL_SCALE, HUD_RETURN_TIME).set_delay(HUD_POP_TIME)


# Updates the timer text and warning color.
func updateTimerDisplay() -> void:
	if gameplay.timeText == null:
		return

	var secondsLeft := int(ceil(gameplay.timeRemaining))
	gameplay.timeText.text = formatTime(secondsLeft)
	gameplay.timeText.add_theme_color_override("font_color", getTimerColor(secondsLeft))

	if secondsLeft <= 10 and secondsLeft > 0:
		animateTimerPulse()


# Returns the timer color based on remaining time.
func getTimerColor(secondsLeft: int) -> Color:
	if secondsLeft <= 30:
		return TIMER_CRITICAL_COLOR

	if secondsLeft <= 60:
		return TIMER_WARNING_COLOR

	return TIMER_NORMAL_COLOR


# Pulses the timer during the final 10 seconds.
func animateTimerPulse() -> void:
	if gameplay.timeText == null:
		return

	if timerTween != null and timerTween.is_valid():
		return

	gameplay.timeText.pivot_offset = gameplay.timeText.size * 0.5
	gameplay.timeText.scale = HUD_NORMAL_SCALE

	timerTween = gameplay.create_tween()
	timerTween.tween_property(gameplay.timeText, "scale", Vector2(1.08, 1.08), 0.08)
	timerTween.tween_property(gameplay.timeText, "scale", HUD_NORMAL_SCALE, 0.12)
	await timerTween.finished
	timerTween = null


# Updates the star icons based on current performance.
func updateStarDisplay(animateChange: bool = true) -> void:
	var newStars: int = calculateCurrentStars()
	gameplay.currentStars = newStars

	var starIcons := [
		gameplay.starLeft,
		gameplay.starMiddle,
		gameplay.starRight
	]

	for index in range(starIcons.size()):
		var starIcon := starIcons[index] as TextureRect

		if starIcon == null:
			continue

		starIcon.visible = true
		starIcon.texture = gameplay.STAR_FILLED_TEXTURE if index < gameplay.currentStars else gameplay.STAR_EMPTY_TEXTURE

	if animateChange and previousStars != -1 and newStars < previousStars:
		animateLostStars(previousStars, newStars)

	previousStars = newStars


# Animates stars that were lost.
func animateLostStars(oldStars: int, newStars: int) -> void:
	var starIcons := [
		gameplay.starLeft,
		gameplay.starMiddle,
		gameplay.starRight
	]

	for index in range(newStars, oldStars):
		if index < 0 or index >= starIcons.size():
			continue

		var starIcon := starIcons[index] as TextureRect

		if starIcon != null:
			animateStar(starIcon)


# Pops one star icon.
func animateStar(starIcon: TextureRect) -> void:
	if starTweens.has(starIcon):
		var oldTween: Tween = starTweens[starIcon]

		if oldTween != null and oldTween.is_valid():
			oldTween.kill()

	starIcon.pivot_offset = starIcon.size * 0.5
	starIcon.scale = STAR_NORMAL_SCALE

	var tween := gameplay.create_tween()
	starTweens[starIcon] = tween

	tween.tween_property(starIcon, "scale", STAR_POP_SCALE, STAR_POP_TIME)
	tween.tween_property(starIcon, "scale", STAR_NORMAL_SCALE, STAR_RETURN_TIME)


# Calculates current stars using fair penalty rules.
func calculateCurrentStars() -> int:
	if gameplay.hearts <= 0:
		return 0

	if gameplay.timeRemaining <= 0.0:
		return 0

	var penaltyPoints := 0

	penaltyPoints += getLivesPenalty()
	penaltyPoints += getTimePenalty()
	penaltyPoints += getHintPenalty()

	if penaltyPoints <= 1:
		return 3

	if penaltyPoints <= 3:
		return 2

	return 1


# Calculates penalty from lives lost.
func getLivesPenalty() -> int:
	var livesLost: int = gameplay.maxHearts - gameplay.hearts

	if livesLost <= 0:
		return 0

	if livesLost == 1:
		return 1

	if livesLost == 2:
		return 2

	return 3


# Calculates penalty from time used.
func getTimePenalty() -> int:
	if gameplay.levelTimeLimit <= 0.0:
		return 0

	var timeUsed: float = float(gameplay.levelTimeLimit) - float(gameplay.timeRemaining)
	var timeUsedRatio: float = timeUsed / float(gameplay.levelTimeLimit)

	if timeUsedRatio <= 0.60:
		return 0

	if timeUsedRatio <= 0.80:
		return 1

	return 2


# Calculates light penalty from hint usage.
func getHintPenalty() -> int:
	if gameplay.hintsUsed <= 1:
		return 0

	if gameplay.hintsUsed <= 3:
		return 1

	return 2


# Formats seconds into MM:SS.
func formatTime(seconds: int) -> String:
	var minutes := int(seconds / 60.0)
	var remainingSeconds := seconds % 60

	return "%02d:%02d" % [minutes, remainingSeconds]