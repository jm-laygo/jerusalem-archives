extends RefCounted

const LIVES_ICON_PATH_FORMAT := "res://assets/interface/icons/icon_lives0%s.png"

const LIVES_FULL_COLOR := Color(0.35, 1.0, 0.35, 1.0)
const LIVES_NORMAL_COLOR := Color(1, 1, 1, 1)
const LIVES_WARNING_COLOR := Color(1.0, 0.55, 0.15, 1.0)
const LIVES_CRITICAL_COLOR := Color(0.35, 0.35, 0.35, 1.0)

var gameplay: Control


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


# Updates the timer text.
func updateTimerDisplay() -> void:
	if gameplay.timeText == null:
		return

	gameplay.timeText.text = formatTime(int(ceil(gameplay.timeRemaining)))


# Updates the star icons based on current performance.
func updateStarDisplay() -> void:
	gameplay.currentStars = calculateCurrentStars()

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

		if index < gameplay.currentStars:
			starIcon.texture = gameplay.STAR_FILLED_TEXTURE
		else:
			starIcon.texture = gameplay.STAR_EMPTY_TEXTURE


# Calculates current stars based on lives lost and hints used.
func calculateCurrentStars() -> int:
	if gameplay.hearts <= 0:
		return 0

	var livesLost: int = gameplay.maxHearts - gameplay.hearts
	var starsLostFromLives: int = int(floor(float(livesLost) / 2.0))
	var starsLostFromHints: int = int(floor(float(gameplay.hintsUsed) / 2.0))

	return clamp(3 - starsLostFromLives - starsLostFromHints, 1, 3)


# Formats seconds into MM:SS.
func formatTime(seconds: int) -> String:
	var minutes := int(seconds / 60.0)
	var remainingSeconds := seconds % 60

	return "%02d:%02d" % [minutes, remainingSeconds]