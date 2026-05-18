extends RefCounted

const DATABASE_PATH := "res://data/database/jerusalem_archives.db"
const LevelRecordGenerator = preload("res://scripts/database/level_record_generator.gd")

var db: Object = null


# Opens the SQLite database.
func openDatabase() -> bool:
	if not ClassDB.class_exists("SQLite"):
		push_error("SQLite class is not registered.")
		return false

	db = ClassDB.instantiate("SQLite")

	if db == null:
		push_error("Failed to instantiate SQLite.")
		return false

	db.path = DATABASE_PATH
	db.foreign_keys = true
	db.read_only = true
	db.verbosity_level = 1

	if not db.open_db():
		push_error("Failed to open database: %s" % db.error_message)
		return false

	return true


# Closes the SQLite database.
func closeDatabase() -> void:
	if db == null:
		return

	db.close_db()
	db = null


# Returns one complete level as a gameplay-ready Dictionary.
func getLevel(chapterId: int, levelNumber: int) -> Dictionary:
	if db == null:
		push_error("Database is not open.")
		return {}

	var levelData: Dictionary = getLevelBaseData(chapterId, levelNumber)

	if levelData.is_empty():
		return {}

	var levelId: int = int(levelData.get("level_id", 0))
	levelData["columns"] = getLevelColumns(levelId)

	if str(levelData.get("generation_mode", "fixed")) == "generated":
		levelData = generateLevel(levelData)
	else:
		levelData["records"] = getFixedLevelRecords(levelId)
		levelData["correct_record_ids"] = getFixedLevelAnswers(levelId)
		levelData["hints"] = getFixedLevelHints(levelId)

	var correctIds: Array = levelData.get("correct_record_ids", [])
	levelData["correct_record_id"] = str(correctIds[0]) if not correctIds.is_empty() else ""

	return levelData


# Loads the main level row.
func getLevelBaseData(chapterId: int, levelNumber: int) -> Dictionary:
	var success: bool = db.query_with_bindings(
		"SELECT levels.level_id, levels.chapter_id, chapters.chapter_title, levels.level_number, levels.level_title, levels.objective, levels.story, levels.selection_mode, levels.selection_limit, levels.hearts, levels.time_limit, levels.generation_mode, levels.case_type, levels.record_count, levels.target_role FROM levels INNER JOIN chapters ON chapters.chapter_id = levels.chapter_id WHERE levels.chapter_id = ? AND levels.level_number = ? LIMIT 1;",
		[chapterId, levelNumber]
	)

	if not success:
		push_error("Level query failed: %s" % db.error_message)
		return {}

	if db.query_result.is_empty():
		push_error("No level found for chapter %s level %s." % [chapterId, levelNumber])
		return {}

	var row: Dictionary = db.query_result[0]

	return {
		"level_id": int(row.get("level_id", 0)),
		"chapter_id": int(row.get("chapter_id", 0)),
		"chapter_title": str(row.get("chapter_title", "")),
		"level_number": int(row.get("level_number", 0)),
		"level_title": str(row.get("level_title", "")),
		"objective": str(row.get("objective", "")),
		"story": str(row.get("story", "")),
		"selection_mode": str(row.get("selection_mode", "single")),
		"selection_limit": int(row.get("selection_limit", 1)),
		"hearts": int(row.get("hearts", 4)),
		"time_limit": int(row.get("time_limit", 240)),
		"generation_mode": str(row.get("generation_mode", "fixed")),
		"case_type": str(row.get("case_type", "fixed")),
		"record_count": int(row.get("record_count", 50)),
		"target_role": str(row.get("target_role", ""))
	}


# Generates a level from database pools.
func generateLevel(levelData: Dictionary) -> Dictionary:
	var generator = LevelRecordGenerator.new(db)
	var caseType: String = str(levelData.get("case_type", ""))

	if caseType == "missing_merchant":
		return generator.generateMissingMerchantLevel(levelData)

	push_error("Unsupported generated case type: %s" % caseType)
	return levelData


# Loads dynamic table columns for the level.
func getLevelColumns(levelId: int) -> Array:
	var success: bool = db.query_with_bindings(
		"SELECT title, key, width_type FROM level_columns WHERE level_id = ? ORDER BY column_order ASC;",
		[levelId]
	)

	if not success:
		push_error("Column query failed: %s" % db.error_message)
		return []

	var columns: Array = []

	for row in db.query_result:
		columns.append({
			"title": str(row.get("title", "")),
			"key": str(row.get("key", "")),
			"type": str(row.get("width_type", "normal"))
		})

	return columns


# Loads fixed table records for fixed/manual levels.
func getFixedLevelRecords(levelId: int) -> Array:
	var success: bool = db.query_with_bindings(
		"SELECT data_json FROM level_records WHERE level_id = ? ORDER BY record_id ASC;",
		[levelId]
	)

	if not success:
		push_error("Record query failed: %s" % db.error_message)
		return []

	var records: Array = []

	for row in db.query_result:
		var dataJson: String = str(row.get("data_json", ""))
		var parsedData = JSON.parse_string(dataJson)

		if parsedData == null:
			push_error("Invalid record JSON: %s" % dataJson)
			continue

		if parsedData is Dictionary:
			records.append(parsedData)

	return records


# Loads correct answer IDs for fixed/manual levels.
func getFixedLevelAnswers(levelId: int) -> Array[String]:
	var success: bool = db.query_with_bindings(
		"SELECT record_id FROM level_answers WHERE level_id = ? ORDER BY answer_id ASC;",
		[levelId]
	)

	if not success:
		push_error("Answer query failed: %s" % db.error_message)
		return []

	var answers: Array[String] = []

	for row in db.query_result:
		answers.append(str(row.get("record_id", "")))

	return answers


# Loads ordered hints for fixed/manual levels.
func getFixedLevelHints(levelId: int) -> Array:
	var success: bool = db.query_with_bindings(
		"SELECT hint_text FROM level_hints WHERE level_id = ? ORDER BY hint_order ASC;",
		[levelId]
	)

	if not success:
		push_error("Hint query failed: %s" % db.error_message)
		return []

	var hints: Array = []

	for row in db.query_result:
		hints.append(str(row.get("hint_text", "")))

	return hints