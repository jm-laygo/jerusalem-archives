extends RefCounted

const DATABASE_PATH := "res://data/database/jerusalem_archives.db"
const LevelRecordGenerator = preload("res://scripts/database/level_record_generator.gd")

var db: Object = null


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


func closeDatabase() -> void:
	if db == null:
		return

	db.close_db()
	db = null


func getLevel(chapterId: int, levelNumber: int) -> Dictionary:
	if db == null:
		push_error("Database is not open.")
		return {}

	var levelData: Dictionary = getLevelBaseData(chapterId, levelNumber)

	if levelData.is_empty():
		return {}

	var levelId: int = int(levelData.get("level_id", 0))

	levelData["columns"] = getLevelColumns(levelId)
	levelData["hints"] = getLevelHints(levelId)

	if str(levelData.get("generation_mode", "fixed")) == "generated":
		levelData = generateLevel(levelData)
	else:
		levelData["records"] = getLevelRecords(levelId)
		levelData["correct_record_ids"] = getLevelAnswers(levelId)

	var correctIds: Array = levelData.get("correct_record_ids", [])

	if not correctIds.is_empty():
		levelData["correct_record_id"] = str(correctIds[0])
	else:
		levelData["correct_record_id"] = ""

	return levelData


func getLevelBaseData(chapterId: int, levelNumber: int) -> Dictionary:
	var success: bool = db.query_with_bindings(
		"
		SELECT
			levels.level_id,
			levels.chapter_id,
			chapters.chapter_title,
			levels.level_number,
			levels.level_title,
			levels.objective,
			levels.story,
			levels.selection_mode,
			levels.selection_limit,
			levels.hearts,
			levels.time_limit,
			levels.generation_mode,
			levels.case_type,
			levels.record_count,
			levels.target_role,
			levels.success_text,
			levels.failure_text,
			levels.difficulty_tier
		FROM levels
		INNER JOIN chapters ON chapters.chapter_id = levels.chapter_id
		WHERE levels.chapter_id = ? AND levels.level_number = ?
		LIMIT 1;
		",
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
		"target_role": str(row.get("target_role", "")),
		"success_text": str(row.get("success_text", "")),
		"failure_text": str(row.get("failure_text", "")),
		"difficulty_tier": int(row.get("difficulty_tier", 1))
	}


func generateLevel(levelData: Dictionary) -> Dictionary:
	var generator = LevelRecordGenerator.new(db)
	return generator.generateLevel(levelData)


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


func getLevelRecords(levelId: int) -> Array:
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

		if parsedData is Dictionary:
			records.append(parsedData)

	return records


func getLevelAnswers(levelId: int) -> Array[String]:
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


func getLevelHints(levelId: int) -> Array:
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