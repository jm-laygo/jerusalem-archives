extends RefCounted

const RECORD_ID_PREFIX := "R"

const CASE_MISSING_MERCHANT := "missing_merchant"
const CASE_QUARANTINE_CLEARANCE := "quarantine_clearance"
const CASE_FALSE_PILGRIM := "false_pilgrim"
const CASE_RELIGIOUS_WITNESS := "religious_witness"
const CASE_CARGO_DISPUTE := "cargo_dispute"
const CASE_FAMILY_LEDGER := "family_ledger"
const CASE_STOREHOUSE_THEFT := "storehouse_theft"
const CASE_CHAPEL_QUARREL := "chapel_quarrel"
const CASE_DIPLOMATIC_ATTENDANT := "diplomatic_attendant"
const CASE_MISSING_INTERPRETER := "missing_interpreter"
const CASE_SPOILED_GRAIN := "spoiled_grain"
const CASE_SAFE_CONDUCT_ENVOY := "safe_conduct_envoy"
const CASE_DEAD_CLERK_SEAL := "dead_clerk_seal"
const CASE_CARAVAN_SPY := "caravan_spy"
const CASE_FINAL_CLEARANCE := "final_clearance"

var db: Object
var random := RandomNumberGenerator.new()


func _init(database: Object) -> void:
	db = database
	random.randomize()


func generateLevel(levelData: Dictionary) -> Dictionary:
	var columns: Array = levelData.get("columns", [])
	var caseType: String = str(levelData.get("case_type", CASE_MISSING_MERCHANT))
	var recordCount: int = int(levelData.get("record_count", 50))
	var targetCount: int = getTargetCount(levelData)

	var people: Array = loadPeople(levelData)

	if people.is_empty():
		push_error("No people available for generated level.")
		return levelData

	var targets: Array = pickTargets(people, targetCount)
	var records: Array = buildGeneratedRecords(columns, people, targets, recordCount, caseType)
	var correctIds: Array[String] = getTargetRecordIds(targets)

	levelData["records"] = records
	levelData["correct_record_ids"] = correctIds

	if correctIds.is_empty():
		levelData["correct_record_id"] = ""
	else:
		levelData["correct_record_id"] = correctIds[0]

	return levelData


func getTargetCount(levelData: Dictionary) -> int:
	var selectionMode: String = str(levelData.get("selection_mode", "single")).to_lower()
	var selectionLimit: int = int(levelData.get("selection_limit", 1))

	if selectionMode == "multiple":
		return max(selectionLimit, 1)

	return 1


func loadPeople(levelData: Dictionary) -> Array:
	var targetRole: String = str(levelData.get("target_role", "")).strip_edges()

	var success: bool

	if targetRole.is_empty() or targetRole == "Any":
		success = db.query("SELECT name, surname, culture, religion, sex, role FROM person_pool;")
	else:
		success = db.query_with_bindings(
			"SELECT name, surname, culture, religion, sex, role FROM person_pool WHERE role = ?;",
			[targetRole]
		)

	if not success:
		push_error("Person pool query failed: %s" % db.error_message)
		return []

	var people: Array = []

	for row in db.query_result:
		people.append({
			"name": str(row.get("name", "")),
			"surname": str(row.get("surname", "")),
			"culture": str(row.get("culture", "")),
			"religion": str(row.get("religion", "")),
			"sex": str(row.get("sex", "")),
			"role": str(row.get("role", ""))
		})

	return people


func pickTargets(people: Array, targetCount: int) -> Array:
	var pool := people.duplicate(true)
	pool.shuffle()

	var targets: Array = []
	var safeCount: int = min(targetCount, pool.size())

	for index in range(safeCount):
		targets.append(pool[index].duplicate(true))

	return targets


func buildGeneratedRecords(
	columns: Array,
	people: Array,
	targets: Array,
	recordCount: int,
	caseType: String
) -> Array:
	var selectedPeople: Array = []

	for target in targets:
		selectedPeople.append(target)

	var pool := people.duplicate(true)
	pool.shuffle()

	for person in pool:
		if selectedPeople.size() >= recordCount:
			break

		if isPersonInList(person, targets):
			continue

		selectedPeople.append(person.duplicate(true))

	selectedPeople.shuffle()

	var records: Array = []

	for index in range(selectedPeople.size()):
		var person: Dictionary = selectedPeople[index]
		var recordId: String = makeRecordId(index + 1)
		var isTarget: bool = isPersonInList(person, targets)
		var record := buildOneRecord(columns, person, recordId, isTarget, caseType)

		records.append(record)

		if isTarget:
			for target in targets:
				if isSamePerson(person, target):
					target["record_id"] = recordId

	return records


func buildOneRecord(
	columns: Array,
	person: Dictionary,
	recordId: String,
	isTarget: bool,
	caseType: String
) -> Dictionary:
	var record: Dictionary = {}

	for column in columns:
		var key: String = str(column.get("key", ""))

		if key.is_empty():
			continue

		record[key] = getValueForKey(key, person, recordId, isTarget, caseType)

	applyCaseOverrides(record, person, isTarget, caseType)

	return record


func getValueForKey(
	key: String,
	person: Dictionary,
	recordId: String,
	isTarget: bool,
	caseType: String
):
	match key:
		"record_id":
			return recordId
		"name":
			return str(person.get("name", ""))
		"surname":
			return str(person.get("surname", ""))
		"sex":
			return str(person.get("sex", ""))
		"culture":
			return str(person.get("culture", ""))
		"religion":
			return str(person.get("religion", ""))
		"role":
			return getRoleValue(person, isTarget, caseType)
		"origin":
			return getOrigin(person)
		"last_seen":
			return getLastSeen(person)
		"ship_name":
			return randomFrom(["Saint Anne", "Sea Falcon", "Pilgrim Star", "Dawn of Acre", "Venetian Dove", "Harbor Mercy"])
		"health_mark":
			return randomFrom(["Clear", "Clear", "Watched", "Fevered"])
		"quarantine_status":
			return randomFrom(["None", "None", "Watched", "Required"])
		"departure_status":
			return randomFrom(["Held", "Cleared", "Pending"])
		"declared_role":
			return str(person.get("role", "Traveler"))
		"cargo":
			return randomFrom(["Grain", "Silk", "Olive Oil", "Spices", "Trade Weights", "Iron Tools", "Medicaments"])
		"pilgrim_group":
			return randomFrom(["Listed", "Listed", "Not Listed", "Chapel Roll"])
		"destination":
			return randomFrom(["Jerusalem", "Acre", "Ramla", "Caesarea", "Bethlehem"])
		"gate_pass":
			return randomFrom(["Approved", "Pending", "Requested", "Denied"])
		"prayer_site":
			return getPrayerSite(person)
		"cargo_owner":
			return "%s %s" % [person.get("name", ""), person.get("surname", "")]
		"cargo_mark":
			return randomFrom(["Blue Wax", "Red Wax", "Cross Mark", "Lion Mark", "Unmarked"])
		"seal_condition":
			return randomFrom(["Intact", "Intact", "Worn", "Broken"])
		"dock_clerk":
			return randomFrom(["Thomas of Tyre", "Matthaios Kallistos", "Yehuda ben Aaron", "Bedros Hovhannisian"])
		"inspection_note":
			return randomFrom(["Passed inspection", "Delayed", "Corrected before seal", "No issue recorded"])
		"family_line":
			return getFamilyLine(person)
		"religious_community":
			return str(person.get("religion", ""))
		"ledger_status":
			return randomFrom(["Filed", "Filed", "Copied", "Missing From Roll"])
		"night_access":
			return randomFrom(["No", "No", "Yes"])
		"assigned_area":
			return randomFrom(["Outer Gate", "Harbor Storehouse", "Customs Hall", "West Quay", "Guardhouse"])
		"key_status":
			return randomFrom(["Returned", "Returned", "Logged", "Unreturned"])
		"guard_post":
			return randomFrom(["North Post", "South Gate", "Storehouse Door", "Customs Steps"])
		"warehouse_bay":
			return randomFrom(["Bay I", "Bay II", "Bay III", "Bay IV", "Chapel Store"])
		"witness_location":
			return randomFrom(["Market Steps", "Armenian Quarter", "Harbor Mosque", "Customs Hall", "Synagogue Scribes"])
		"alibi_status":
			return randomFrom(["Confirmed", "Unclear", "Contradicted"])
		"dispute_reason":
			return randomFrom(["Missing goods", "Broken seal", "Wrong bay", "Unpaid porterage"])
		"envoy_origin":
			return randomFrom(["Byzantium", "Antioch", "Damascus", "Cairo", "Jerusalem Court"])
		"diplomatic_seal":
			return randomFrom(["Present", "Present", "Damaged", "Missing"])
		"escort_status":
			return randomFrom(["Listed", "Listed", "Missing", "Mismatched"])
		"letter_bearer":
			return randomFrom(["Yes", "No"])
		"language":
			return getLanguage(person)
		"assigned_pier":
			return randomFrom(["East Pier", "West Pier", "Pilgrim Quay", "Customs Pier"])
		"interpreter_assigned":
			return randomFrom(["Yes", "No"])
		"status":
			return randomFrom(["Present", "Present", "Absent", "Delayed"])
		"witness_statement":
			return randomFrom(["Order was misunderstood", "Interpreter not seen", "Guard refused entry", "Merchant protested"])
		"inspector":
			return randomFrom(["Musa al-Iskandari", "Andronikos Angelos", "Enrico Morosini"])
		"condition":
			return randomFrom(["Sound", "Sound", "Damp", "Spoiled"])
		"correction_mark":
			return randomFrom(["None", "None", "Minor", "Altered"])
		"tax_clerk":
			return randomFrom(["Thomas of Tyre", "Yehuda ben Aaron", "Matthaios Kallistos"])
		"manifest_status":
			return randomFrom(["Accepted", "Accepted", "Delayed", "Disputed"])
		"court_affiliation":
			return randomFrom(["Frankish Court", "Byzantine Mission", "Damascene Envoy", "Local Harbor Office"])
		"safe_conduct":
			return randomFrom(["Valid", "Valid", "Pending", "Missing"])
		"escort_name":
			return "%s %s" % [person.get("name", ""), person.get("surname", "")]
		"guard_warning":
			return randomFrom(["None", "None", "Watch closely", "Seal questioned"])
		"permit_type":
			return randomFrom(["Road Permit", "Trade Permit", "Pilgrim Pass", "Escort Writ"])
		"seal_date":
			return randomFrom(["Before Death", "Before Death", "Same Day", "After Death"])
		"seal_authority":
			return randomFrom(["Thomas of Tyre", "Dead Clerk", "Harbor Commander", "Customs Hall"])
		"clerk":
			return randomFrom(["Thomas of Tyre", "Matthaios Kallistos", "Yehuda ben Aaron"])
		"clerk_status":
			return randomFrom(["Alive", "Alive", "Transferred", "Dead"])
		"road_permit":
			return randomFrom(["Valid", "Valid", "Pending", "Questioned"])
		"claimed_origin":
			return getOrigin(person)
		"recorded_origin":
			return getOrigin(person)
		"witness_match":
			return randomFrom(["Yes", "Yes", "Unclear", "No"])
		"caravan":
			return randomFrom(["North Road", "Jerusalem Road", "Ramla Caravan", "Pilgrim Train"])
		"final_status":
			return randomFrom(["Held", "Pending", "Cleared"])
		"permit_status":
			return randomFrom(["Valid", "Valid", "Pending", "Forged"])
		"archive_mark":
			return randomFrom(["Clean", "Clean", "Review", "Warning"])
		"warning_note":
			return randomFrom(["None", "None", "Health warning", "Permit warning", "Archive warning"])
		"road_clearance":
			return randomFrom(["Held", "Pending", "Approved"])

	return ""


func applyCaseOverrides(record: Dictionary, person: Dictionary, isTarget: bool, caseType: String) -> void:
	if not isTarget:
		return

	match caseType:
		CASE_MISSING_MERCHANT:
			record["last_seen"] = getLastSeen(person)

		CASE_QUARANTINE_CLEARANCE:
			record["health_mark"] = "Fevered"
			record["quarantine_status"] = "Required"
			record["departure_status"] = "Cleared"

		CASE_FALSE_PILGRIM:
			record["declared_role"] = "Pilgrim"
			record["cargo"] = "Trade Weights"
			record["pilgrim_group"] = "Not Listed"
			record["gate_pass"] = "Requested"

		CASE_RELIGIOUS_WITNESS:
			record["prayer_site"] = getPrayerSite(person)
			record["last_seen"] = getPrayerSite(person)

		CASE_CARGO_DISPUTE:
			record["seal_condition"] = "Broken"
			record["inspection_note"] = "Corrected after seal"
			record["cargo_mark"] = "Unmarked"

		CASE_FAMILY_LEDGER:
			record["ledger_status"] = "Missing From Roll"
			record["family_line"] = getFamilyLine(person)

		CASE_STOREHOUSE_THEFT:
			record["night_access"] = "Yes"
			record["assigned_area"] = "Harbor Storehouse"
			record["key_status"] = "Unreturned"

		CASE_CHAPEL_QUARREL:
			record["witness_location"] = "Armenian Quarter"
			record["alibi_status"] = "Contradicted"
			record["dispute_reason"] = "Missing goods"

		CASE_DIPLOMATIC_ATTENDANT:
			record["diplomatic_seal"] = "Present"
			record["escort_status"] = "Missing"
			record["letter_bearer"] = "Yes"

		CASE_MISSING_INTERPRETER:
			record["interpreter_assigned"] = "Yes"
			record["status"] = "Absent"
			record["witness_statement"] = "Interpreter not seen"

		CASE_SPOILED_GRAIN:
			record["cargo"] = "Grain"
			record["condition"] = "Spoiled"
			record["correction_mark"] = "Altered"
			record["manifest_status"] = "Disputed"

		CASE_SAFE_CONDUCT_ENVOY:
			record["safe_conduct"] = "Valid"
			record["escort_status"] = "Mismatched"
			record["guard_warning"] = "Seal questioned"

		CASE_DEAD_CLERK_SEAL:
			record["seal_date"] = "After Death"
			record["seal_authority"] = "Dead Clerk"
			record["clerk_status"] = "Dead"
			record["road_permit"] = "Questioned"

		CASE_CARAVAN_SPY:
			record["claimed_origin"] = randomFrom(["Antioch", "Damascus", "Cairo", "Byzantium"])
			record["recorded_origin"] = randomDifferentOrigin(str(record["claimed_origin"]))
			record["witness_match"] = "No"
			record["final_status"] = "Cleared"

		CASE_FINAL_CLEARANCE:
			record["final_status"] = "Cleared"
			record["road_clearance"] = "Approved"
			record["archive_mark"] = "Warning"
			record["warning_note"] = randomFrom(["Health warning", "Permit warning", "Archive warning"])


func getTargetRecordIds(targets: Array) -> Array[String]:
	var ids: Array[String] = []

	for target in targets:
		var recordId: String = str(target.get("record_id", ""))

		if not recordId.is_empty():
			ids.append(recordId)

	return ids


func isPersonInList(person: Dictionary, peopleList: Array) -> bool:
	for item in peopleList:
		if isSamePerson(person, item):
			return true

	return false


func isSamePerson(a: Dictionary, b: Dictionary) -> bool:
	return (
		str(a.get("name", "")) == str(b.get("name", "")) and
		str(a.get("surname", "")) == str(b.get("surname", "")) and
		str(a.get("culture", "")) == str(b.get("culture", "")) and
		str(a.get("religion", "")) == str(b.get("religion", "")) and
		str(a.get("sex", "")) == str(b.get("sex", "")) and
		str(a.get("role", "")) == str(b.get("role", ""))
	)


func makeRecordId(number: int) -> String:
	return "%s%03d" % [RECORD_ID_PREFIX, number]


func randomFrom(values: Array) -> String:
	if values.is_empty():
		return ""

	return str(values[random.randi_range(0, values.size() - 1)])


func randomDifferentOrigin(origin: String) -> String:
	var origins := ["Antioch", "Damascus", "Cairo", "Byzantium", "Acre", "Jerusalem", "Ramla"]

	origins.erase(origin)

	if origins.is_empty():
		return "Unknown"

	return randomFrom(origins)


func getOrigin(person: Dictionary) -> String:
	var culture: String = str(person.get("culture", ""))

	match culture:
		"Arabic":
			return "Jaffa"
		"Syrian":
			return "Damascus"
		"Egyptian":
			return "Cairo"
		"Hebrew":
			return "Jewish Quarter"
		"Armenian":
			return "Cilicia"
		"Byzantine", "Greek":
			return "Byzantium"
		"Venetian":
			return "Venice"
		"Frankish", "Occitan":
			return "Western Lands"
		"Persian":
			return "Persia"
		"Yemeni":
			return "Yemen"
		"Turkic":
			return "Eastern Marches"

	return "Unknown"


func getLastSeen(person: Dictionary) -> String:
	var religion: String = str(person.get("religion", ""))

	match religion:
		"Muslim":
			return "Harbor Mosque"
		"Jewish":
			return "Synagogue Scribes"
		"Catholic":
			return "Latin Chapel"
		"Orthodox":
			return "Eastern Quay"
		"Armenian Apostolic":
			return "Armenian Quarter"

	return "Customs Steps"


func getPrayerSite(person: Dictionary) -> String:
	var religion: String = str(person.get("religion", ""))

	match religion:
		"Muslim":
			return "Harbor Mosque"
		"Jewish":
			return "Synagogue Scribes"
		"Catholic":
			return "Latin Chapel"
		"Orthodox":
			return "Greek Chapel"
		"Armenian Apostolic":
			return "Armenian Chapel"

	return "Harbor Shrine"


func getFamilyLine(person: Dictionary) -> String:
	var surname: String = str(person.get("surname", ""))

	if surname.contains("bat "):
		return "Daughter Line"

	if surname.contains("ben "):
		return "Son Line"

	if surname.contains("ibn "):
		return "House of Father"

	if surname.contains("de "):
		return "Western House"

	if surname.contains("of "):
		return "Place Line"

	return "Family Roll"


func getLanguage(person: Dictionary) -> String:
	var culture: String = str(person.get("culture", ""))

	match culture:
		"Arabic", "Syrian", "Egyptian", "Yemeni":
			return "Arabic"
		"Hebrew":
			return "Hebrew"
		"Byzantine", "Greek":
			return "Greek"
		"Armenian":
			return "Armenian"
		"Frankish", "Occitan":
			return "Latin"
		"Venetian":
			return "Venetian"
		"Persian":
			return "Persian"
		"Turkic":
			return "Turkic"

	return "Mixed"


func getRoleValue(person: Dictionary, isTarget: bool, caseType: String) -> String:
	if isTarget and caseType == CASE_FALSE_PILGRIM:
		return "Pilgrim"

	return str(person.get("role", "Traveler"))