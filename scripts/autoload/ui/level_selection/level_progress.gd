extends Node

const SAVE_PATH := "user://level_progress.cfg"

var config := ConfigFile.new()


func _ready() -> void:
	loadProgress()


func loadProgress() -> void:
	var error := config.load(SAVE_PATH)

	if error != OK:
		config.set_value("chapter_1", "unlocked_level", 1)
		saveProgress()


func saveProgress() -> void:
	config.save(SAVE_PATH)


func getUnlockedLevel(chapterId: int) -> int:
	return int(config.get_value("chapter_%s" % chapterId, "unlocked_level", 1))


func getStars(chapterId: int, levelNumber: int) -> int:
	return int(config.get_value("chapter_%s" % chapterId, "level_%s_stars" % levelNumber, 0))


func completeLevel(chapterId: int, levelNumber: int, stars: int) -> void:
	var cleanStars := clampi(stars, 0, 3)
	var currentStars := getStars(chapterId, levelNumber)

	if cleanStars > currentStars:
		config.set_value("chapter_%s" % chapterId, "level_%s_stars" % levelNumber, cleanStars)

	var unlockedLevel := getUnlockedLevel(chapterId)

	if levelNumber >= unlockedLevel:
		config.set_value("chapter_%s" % chapterId, "unlocked_level", levelNumber + 1)

	saveProgress()

	print("Progress saved. Chapter: %s Level: %s Stars: %s Unlocked: %s" % [
		chapterId,
		levelNumber,
		cleanStars,
		getUnlockedLevel(chapterId)
	])