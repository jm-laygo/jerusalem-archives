DELETE FROM level_hints;
DELETE FROM level_answers;
DELETE FROM level_records;
DELETE FROM level_columns;
DELETE FROM levels;
DELETE FROM chapters;
DELETE FROM person_pool;

INSERT INTO chapters (
	chapter_id,
	chapter_title,
	chapter_description
)
VALUES (
	1,
	'Port of Jaffa',
	'The archivist-inquisitor arrives at the harbor archive before the road to Jerusalem opens.'
);

INSERT INTO levels (
	level_id,
	chapter_id,
	level_number,
	level_title,
	objective,
	story,
	selection_mode,
	selection_limit,
	hearts,
	time_limit,
	generation_mode,
	case_type,
	record_count,
	target_role
)
VALUES (
	1,
	1,
	1,
	'Missing Merchant',
	'Find the missing merchant whose record matches the witness report.',
	'A merchant was recorded at the harbor gate, but the name vanished before the final departure roll was sealed. Use the witness report and archive fields to identify the missing entry.',
	'single',
	1,
	4,
	240,
	'generated',
	'missing_merchant',
	50,
	'Merchant'
);

INSERT INTO level_columns (level_id, title, key, width_type, column_order) VALUES
(1, 'Record ID', 'record_id', 'normal', 1),
(1, 'Name', 'name', 'normal', 2),
(1, 'Surname', 'surname', 'long', 3),
(1, 'Culture', 'culture', 'normal', 4),
(1, 'Religion', 'religion', 'superlong', 5);

INSERT INTO level_hints (level_id, hint_order, hint_text) VALUES
(1, 1, 'Begin with the culture and religion fields.'),
(1, 2, 'The witness report describes the missing merchant by origin and faith.'),
(1, 3, 'Compare the name form carefully. Some surnames reveal family or place origin.'),
(1, 4, 'The correct record matches every detail in the updated case report.');

INSERT INTO person_pool (name, surname, culture, religion, sex, role) VALUES
('Yusuf', 'al-Din', 'Arabic', 'Muslim', 'Male', 'Merchant'),
('Miriam', 'bat Yosef', 'Hebrew', 'Jewish', 'Female', 'Merchant'),
('Alexios', 'Komnenos', 'Byzantine', 'Orthodox', 'Male', 'Merchant'),
('Aram', 'of Cilicia', 'Armenian', 'Armenian Apostolic', 'Male', 'Merchant'),
('Guillaume', 'de Lusignan', 'Frankish', 'Catholic', 'Male', 'Merchant'),
('Farid', 'ibn Khalid', 'Egyptian', 'Muslim', 'Male', 'Merchant'),
('Marco', 'Contarini', 'Venetian', 'Catholic', 'Male', 'Merchant'),
('Elias', 'ben Natan', 'Hebrew', 'Jewish', 'Male', 'Merchant'),
('Hassan', 'al-Haddad', 'Arabic', 'Muslim', 'Male', 'Merchant'),
('Stephanos', 'Doukas', 'Greek', 'Orthodox', 'Male', 'Merchant'),

('Tigran', 'Vardanyan', 'Armenian', 'Armenian Apostolic', 'Male', 'Merchant'),
('Raymond', 'de Toulouse', 'Occitan', 'Catholic', 'Male', 'Merchant'),
('Selim', 'ibn Orhan', 'Turkic', 'Muslim', 'Male', 'Merchant'),
('Bahram', 'Farrokh', 'Persian', 'Muslim', 'Male', 'Merchant'),
('Dawud', 'ben Ezra', 'Hebrew', 'Jewish', 'Male', 'Merchant'),
('Niketas', 'Palaiologos', 'Byzantine', 'Orthodox', 'Male', 'Merchant'),
('Ibrahim', 'al-Masri', 'Egyptian', 'Muslim', 'Male', 'Merchant'),
('Pietro', 'Ziani', 'Venetian', 'Catholic', 'Male', 'Merchant'),
('Nerses', 'Karekin', 'Armenian', 'Armenian Apostolic', 'Male', 'Merchant'),
('Amalric', 'de Jaffa', 'Frankish', 'Catholic', 'Male', 'Merchant'),

('Khalil', 'al-Suri', 'Syrian', 'Muslim', 'Male', 'Merchant'),
('Isaac', 'ben Shimon', 'Hebrew', 'Jewish', 'Male', 'Merchant'),
('Manuel', 'Chrysoberges', 'Byzantine', 'Orthodox', 'Male', 'Merchant'),
('Yusuf', 'al-Yamani', 'Yemeni', 'Muslim', 'Male', 'Merchant'),
('Leon', 'Argyros', 'Greek', 'Orthodox', 'Male', 'Merchant'),
('Gerard', 'de Ridefort', 'Frankish', 'Catholic', 'Male', 'Merchant'),
('Salih', 'ibn Rashid', 'Arabic', 'Muslim', 'Male', 'Merchant'),
('Avraham', 'ben Levi', 'Hebrew', 'Jewish', 'Male', 'Merchant'),
('Vartan', 'Sarkisian', 'Armenian', 'Armenian Apostolic', 'Male', 'Merchant'),
('Giovanni', 'Dandolo', 'Venetian', 'Catholic', 'Male', 'Merchant'),

('Theodoros', 'Gabras', 'Byzantine', 'Orthodox', 'Male', 'Merchant'),
('Musa', 'al-Iskandari', 'Egyptian', 'Muslim', 'Male', 'Merchant'),
('Pierre', 'de Montpellier', 'Occitan', 'Catholic', 'Male', 'Merchant'),
('Nasir', 'al-Dimashqi', 'Syrian', 'Muslim', 'Male', 'Merchant'),
('Yakov', 'ben Meir', 'Hebrew', 'Jewish', 'Male', 'Merchant'),
('Andronikos', 'Angelos', 'Byzantine', 'Orthodox', 'Male', 'Merchant'),
('Rostam', 'Bahmani', 'Persian', 'Muslim', 'Male', 'Merchant'),
('Enrico', 'Morosini', 'Venetian', 'Catholic', 'Male', 'Merchant'),
('Bedros', 'Hovhannisian', 'Armenian', 'Armenian Apostolic', 'Male', 'Merchant'),
('Henri', 'de Antioch', 'Frankish', 'Catholic', 'Male', 'Merchant'),

('Omar', 'ibn Said', 'Arabic', 'Muslim', 'Male', 'Merchant'),
('Raphael', 'ben Daniel', 'Hebrew', 'Jewish', 'Male', 'Merchant'),
('Ioannes', 'Kantakouzenos', 'Byzantine', 'Orthodox', 'Male', 'Merchant'),
('Qasim', 'al-Yafi', 'Yemeni', 'Muslim', 'Male', 'Merchant'),
('Demetrios', 'Lascaris', 'Greek', 'Orthodox', 'Male', 'Merchant'),
('Balian', 'd''Ibelin', 'Frankish', 'Catholic', 'Male', 'Merchant'),
('Karim', 'al-Baghdadi', 'Persian', 'Muslim', 'Male', 'Merchant'),
('Samir', 'al-Halabi', 'Syrian', 'Muslim', 'Male', 'Merchant'),
('Yehuda', 'ben Aaron', 'Hebrew', 'Jewish', 'Male', 'Merchant'),
('Luca', 'Gradenigo', 'Venetian', 'Catholic', 'Male', 'Merchant'),

('Rivka', 'bat Natan', 'Hebrew', 'Jewish', 'Female', 'Merchant'),
('Leah', 'bat Ezra', 'Hebrew', 'Jewish', 'Female', 'Merchant'),
('Anna', 'Komnene', 'Byzantine', 'Orthodox', 'Female', 'Merchant'),
('Sofia', 'Doukaina', 'Greek', 'Orthodox', 'Female', 'Merchant'),
('Mariam', 'al-Halabiyya', 'Syrian', 'Muslim', 'Female', 'Merchant'),
('Amina', 'al-Masriya', 'Egyptian', 'Muslim', 'Female', 'Merchant'),
('Lucia', 'Contarini', 'Venetian', 'Catholic', 'Female', 'Merchant'),
('Isabella', 'de Jaffa', 'Frankish', 'Catholic', 'Female', 'Merchant'),
('Anahid', 'Sarkisian', 'Armenian', 'Armenian Apostolic', 'Female', 'Merchant'),
('Shirin', 'Farrokhzad', 'Persian', 'Muslim', 'Female', 'Merchant');