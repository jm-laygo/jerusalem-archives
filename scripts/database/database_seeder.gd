extends Node

const DATABASE_PATH := "res://data/database/jerusalem_archives.db"
const SCHEMA_PATH := "res://data/database/schema.sql"
const SEED_PATH := "res://data/database/seed_chapter_001.sql"

var db: Object


func _ready() -> void:
	print("Starting database setup...")

	if not ClassDB.class_exists("SQLite"):
		push_error("SQLite class is not registered. Check godot-sqlite addon.")
		return

	db = ClassDB.instantiate("SQLite")

	if db == null:
		push_error("SQLite exists, but failed to instantiate.")
		return

	db.path = DATABASE_PATH
	db.foreign_keys = true
	db.verbosity_level = 1

	if not db.open_db():
		push_error("Failed to open database: %s" % db.error_message)
		return

	print("Opened database: %s" % DATABASE_PATH)

	if not runSqlFile(SCHEMA_PATH):
		closeDatabase()
		return

	if not runSqlFile(SEED_PATH):
		closeDatabase()
		return

	testChapterQuery()
	closeDatabase()

	print("Database setup finished.")


func runSqlFile(filePath: String) -> bool:
	if not FileAccess.file_exists(filePath):
		push_error("SQL file not found: %s" % filePath)
		return false

	var file := FileAccess.open(filePath, FileAccess.READ)

	if file == null:
		push_error("Cannot open SQL file: %s" % filePath)
		return false

	var sqlText := file.get_as_text()
	file.close()

	var statements := sqlText.split(";", false)
	var statementIndex := 0

	print("Running SQL file: %s" % filePath)
	print("Statement count: %s" % statements.size())

	for rawStatement in statements:
		var statement := str(rawStatement).strip_edges()

		if statement.is_empty():
			continue

		statementIndex += 1

		var success: bool = db.query(statement + ";")

		if not success:
			push_error(
				"SQL failed at statement %s in %s:\n%s\nError: %s" % [
					statementIndex,
					filePath,
					statement,
					db.error_message
				]
			)
			return false

	print("Executed SQL file: %s" % filePath)
	return true


func testChapterQuery() -> void:
	var success: bool = db.query("
		SELECT
			levels.level_id,
			levels.level_number,
			levels.level_title,
			levels.case_type,
			levels.selection_mode,
			levels.selection_limit,
			COUNT(level_columns.column_id) AS column_count
		FROM levels
		LEFT JOIN level_columns ON level_columns.level_id = levels.level_id
		WHERE levels.chapter_id = 1
		GROUP BY levels.level_id
		ORDER BY levels.level_number ASC;
	")

	if not success:
		push_error("Chapter query failed: %s" % db.error_message)
		return

	print("Chapter 1 Levels Found: %s" % db.query_result.size())

	for row in db.query_result:
		print(
			"Level %s: %s | %s | %s/%s | columns=%s" % [
				row.get("level_number", ""),
				row.get("level_title", ""),
				row.get("case_type", ""),
				row.get("selection_mode", ""),
				row.get("selection_limit", ""),
				row.get("column_count", "")
			]
		)


func closeDatabase() -> void:
	if db == null:
		return

	db.close_db()
	db = null
	print("Closed database.")
