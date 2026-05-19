DROP TABLE IF EXISTS level_hints;
DROP TABLE IF EXISTS level_answers;
DROP TABLE IF EXISTS level_records;
DROP TABLE IF EXISTS level_columns;
DROP TABLE IF EXISTS levels;
DROP TABLE IF EXISTS chapters;
DROP TABLE IF EXISTS person_pool;

CREATE TABLE IF NOT EXISTS chapters (
	chapter_id INTEGER PRIMARY KEY,
	chapter_title TEXT NOT NULL,
	chapter_description TEXT
);

CREATE TABLE IF NOT EXISTS levels (
	level_id INTEGER PRIMARY KEY AUTOINCREMENT,
	chapter_id INTEGER NOT NULL,
	level_number INTEGER NOT NULL,
	level_title TEXT NOT NULL,
	objective TEXT NOT NULL,
	story TEXT NOT NULL,
	selection_mode TEXT NOT NULL DEFAULT 'single',
	selection_limit INTEGER NOT NULL DEFAULT 1,
	hearts INTEGER NOT NULL DEFAULT 4,
	time_limit INTEGER NOT NULL DEFAULT 240,
	generation_mode TEXT NOT NULL DEFAULT 'fixed',
	case_type TEXT NOT NULL DEFAULT 'fixed',
	record_count INTEGER NOT NULL DEFAULT 50,
	target_role TEXT NOT NULL DEFAULT '',
	success_text TEXT NOT NULL DEFAULT '',
	failure_text TEXT NOT NULL DEFAULT '',
	difficulty_tier INTEGER NOT NULL DEFAULT 1,
	UNIQUE(chapter_id, level_number),
	FOREIGN KEY (chapter_id) REFERENCES chapters(chapter_id)
);

CREATE TABLE IF NOT EXISTS level_columns (
	column_id INTEGER PRIMARY KEY AUTOINCREMENT,
	level_id INTEGER NOT NULL,
	title TEXT NOT NULL,
	key TEXT NOT NULL,
	width_type TEXT NOT NULL DEFAULT 'normal',
	column_order INTEGER NOT NULL,
	FOREIGN KEY (level_id) REFERENCES levels(level_id)
);

CREATE TABLE IF NOT EXISTS level_records (
	record_pk INTEGER PRIMARY KEY AUTOINCREMENT,
	level_id INTEGER NOT NULL,
	record_id TEXT NOT NULL,
	data_json TEXT NOT NULL,
	UNIQUE(level_id, record_id),
	FOREIGN KEY (level_id) REFERENCES levels(level_id)
);

CREATE TABLE IF NOT EXISTS level_answers (
	answer_id INTEGER PRIMARY KEY AUTOINCREMENT,
	level_id INTEGER NOT NULL,
	record_id TEXT NOT NULL,
	FOREIGN KEY (level_id) REFERENCES levels(level_id)
);

CREATE TABLE IF NOT EXISTS level_hints (
	hint_id INTEGER PRIMARY KEY AUTOINCREMENT,
	level_id INTEGER NOT NULL,
	hint_order INTEGER NOT NULL,
	hint_text TEXT NOT NULL,
	FOREIGN KEY (level_id) REFERENCES levels(level_id)
);

CREATE TABLE IF NOT EXISTS person_pool (
	person_id INTEGER PRIMARY KEY AUTOINCREMENT,
	name TEXT NOT NULL,
	surname TEXT NOT NULL,
	culture TEXT NOT NULL,
	religion TEXT NOT NULL,
	sex TEXT NOT NULL,
	role TEXT NOT NULL
);