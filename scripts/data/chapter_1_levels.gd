extends RefCounted
class_name Chapter1Levels


static func get_level(level_number: int) -> Dictionary:
	for level in get_levels():
		if level.get("level_number", 0) == level_number:
			return level

	return {}


static func get_levels() -> Array:
	return [
		get_level_1_missing_merchant()
	]


static func get_level_1_missing_merchant() -> Dictionary:
	return {
		"chapter_id": 1,
		"chapter_title": "Port of Jaffa",
		"level_number": 1,
		"level_title": "Missing Merchant",

		"objective": "A merchant was reported missing from the Port of Jaffa ledger. Search the archive records and identify the correct entry before the case is sealed.",

		"story": "A merchant was reported missing from the Port of Jaffa ledger. Search the archive records and identify the correct entry before the case is sealed.",

		"columns": [
			{
				"title": "Record ID",
				"key": "record_id",
				"type": "normal"
			},
			{
				"title": "Name",
				"key": "name",
				"type": "normal"
			},
			{
				"title": "Surname",
				"key": "surname",
				"type": "long"
			},
			{
				"title": "Culture",	
				"key": "culture",
				"type": "normal"
			},
			{
				"title": "Religion",
				"key": "religion",
				"type": "superlong"
			}
		],

		"records": [
			{ "record_id": "R001", "name": "Yusuf", "surname": "al-Din", "culture": "Arabic", "religion": "Muslim" },
			{ "record_id": "R002", "name": "Miriam", "surname": "bat Yosef", "culture": "Hebrew", "religion": "Jewish" },
			{ "record_id": "R003", "name": "Alexios", "surname": "Komnenos", "culture": "Byzantine", "religion": "Orthodox" },
			{ "record_id": "R004", "name": "Aram", "surname": "of Cilicia", "culture": "Armenian", "religion": "Armenian Apostolic" },
			{ "record_id": "R005", "name": "Guillaume", "surname": "de Lusignan", "culture": "Frankish", "religion": "Catholic" },
			{ "record_id": "R006", "name": "Farid", "surname": "ibn Khalid", "culture": "Egyptian", "religion": "Muslim" },
			{ "record_id": "R007", "name": "Marco", "surname": "Contarini", "culture": "Venetian", "religion": "Catholic" },
			{ "record_id": "R008", "name": "Elias", "surname": "ben Natan", "culture": "Hebrew", "religion": "Jewish" },
			{ "record_id": "R009", "name": "Hassan", "surname": "al-Haddad", "culture": "Arabic", "religion": "Muslim" },
			{ "record_id": "R010", "name": "Stephanos", "surname": "Doukas", "culture": "Greek", "religion": "Orthodox" },

			{ "record_id": "R011", "name": "Tigran", "surname": "Vardanyan", "culture": "Armenian", "religion": "Armenian Apostolic" },
			{ "record_id": "R012", "name": "Raymond", "surname": "de Toulouse", "culture": "Occitan", "religion": "Catholic" },
			{ "record_id": "R013", "name": "Selim", "surname": "ibn Orhan", "culture": "Turkic", "religion": "Muslim" },
			{ "record_id": "R014", "name": "Bahram", "surname": "Farrokh", "culture": "Persian", "religion": "Muslim" },
			{ "record_id": "R015", "name": "Dawud", "surname": "ben Ezra", "culture": "Hebrew", "religion": "Jewish" },
			{ "record_id": "R016", "name": "Niketas", "surname": "Palaiologos", "culture": "Byzantine", "religion": "Orthodox" },
			{ "record_id": "R017", "name": "Ibrahim", "surname": "al-Masri", "culture": "Egyptian", "religion": "Muslim" },
			{ "record_id": "R018", "name": "Pietro", "surname": "Ziani", "culture": "Venetian", "religion": "Catholic" },
			{ "record_id": "R019", "name": "Nerses", "surname": "Karekin", "culture": "Armenian", "religion": "Armenian Apostolic" },
			{ "record_id": "R020", "name": "Amalric", "surname": "de Jaffa", "culture": "Frankish", "religion": "Catholic" },

			{ "record_id": "R021", "name": "Khalil", "surname": "al-Suri", "culture": "Syrian", "religion": "Muslim" },
			{ "record_id": "R022", "name": "Isaac", "surname": "ben Shimon", "culture": "Hebrew", "religion": "Jewish" },
			{ "record_id": "R023", "name": "Manuel", "surname": "Chrysoberges", "culture": "Byzantine", "religion": "Orthodox" },
			{ "record_id": "R024", "name": "Yusuf", "surname": "al-Yamani", "culture": "Yemeni", "religion": "Muslim" },
			{ "record_id": "R025", "name": "Leon", "surname": "Argyros", "culture": "Greek", "religion": "Orthodox" },
			{ "record_id": "R026", "name": "Gerard", "surname": "de Ridefort", "culture": "Frankish", "religion": "Catholic" },
			{ "record_id": "R027", "name": "Salih", "surname": "ibn Rashid", "culture": "Arabic", "religion": "Muslim" },
			{ "record_id": "R028", "name": "Avraham", "surname": "ben Levi", "culture": "Hebrew", "religion": "Jewish" },
			{ "record_id": "R029", "name": "Vartan", "surname": "Sarkisian", "culture": "Armenian", "religion": "Armenian Apostolic" },
			{ "record_id": "R030", "name": "Giovanni", "surname": "Dandolo", "culture": "Venetian", "religion": "Catholic" },

			{ "record_id": "R031", "name": "Theodoros", "surname": "Gabras", "culture": "Byzantine", "religion": "Orthodox" },
			{ "record_id": "R032", "name": "Musa", "surname": "al-Iskandari", "culture": "Egyptian", "religion": "Muslim" },
			{ "record_id": "R033", "name": "Pierre", "surname": "de Montpellier", "culture": "Occitan", "religion": "Catholic" },
			{ "record_id": "R034", "name": "Nasir", "surname": "al-Dimashqi", "culture": "Syrian", "religion": "Muslim" },
			{ "record_id": "R035", "name": "Yakov", "surname": "ben Meir", "culture": "Hebrew", "religion": "Jewish" },
			{ "record_id": "R036", "name": "Andronikos", "surname": "Angelos", "culture": "Byzantine", "religion": "Orthodox" },
			{ "record_id": "R037", "name": "Rostam", "surname": "Bahmani", "culture": "Persian", "religion": "Muslim" },
			{ "record_id": "R038", "name": "Enrico", "surname": "Morosini", "culture": "Venetian", "religion": "Catholic" },
			{ "record_id": "R039", "name": "Bedros", "surname": "Hovhannisian", "culture": "Armenian", "religion": "Armenian Apostolic" },
			{ "record_id": "R040", "name": "Henri", "surname": "de Antioch", "culture": "Frankish", "religion": "Catholic" },

			{ "record_id": "R041", "name": "Omar", "surname": "ibn Said", "culture": "Arabic", "religion": "Muslim" },
			{ "record_id": "R042", "name": "Raphael", "surname": "ben Daniel", "culture": "Hebrew", "religion": "Jewish" },
			{ "record_id": "R043", "name": "Ioannes", "surname": "Kantakouzenos", "culture": "Byzantine", "religion": "Orthodox" },
			{ "record_id": "R044", "name": "Qasim", "surname": "al-Yafi", "culture": "Yemeni", "religion": "Muslim" },
			{ "record_id": "R045", "name": "Demetrios", "surname": "Lascaris", "culture": "Greek", "religion": "Orthodox" },
			{ "record_id": "R046", "name": "Balian", "surname": "d'Ibelin", "culture": "Frankish", "religion": "Catholic" },
			{ "record_id": "R047", "name": "Karim", "surname": "al-Baghdadi", "culture": "Persian", "religion": "Muslim" },
			{ "record_id": "R048", "name": "Samir", "surname": "al-Halabi", "culture": "Syrian", "religion": "Muslim" },
			{ "record_id": "R049", "name": "Yehuda", "surname": "ben Aaron", "culture": "Hebrew", "religion": "Jewish" },
			{ "record_id": "R050", "name": "Luca", "surname": "Gradenigo", "culture": "Venetian", "religion": "Catholic" }
		],

		"correct_record_id": "R002",

		"hints": [
			"Begin by checking the culture field.",
			"The missing merchant is recorded as Hebrew.",
			"Look for the merchant named Miriam.",
			"The correct record is R002."
		],

		"hearts": 4,
		"time_limit": 240
	}