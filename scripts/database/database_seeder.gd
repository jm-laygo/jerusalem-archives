extends Node

const DATABASE_PATH := "res://data/database/jerusalem_archives.db"
const SCHEMA_PATH := "res://data/database/schema.sql"
const SEED_PATH := "res://data/database/seed_level_001.sql"

const LevelRecordGenerator = preload("res://scripts/database/level_record_generator.gd")

var db: Object


# Opens SQLite, recreates the schema, seeds the data, and prints a generated level summary.
func _ready() -> void:
	print("Starting database seeder...")

	if not openDatabase():
		return

	if not executeSqlFile(SCHEMA_PATH):
		closeDatabase()
		return

	if not executeSqlFile(SEED_PATH):
		closeDatabase()
		return

	printSeededLevelSummary(1, 1)

	closeDatabase()
	print("Database seeding finished.")


# Opens the SQLite database connection.
func openDatabase() -> bool:
	if not ClassDB.class_exists("SQLite"):
		push_error("SQLite class is not registered. Check the addon installation.")
		return false

	db = ClassDB.instantiate("SQLite")

	if db == null:
		push_error("SQLite exists, but failed to instantiate.")
		return false

	db.path = DATABASE_PATH
	db.foreign_keys = true
	db.verbosity_level = 1

	if not db.open_db():
		push_error("Failed to open database: %s" % db.error_message)
		return false

	print("Database opened: %s" % DATABASE_PATH)
	return true


# Closes the SQLite database connection.
func closeDatabase() -> void:
	if db == null:
		return

	db.close_db()
	db = null


# Reads and executes a SQL file statement by statement.
func executeSqlFile(filePath: String) -> bool:
	if not FileAccess.file_exists(filePath):
		push_error("SQL file not found: %s" % filePath)
		return false

	var file := FileAccess.open(filePath, FileAccess.READ)

	if file == null:
		push_error("Cannot open SQL file: %s" % filePath)
		return false

	var sqlText := file.get_as_text()
	file.close()

	if sqlText.strip_edges().is_empty():
		push_error("SQL file is empty: %s" % filePath)
		return false

	var statements := sqlText.split(";", false)

	for rawStatement in statements:
		var statement := str(rawStatement).strip_edges()

		if statement.is_empty():
			continue

		var success: bool = db.query(statement + ";")

		if not success:
			push_error("SQL failed:\n%s\nError: %s" % [statement, db.error_message])
			return false

	print("Executed SQL file: %s" % filePath)
	return true


# Prints a playable level summary after seeding.
func printSeededLevelSummary(chapterId: int, levelNumber: int) -> void:
	var levelData: Dictionary = getLevelBaseData(chapterId, levelNumber)

	if levelData.is_empty():
		push_error("No seeded level data found.")
		return

	var levelId: int = int(levelData.get("level_id", 0))

	levelData["columns"] = getLevelColumns(levelId)

	var generationMode: String = str(levelData.get("generation_mode", "fixed"))

	if generationMode == "generated":
		levelData = generateLevel(levelData)
	else:
		levelData["records"] = getFixedLevelRecords(levelId)
		levelData["correct_record_ids"] = getFixedLevelAnswers(levelId)
		levelData["hints"] = getFixedLevelHints(levelId)

		var correctIds: Array = levelData.get("correct_record_ids", [])
		levelData["correct_record_id"] = str(correctIds[0]) if not correctIds.is_empty() else ""

	print("")
	print("Seeded Gameplay Level Summary:")
	print("Chapter: %s" % levelData.get("chapter_title", ""))
	print("Level: %s - %s" % [
		levelData.get("level_number", ""),
		levelData.get("level_title", "")
	])
	print("Objective: %s" % levelData.get("objective", ""))
	print("Story: %s" % levelData.get("story", ""))
	print("Generation Mode: %s" % levelData.get("generation_mode", ""))
	print("Columns found: %s" % levelData.get("columns", []).size())
	print("Records generated/found: %s" % levelData.get("records", []).size())
	print("Correct Record ID: %s" % levelData.get("correct_record_id", ""))
	print("Hints found: %s" % levelData.get("hints", []).size())

	print("")
	print("Sample Records:")

	var records: Array = levelData.get("records", [])

	for index in range(min(records.size(), 10)):
		print(records[index])


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


# Generates a playable level from database pools.
func generateLevel(levelData: Dictionary) -> Dictionary:
	var generator = LevelRecordGenerator.new(db)
	var caseType: String = str(levelData.get("case_type", ""))

	if caseType == "missing_merchant":
		return generator.generateMissingMerchantLevel(levelData)

	push_error("Unsupported generated case type: %s" % caseType)
	return levelData


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