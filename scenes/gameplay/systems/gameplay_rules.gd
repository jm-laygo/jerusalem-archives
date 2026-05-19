extends RefCounted

const OBJECTIVE_NORMAL_FONT_SIZE := 40

const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu/main_menu.tscn"

var gameplay: Control


# Stores the gameplay screen reference used by this rules system.
func _init(gameplayOwner: Control) -> void:
	gameplay = gameplayOwner


# Loads the chosen level.
func loadLevel(levelNumber: int) -> void:
	gameplay.levelFinished = false
	gameplay.activeSortColumnKey = ""
	gameplay.selectedRecord = {}
	gameplay.selectedRow = null

	gameplay.currentLevel = loadLevelFromDatabase(levelNumber)

	if gameplay.currentLevel.is_empty():
		push_error("No level data found: %s" % levelNumber)
		return

	gameplay.currentColumns = gameplay.currentLevel.get("columns", [])
	gameplay.currentRecords = gameplay.currentLevel.get("records", [])
	gameplay.originalRecords = gameplay.currentRecords.duplicate(true)

	gameplay.correctRecordId = str(gameplay.currentLevel.get("correct_record_id", ""))

	gameplay.maxHearts = int(gameplay.currentLevel.get("hearts", 4))
	gameplay.hearts = gameplay.maxHearts

	gameplay.hintIndex = 0
	gameplay.hintsUsed = 0

	gameplay.levelTimeLimit = float(gameplay.currentLevel.get("time_limit", 240))
	gameplay.timeRemaining = gameplay.levelTimeLimit

	gameplay.currentStars = 3

	if gameplay.levelText != null:
		gameplay.levelText.text = "Level %s" % levelNumber

	setLevelObjectiveHeader()

	if gameplay.selectionSystem != null:
		gameplay.selectionSystem.configureFromLevel(gameplay.currentLevel)
		gameplay.selectionSystem.resetSelection()

	gameplay.scrollX = 0.0
	gameplay.scrollY = 0.0
	gameplay.dragAxis = ""

	gameplay.updateHud()
	gameplay.buildTable()
	gameplay.call_deferred("refreshScrollLimits")

	if gameplay.has_method("updateActionButtonsState"):
		gameplay.updateActionButtonsState()


# Shows only the short objective in the objective header.
func setLevelObjectiveHeader() -> void:
	var objectiveText: String = str(gameplay.currentLevel.get("objective", "Identify the correct archive record."))

	gameplay.setObjectiveText(
		objectiveText,
		OBJECTIVE_NORMAL_FONT_SIZE
	)


# Loads one level from SQLite through the level repository.
func loadLevelFromDatabase(levelNumber: int) -> Dictionary:
	if gameplay.levelRepository == null:
		push_error("LevelRepository is not available.")
		return {}

	if not gameplay.levelRepository.openDatabase():
		return {}

	var levelData: Dictionary = gameplay.levelRepository.getLevel(1, levelNumber)

	gameplay.levelRepository.closeDatabase()

	return levelData


# Updates the level timer.
func updateTimer(delta: float) -> void:
	if gameplay.levelFinished:
		return

	if gameplay.timeRemaining <= 0.0:
		return

	gameplay.timeRemaining -= delta

	if gameplay.timeRemaining <= 0.0:
		gameplay.timeRemaining = 0.0
		handleTimeExpired()

	gameplay.updateHud()


# Handles row selection from the table.
func onRowSelected(record: Dictionary, row: Button) -> void:
	gameplay.audioSystem.playFooterClickSound(gameplay.rowClickSound)

	if gameplay.levelFinished:
		return

	if gameplay.selectionSystem != null:
		gameplay.selectionSystem.toggleRowSelection(record, row)
		return

	if gameplay.selectedRow != null and gameplay.selectedRow.has_method("setSelected"):
		gameplay.selectedRow.setSelected(false)

	gameplay.selectedRecord = record
	gameplay.selectedRow = row

	if gameplay.selectedRow != null and gameplay.selectedRow.has_method("setSelected"):
		gameplay.selectedRow.setSelected(true)


# Handles check button press.
func onCheckPressed() -> void:
	if gameplay.levelFinished:
		return

	if gameplay.selectionSystem != null:
		if not gameplay.selectionSystem.hasSelection():
			gameplay.audioSystem.playFooterClickSound(gameplay.checkIncorrectSound)
			return

		if isSelectionCorrect():
			handleCorrectSelection()
		else:
			handleWrongRecord()

		return

	if gameplay.selectedRecord.is_empty():
		gameplay.audioSystem.playFooterClickSound(gameplay.checkIncorrectSound)
		return

	var selectedId := str(gameplay.selectedRecord.get("record_id", ""))

	if selectedId == gameplay.correctRecordId:
		handleCorrectSelection()
	else:
		handleWrongRecord()


# Checks if the selected record IDs match the correct answer IDs exactly.
func isSelectionCorrect() -> bool:
	var selectedIds: Array[String] = gameplay.selectionSystem.getSelectedRecordIds()
	var correctIds: Array[String] = getCorrectRecordIds()

	if selectedIds.size() != correctIds.size():
		return false

	selectedIds.sort()
	correctIds.sort()

	for index in range(correctIds.size()):
		if selectedIds[index] != correctIds[index]:
			return false

	return true


# Returns the correct record IDs from level data.
func getCorrectRecordIds() -> Array[String]:
	var correctIds: Array[String] = []

	if gameplay.currentLevel.has("correct_record_ids"):
		for id in gameplay.currentLevel.get("correct_record_ids", []):
			correctIds.append(str(id))

		return correctIds

	correctIds.append(str(gameplay.currentLevel.get("correct_record_id", "")))
	return correctIds


# Handles correct answer state.
func handleCorrectSelection() -> void:
	gameplay.levelFinished = true
	gameplay.audioSystem.playFooterClickSound(gameplay.checkCorrectSound)

	gameplay.updateHud()

	if gameplay.hudSystem != null and gameplay.hudSystem.has_method("updateStarDisplay"):
		gameplay.hudSystem.updateStarDisplay(true)

	if gameplay.selectionSystem != null:
		for row in gameplay.selectionSystem.selectedRows:
			if row != null and is_instance_valid(row) and row.has_method("playCorrectAnimation"):
				row.playCorrectAnimation()

	saveLevelProgress()

	if gameplay.has_method("openLevelCompletedPopup"):
		gameplay.openLevelCompletedPopup("The archive case has been resolved.")

# Saves stars and unlocks the next level.
func saveLevelProgress() -> void:
	var progressNode: Node = gameplay.get_node_or_null("/root/LevelProgress")

	if progressNode == null:
		push_error("LevelProgress autoload is missing. Add res://scripts/level_progress.gd as /root/LevelProgress.")
		return

	if not progressNode.has_method("completeLevel"):
		push_error("LevelProgress does not have completeLevel().")
		return

	var chapterId := 1

	if "currentChapterId" in gameplay:
		chapterId = int(gameplay.currentChapterId)

	var levelNumber := 1

	if "currentLevelNumber" in gameplay:
		levelNumber = int(gameplay.currentLevelNumber)

	var stars := int(gameplay.currentStars)

	progressNode.call("completeLevel", chapterId, levelNumber, stars)


# Handles wrong selected record.
func handleWrongRecord() -> void:
	gameplay.audioSystem.playFooterClickSound(gameplay.checkIncorrectSound)

	gameplay.hearts -= 1

	if gameplay.hearts <= 0:
		gameplay.hearts = 0
		handleNoHeartsLeft()
		return

	gameplay.updateHud()


# Handles no hearts left.
func handleNoHeartsLeft() -> void:
	gameplay.levelFinished = true
	gameplay.updateHud()

	if gameplay.hudSystem != null and gameplay.hudSystem.has_method("updateStarDisplay"):
		gameplay.hudSystem.updateStarDisplay(true)

	if gameplay.has_method("openGameOverPopup"):
		gameplay.openGameOverPopup("Lives have been depleted.")


# Handles time expiration.
func handleTimeExpired() -> void:
	gameplay.levelFinished = true
	gameplay.updateHud()

	if gameplay.hudSystem != null and gameplay.hudSystem.has_method("updateStarDisplay"):
		gameplay.hudSystem.updateStarDisplay(true)

	if gameplay.has_method("openGameOverPopup"):
		gameplay.openGameOverPopup("Time has expired.")


# Handles hint button press.
func onHintPressed() -> void:
	if gameplay.levelFinished:
		return

	var hints: Array = gameplay.currentLevel.get("hints", [])
	var hintLimit: int = mini(gameplay.MAX_HINT_COUNT, hints.size())

	if gameplay.hintIndex >= hintLimit:
		gameplay.updateActionButtonsState()

		if gameplay.has_method("openHintPopup"):
			gameplay.openHintPopup()

		return

	gameplay.audioSystem.playFooterClickSound(gameplay.hintClickSound)

	if gameplay.has_method("openHintPopup"):
		gameplay.openHintPopup()


# Handles info button press.
func onInfoPressed() -> void:
	gameplay.audioSystem.playFooterClickSound(gameplay.infoClickSound)

	if gameplay.has_method("openInfoPopup"):
		gameplay.openInfoPopup()


# Returns to main menu directly.
func returnToMainMenu() -> void:
	gameplay.get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
