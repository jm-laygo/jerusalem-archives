extends RefCounted

const OBJECTIVE_FONT_SIZE := 40
const OBJECTIVE_MESSAGE_FONT_SIZE := 48
const OBJECTIVE_WARNING_FONT_SIZE := 50

const DEFAULT_TIME_LIMIT := 240.0
const DEFAULT_HEARTS := 4
const DEFAULT_OBJECTIVE := "Objective"
const DEFAULT_STORY := "No story available."

var gameplay: Control


# Stores the gameplay screen reference used by this rules system.
func _init(gameplayOwner: Control) -> void:
	gameplay = gameplayOwner


# Loads level data and resets gameplay state.
func loadLevel(levelNumber: int) -> void:
	gameplay.currentLevel = loadLevelFromDatabase(levelNumber)

	if gameplay.currentLevel.is_empty():
		push_error("Level data not found: %s" % levelNumber)
		return

	gameplay.currentColumns = gameplay.currentLevel.get("columns", [])
	gameplay.currentRecords = gameplay.currentLevel.get("records", [])
	gameplay.originalRecords = gameplay.currentRecords.duplicate(true)

	gameplay.activeSortColumnKey = ""
	gameplay.correctRecordId = str(gameplay.currentLevel.get("correct_record_id", ""))

	gameplay.hearts = int(gameplay.currentLevel.get("hearts", DEFAULT_HEARTS))
	gameplay.maxHearts = gameplay.hearts

	gameplay.hintIndex = 0
	gameplay.hintsUsed = 0
	gameplay.currentStars = 3

	gameplay.levelTimeLimit = float(gameplay.currentLevel.get("time_limit", DEFAULT_TIME_LIMIT))
	gameplay.timeRemaining = gameplay.levelTimeLimit

	gameplay.levelFinished = false

	gameplay.selectedRecord = {}
	gameplay.selectedRow = null

	if gameplay.selectionSystem != null:
		gameplay.selectionSystem.configureFromLevel(gameplay.currentLevel)
		gameplay.selectionSystem.resetSelection()

	gameplay.scrollX = 0.0
	gameplay.scrollY = 0.0
	gameplay.dragAxis = ""

	if gameplay.levelText != null:
		gameplay.levelText.text = "Level %s" % str(gameplay.currentLevel.get("level_number", levelNumber))

	gameplay.setObjectiveText(str(gameplay.currentLevel.get("objective", DEFAULT_OBJECTIVE)), OBJECTIVE_FONT_SIZE)

	gameplay.hudSystem.previousHearts = -1
	gameplay.hudSystem.previousStars = -1
	gameplay.hudSystem.updateHud()

	gameplay.tableSystem.buildTable()


# Updates the level timer while the level is active.
func updateTimer(delta: float) -> void:
	if gameplay.levelFinished:
		return

	if gameplay.timeRemaining <= 0.0:
		return

	gameplay.timeRemaining -= delta

	if gameplay.timeRemaining <= 0.0:
		handleTimerExpired()
		return

	gameplay.hudSystem.updateTimerDisplay()


# Handles the fail state when the timer reaches zero.
func handleTimerExpired() -> void:
	gameplay.timeRemaining = 0.0
	gameplay.levelFinished = true
	gameplay.hearts = 0

	gameplay.hudSystem.updateHud()
	gameplay.setObjectiveText("Time is up. Case failed.", OBJECTIVE_MESSAGE_FONT_SIZE)


# Handles row selection from the table.
func onRowSelected(record: Dictionary, row: Button) -> void:
	gameplay.audioSystem.playFooterClickSound(gameplay.rowClickSound)

	if gameplay.selectionSystem != null:
		gameplay.selectionSystem.toggleRowSelection(record, row)
		return

	if gameplay.selectedRow != null and gameplay.selectedRow.has_method("setSelected"):
		gameplay.selectedRow.setSelected(false)

	gameplay.selectedRecord = record
	gameplay.selectedRow = row

	if gameplay.selectedRow != null and gameplay.selectedRow.has_method("setSelected"):
		gameplay.selectedRow.setSelected(true)


# Checks whether the selected record is correct.
func onCheckPressed() -> void:
	if gameplay.levelFinished:
		return

	if gameplay.selectionSystem != null:
		if not gameplay.selectionSystem.hasSelection():
			gameplay.setObjectiveText("Select a record first.", OBJECTIVE_WARNING_FONT_SIZE)
			return

		if isSelectionCorrect():
			handleCorrectSelection()
		else:
			handleWrongRecord()

		return

	if gameplay.selectedRecord.is_empty():
		gameplay.setObjectiveText("Select a record first.", OBJECTIVE_WARNING_FONT_SIZE)
		return

	var selectedId := str(gameplay.selectedRecord.get("record_id", ""))

	if selectedId == gameplay.correctRecordId:
		handleCorrectRecord(selectedId)
	else:
		handleWrongRecord()

# Checks if the selected record IDs match the correct answer IDs.
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


# Handles correct answer state for single or multiple selected records.
func handleCorrectSelection() -> void:
	gameplay.levelFinished = true
	gameplay.audioSystem.playFooterClickSound(gameplay.checkCorrectSound)

	gameplay.hudSystem.updateHud()
	gameplay.hudSystem.updateStarDisplay(true)

	for row in gameplay.selectionSystem.selectedRows:
		if row != null and is_instance_valid(row) and row.has_method("playCorrectAnimation"):
			row.playCorrectAnimation()

	var selectedIds: Array[String] = gameplay.selectionSystem.getSelectedRecordIds()

	gameplay.setObjectiveText(
		"Case Solved! Correct record: %s" % ", ".join(selectedIds),
		OBJECTIVE_WARNING_FONT_SIZE
	)


# Handles correct answer state.
func handleCorrectRecord(selectedId: String) -> void:
	gameplay.levelFinished = true
	gameplay.audioSystem.playFooterClickSound(gameplay.checkCorrectSound)

	gameplay.hudSystem.updateHud()
	gameplay.hudSystem.updateStarDisplay(true)

	if gameplay.selectedRow != null and gameplay.selectedRow.has_method("playCorrectAnimation"):
		gameplay.selectedRow.playCorrectAnimation()

	gameplay.setObjectiveText(
		"Case Solved! Correct record: %s" % selectedId,
		OBJECTIVE_WARNING_FONT_SIZE
	)


# Handles wrong answer state.
func handleWrongRecord() -> void:
	gameplay.audioSystem.playFooterClickSound(gameplay.checkIncorrectSound)

	if gameplay.selectedRow != null and gameplay.selectedRow.has_method("playWrongAnimation"):
		gameplay.selectedRow.playWrongAnimation()

	gameplay.hearts -= 1
	gameplay.hearts = max(gameplay.hearts, 0)

	gameplay.hudSystem.updateHud()
	gameplay.hudSystem.updateStarDisplay(true)

	if gameplay.hearts <= 0:
		gameplay.levelFinished = true
		gameplay.setObjectiveText("Case Failed. Try again.", OBJECTIVE_MESSAGE_FONT_SIZE)
	else:
		gameplay.setObjectiveText("Wrong record. Check the archive clues again.", OBJECTIVE_MESSAGE_FONT_SIZE)


# Shows the next available hint.
func onHintPressed() -> void:
	if gameplay.levelFinished:
		return

	var hints: Array = gameplay.currentLevel.get("hints", [])

	if hints.is_empty():
		gameplay.setObjectiveText("No hints available.", OBJECTIVE_MESSAGE_FONT_SIZE)
		return

	if gameplay.hintIndex >= hints.size():
		gameplay.setObjectiveText("No more hints available.", OBJECTIVE_MESSAGE_FONT_SIZE)
		return

	gameplay.setObjectiveText(str(hints[gameplay.hintIndex]), OBJECTIVE_FONT_SIZE)

	gameplay.hintIndex += 1
	gameplay.hintsUsed += 1

	gameplay.hudSystem.updateStarDisplay(true)

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


# Shows the level story/objective info.
func onInfoPressed() -> void:
	gameplay.setObjectiveText(str(gameplay.currentLevel.get("story", DEFAULT_STORY)), OBJECTIVE_FONT_SIZE)
