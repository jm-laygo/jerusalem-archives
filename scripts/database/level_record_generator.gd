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

	var targetRecords: Array = getRecordsByIds(records, correctIds)
	var cluePhrases: Array = buildCluePhrasesFromHeaders(levelData, targetRecords)

	levelData["clue_phrases"] = cluePhrases
	levelData["story"] = buildMessageReportFromHeaders(levelData, targetRecords, cluePhrases)
	levelData["hints"] = buildHintsFromClues(levelData, cluePhrases)

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

# Builds an immersive multi-page case report based on the generated answer.
# Pages are separated with ||| for the info popup BACK/NEXT buttons.
func buildCaseReport(levelData: Dictionary, targets: Array) -> String:
	var caseType: String = str(levelData.get("case_type", ""))
	var title: String = str(levelData.get("level_title", "Case Report"))

	if targets.is_empty():
		return buildFallbackCaseReport(title)

	var target: Dictionary = targets[0]
	var targetCount: int = targets.size()

	match caseType:
		CASE_MISSING_MERCHANT:
			return buildMissingMerchantReport(target)

		CASE_QUARANTINE_CLEARANCE:
			return buildQuarantineReport(target)

		CASE_FALSE_PILGRIM:
			return buildFalsePilgrimReport(target)

		CASE_RELIGIOUS_WITNESS:
			return buildReligiousWitnessReport(target)

		CASE_CARGO_DISPUTE:
			return buildCargoDisputeReport(target)

		CASE_FAMILY_LEDGER:
			return buildFamilyLedgerReport(target)

		CASE_STOREHOUSE_THEFT:
			return buildStorehouseTheftReport(target)

		CASE_CHAPEL_QUARREL:
			return buildChapelQuarrelReport(target)

		CASE_DIPLOMATIC_ATTENDANT:
			return buildDiplomaticReport(target)

		CASE_MISSING_INTERPRETER:
			return buildInterpreterReport(target)

		CASE_SPOILED_GRAIN:
			return buildSpoiledGrainReport(targetCount)

		CASE_SAFE_CONDUCT_ENVOY:
			return buildSafeConductReport(targetCount)

		CASE_DEAD_CLERK_SEAL:
			return buildDeadClerkSealReport(targetCount)

		CASE_CARAVAN_SPY:
			return buildCaravanSpyReport(targetCount)

		CASE_FINAL_CLEARANCE:
			return buildFinalClearanceReport(targetCount)

	return buildFallbackCaseReport(title)


func buildFallbackCaseReport(_title: String) -> String:
	return "Servant of the archive, a troubled record has reached your desk.|||The matter is unclear, and the witnesses offer only fragments.|||Compare the records carefully. The truth is hidden in the fields, not in the names alone.|||Resolve the case before the harbor seal is closed."


# LEVEL 1
func buildMissingMerchantReport(target: Dictionary) -> String:
	var faithClue: String = getFaithLetterClue(target)
	var cultureClue: String = getCultureLetterClue(target)
	var lastSeen: String = getLastSeen(target)

	return (
		"To the newly arrived keeper of the harbor roll,\n\n"
		+ "I write before the ink dries on your appointment, for Jaffa has already placed a burden upon your table. "
		+ "A merchant was entered upon the departure roll at dawn, yet by the time the seal was called for, the name had vanished as though scraped from the skin of the parchment."
		+ "|||"
		+ "The witness is no scholar and remembers no full name. He swears only that the missing merchant was seen near %s, standing apart from the louder traders while the bells and calls of the harbor crossed one another in the morning air." % lastSeen
		+ "|||"
		+ "%s %s These are not names, but they are not empty words. A man carries his prayers, his tongue, and his road upon him even when his written name is lost."
		% [faithClue, cultureClue]
		+ "|||"
		+ "Therefore search the surviving harbor records. Do not trust the first familiar name. Find the merchant whose record agrees with the witness, the place, and the people around him.\n\n"
		+ "Signed,\nHarbor Clerk Thomas of Tyre"
	)


# LEVEL 2
func buildQuarantineReport(_target: Dictionary) -> String:
	return (
		"To the examiner of the quay records,\n\n"
		+ "The fever bell was struck before noon, and all men looked toward the ship as though death itself had stepped onto the planks. The physician ordered the marked travelers kept beneath watch near the quarantine tents."
		+ "|||"
		+ "Yet one record bears the shape of a lie. The body was marked unclean by sickness, the tents were ordered, and still the departure hand was too generous with its approval."
		+ "|||"
		+ "Do not be deceived by names or origins. In this matter, the sickness writes more truth than the traveler. The mark of fever, the order of quarantine, and the leave to depart must agree."
		+ "|||"
		+ "Find the traveler who should have been held at the quay. If that person reaches the Jerusalem road, the archive will have carried illness inland.\n\n"
		+ "Signed,\nPhysician Musa al-Iskandari"
	)


# LEVEL 3
func buildFalsePilgrimReport(target: Dictionary) -> String:
	var cultureClue: String = getCultureLetterClue(target)

	return (
		"To the keeper of pilgrim names,\n\n"
		+ "A man came beneath a humble badge and spoke of vows, dust, and Jerusalem. But when his pack was opened, the mercy of pilgrimage was not all that lay within."
		+ "|||"
		+ "Trade weights were found beside his travel things, and slips of cargo were folded with more care than any prayer token. %s" % cultureClue
		+ "|||"
		+ "A true pilgrim is known not only by words, but by the company that receives him, the pass that carries him, and the burden he chooses to bring."
		+ "|||"
		+ "Search the records. Find the one who asks for holy passage while carrying the habits of trade.\n\n"
		+ "Signed,\nCustoms Clerk Bedros Hovhannisian"
	)


# LEVEL 4
func buildReligiousWitnessReport(target: Dictionary) -> String:
	var faithClue: String = getFaithLetterClue(target)
	var place: String = getPrayerSite(target)

	return (
		"To the servant who weighs witness against record,\n\n"
		+ "A dockhand came trembling to the archive, speaking through another man''s tongue. He knew no name, no surname, no family house, yet he would not abandon what he saw."
		+ "|||"
		+ "He saw the person near %s before the harbor crowd scattered. The witness remembered posture, prayer, and the company of those who gathered nearby." % place
		+ "|||"
		+ "%s In such details, the careless hear nothing. The careful hear the beginning of a name." % faithClue
		+ "|||"
		+ "Look to the record that agrees with the place of prayer. The witness gave you no name, but he gave you the road toward it.\n\n"
		+ "Signed,\nInterpreter Nasir al-Dimashqi"
	)


# LEVEL 5
func buildCargoDisputeReport(_target: Dictionary) -> String:
	return (
		"To the judge of seals,\n\n"
		+ "The Venetians have raised their voices again, and this time the quarrel has teeth. They accuse the watch of opening a crate before inspection, while the guards swear by steel and cross that no hand was laid upon it."
		+ "|||"
		+ "The manifest, however, speaks with a weaker oath. One record bears a damaged seal, an uncertain cargo mark, and a correction made after the seal should already have settled the matter."
		+ "|||"
		+ "A clean seal and a clean inspection walk together. When wax, mark, and note pull apart, someone has written after the truth."
		+ "|||"
		+ "Find the cargo record whose seal and inspection cannot both be honest.\n\n"
		+ "Signed,\nHarbor Notary Matteo of Acre"
	)


# LEVEL 6
func buildFamilyLedgerReport(target: Dictionary) -> String:
	var familyClue: String = getFamilyLetterClue(target)
	var faithClue: String = getFaithLetterClue(target)

	return (
		"To the keeper of copied names,\n\n"
		+ "A ledger from the quarter of family scribes was brought to me with trembling hands. A woman is remembered by her house, yet her place in the harbor copy has been broken."
		+ "|||"
		+ "%s The family form matters here, for fathers, sons, daughters, and houses leave different marks upon the page." % familyClue
		+ "|||"
		+ "%s The community record should have carried her safely from one roll to the next, yet the copied ledger failed her." % faithClue
		+ "|||"
		+ "Find the person whose family identity remains visible, while the ledger status shows the wound.\n\n"
		+ "Signed,\nYehuda ben Aaron, Scribe of the Quarter"
	)


# LEVEL 7
func buildStorehouseTheftReport(_target: Dictionary) -> String:
	return (
		"To the examiner of keys,\n\n"
		+ "Frankish blades have vanished from a locked storehouse, and already men seek an easy culprit among those who carry crates and sweep the quay."
		+ "|||"
		+ "But iron does not leave a locked room by rumor. Someone had night passage where he should not have passed, and a key did not return as cleanly as the guard captain claims."
		+ "|||"
		+ "Look not first at blood, tongue, or station. Look at access, assigned place, and the fate of the key."
		+ "|||"
		+ "Find the record that made the theft possible.\n\n"
		+ "Signed,\nHugh de Jaffa, Guard Captain"
	)


# LEVEL 8
func buildChapelQuarrelReport(target: Dictionary) -> String:
	var cultureClue: String = getCultureLetterClue(target)

	return (
		"To the keeper set between angry merchants,\n\n"
		+ "The quarter near the chapel has filled with accusation. Goods have vanished, tempers have sharpened, and every man now points toward the nearest porter."
		+ "|||"
		+ "%s The accused swears he was elsewhere, but a witness places him near the very path he denies." % cultureClue
		+ "|||"
		+ "An alibi is only as strong as the place that supports it. When witness location and written claim oppose one another, the record begins to confess."
		+ "|||"
		+ "Find the entry whose own alibi breaks beneath the witness account.\n\n"
		+ "Signed,\nBedros Hovhannisian"
	)


# LEVEL 9
func buildDiplomaticReport(_target: Dictionary) -> String:
	return (
		"To the keeper of seals and foreign courtesy,\n\n"
		+ "An emissary from the Greek court stands at Jaffa with a sealed letter bound for Jerusalem. His patience is thin, and his attendants are counted twice."
		+ "|||"
		+ "One attendant is not held properly by the list. The seal is present, the duty is grave, yet the escort record leaves a dangerous absence."
		+ "|||"
		+ "In matters of empire, a missing attendant is not a small mistake. Escort, seal, and letter duty must stand together."
		+ "|||"
		+ "Find the record that threatens the envoy''s passage before insult becomes report.\n\n"
		+ "Signed,\nMatthaios Kallistos"
	)


# LEVEL 10
func buildInterpreterReport(target: Dictionary) -> String:
	var languageClue: String = getLanguageLetterClue(target)

	return (
		"To the one who keeps order when tongues fail,\n\n"
		+ "Merchants and Latin guards nearly drew steel after an order was carried badly across the pier. The quarrel did not begin with hate, but with absence."
		+ "|||"
		+ "%s The interpreter assigned to that place was expected, named, and recorded, yet not seen when needed." % languageClue
		+ "|||"
		+ "A language need, an assigned pier, and a status line must agree. If they do not, the missing man is found in the contradiction."
		+ "|||"
		+ "Find the interpreter whose record says assigned, but whose body never came.\n\n"
		+ "Signed,\nRashid al-Suri"
	)


# LEVEL 11
func buildSpoiledGrainReport(targetCount: int) -> String:
	return (
		"To the keeper of customs scales,\n\n"
		+ "The garrison grain has soured, and the quay is close to riot. Men shout of hunger, fraud, and blame, while the manifests lie damp beneath your hand."
		+ "|||"
		+ "More than one record may be stained. Grain that is merely poor is one matter. Grain marked spoiled and then altered in the manifest is another."
		+ "|||"
		+ "Look for the union of rot and correction. Condition, correction mark, and manifest status will reveal the corrupted entries."
		+ "|||"
		+ "Select all %s records that show both spoiled grain and tampering.\n\nSigned,\nInspector Musa al-Iskandari" % targetCount
	)


# LEVEL 12
func buildSafeConductReport(targetCount: int) -> String:
	return (
		"To the keeper of promises under seal,\n\n"
		+ "An envoy under safe conduct has entered Jaffa. Some guards watch him as though courtesy were weakness, and that is how wars begin in ledgers before they begin in streets."
		+ "|||"
		+ "More than one entry threatens the promise. Protection must agree with escort, seal, and warning, or the parchment becomes an insult."
		+ "|||"
		+ "A valid safe conduct with a broken escort is a dangerous contradiction. A questioned seal beside diplomatic protection is no small matter."
		+ "|||"
		+ "Select all %s records that endanger the safe-conduct list.\n\nSigned,\nHarbor Commander Amalric" % targetCount
	)


# LEVEL 13
func buildDeadClerkSealReport(targetCount: int) -> String:
	return (
		"To the reader of wax and death,\n\n"
		+ "A permit has arrived bearing the authority of a clerk already named among the dead. Yet other permits in the bundle bear similar confidence."
		+ "|||"
		+ "The dead do not press seals after burial, no matter how clean the wax appears. Date, authority, clerk, and status must answer one another."
		+ "|||"
		+ "More than one permit may have borrowed a dead hand. Do not trust the look of office. Trust the contradiction."
		+ "|||"
		+ "Select all %s permits that could not have been honestly sealed.\n\nSigned,\nThomas of Tyre" % targetCount
	)


# LEVEL 14
func buildCaravanSpyReport(targetCount: int) -> String:
	return (
		"To the keeper before the Jerusalem road,\n\n"
		+ "The caravan gathers before dawn, and every traveler wears dust enough to hide a lie. The commander believes some names have been dressed in false origins."
		+ "|||"
		+ "A claimed homeland may sound harmless until the archive records another. A witness who does not match makes the lie sharper."
		+ "|||"
		+ "More than one traveler may carry a borrowed origin. Compare claim, record, witness, and final clearance."
		+ "|||"
		+ "Select all %s caravan records whose identities fail under comparison.\n\nSigned,\nOdo de Acre" % targetCount
	)


# LEVEL 15
func buildFinalClearanceReport(targetCount: int) -> String:
	return (
		"To the final hand before Jerusalem,\n\n"
		+ "The road opens at dawn. What passes your table may pass beneath the walls of the Holy City, and a careless seal may carry sickness, forgery, or danger inland."
		+ "|||"
		+ "Some records bear warnings yet still ask to be approved. A warning ignored is not a warning removed. It is a sin written neatly."
		+ "|||"
		+ "Look for the records where danger stands beside clearance: illness, false permit, archive warning, or disputed approval."
		+ "|||"
		+ "Select all %s records wrongly cleared for the Jerusalem road.\n\nSigned,\nThe Harbor Archive" % targetCount
	)


# Builds better generated hints based on the current generated case.
func buildGeneratedHints(levelData: Dictionary, _targets: Array) -> Array:
	var caseType: String = str(levelData.get("case_type", ""))

	match caseType:
		CASE_MISSING_MERCHANT:
			return [
				"The case report tells you a place. Start with Last Seen.",
				"Last Seen points toward Religion or Culture.",
				"Compare Last Seen, Religion, and Culture together.",
				"The answer is the merchant whose identity fits the witness place."
			]

		CASE_QUARANTINE_CLEARANCE:
			return [
				"Find a medical contradiction.",
				"Fevered should not be freely cleared.",
				"Compare Health Mark, Quarantine Status, and Departure Status.",
				"The answer is Fevered, Required, and Cleared."
			]

		CASE_FALSE_PILGRIM:
			return [
				"The false pilgrim is exposed by cargo.",
				"Compare Declared Role and Cargo.",
				"Pilgrim plus Trade Weights is suspicious.",
				"Find the record claiming Pilgrim while carrying trade evidence."
			]

		CASE_RELIGIOUS_WITNESS:
			return [
				"The witness gave a prayer place.",
				"Prayer Site points to Religion.",
				"Compare Prayer Site and Religion.",
				"The answer matches both the place and the faith."
			]

		CASE_CARGO_DISPUTE:
			return [
				"Start with Seal Condition.",
				"A broken seal with a corrected inspection note is suspicious.",
				"Compare Seal Condition, Cargo Mark, and Inspection Note.",
				"The answer is the cargo record whose seal and inspection disagree."
			]

		CASE_FAMILY_LEDGER:
			return [
				"Do not search only by name.",
				"Check Sex, Family Line, and Religious Community.",
				"Ledger Status tells you what broke.",
				"The answer has a family identity but a missing ledger status."
			]

		CASE_STOREHOUSE_THEFT:
			return [
				"The thief needed access.",
				"Start with Night Access.",
				"Compare Night Access, Assigned Area, and Key Status.",
				"The answer had storehouse access and a key problem."
			]

		CASE_CHAPEL_QUARREL:
			return [
				"Compare the alibi, not the accusation.",
				"Witness Location matters most.",
				"Alibi Status should agree with Witness Location.",
				"The answer is the record with a contradicted alibi."
			]

		CASE_DIPLOMATIC_ATTENDANT:
			return [
				"Start with Escort Status.",
				"Letter Bearer and Escort Status should agree.",
				"Check Diplomatic Seal too.",
				"The answer has diplomatic duty but is not properly accounted for."
			]

		CASE_MISSING_INTERPRETER:
			return [
				"Find someone assigned but absent.",
				"Compare Interpreter Assigned and Status.",
				"Language and Assigned Pier help confirm the case.",
				"The answer is assigned Yes but Status Absent."
			]

		CASE_SPOILED_GRAIN:
			return [
				"This level has multiple answers.",
				"Grain alone is not enough. Look for spoilage.",
				"Condition must combine with Correction Mark or Manifest Status.",
				"Select every grain record that is Spoiled and Altered or Disputed."
			]

		CASE_SAFE_CONDUCT_ENVOY:
			return [
				"This level has multiple answers.",
				"Safe Conduct must agree with Escort Status.",
				"Guard Warning and Diplomatic Seal matter.",
				"Select every protected record with mismatched or questioned escort details."
			]

		CASE_DEAD_CLERK_SEAL:
			return [
				"This level may have multiple forged permits.",
				"Do not trust the seal alone.",
				"Compare Seal Date with Clerk Status.",
				"Select every permit approved by an impossible authority."
			]

		CASE_CARAVAN_SPY:
			return [
				"This level has multiple suspicious identities.",
				"Compare Claimed Origin and Recorded Origin.",
				"Witness Match should support the claim.",
				"Select every cleared record where origin and witness fail."
			]

		CASE_FINAL_CLEARANCE:
			return [
				"This final level has multiple answers.",
				"Look for Warning Note or Archive Mark first.",
				"Warnings should not be Cleared or Approved.",
				"Select every record cleared despite a warning."
			]

	return [
		"Read the case report first.",
		"Compare the suspicious fields.",
		"Look for contradiction.",
		"Choose the record that best matches the case."
	]


func getFaithLetterClue(target: Dictionary) -> String:
	var religion: String = str(target.get("religion", ""))

	match religion:
		"Muslim":
			return "The witness says the person bowed toward Allah''s mercy and moved with those who answered the call to prayer."
		"Jewish":
			return "The witness heard talk of family ledgers and saw the person near the scribes who keep the old names of Israel."
		"Catholic":
			return "The witness recalls Latin prayers and the sign of the cross made in the western manner."
		"Orthodox":
			return "The witness heard Greek prayers and saw the person among those who kept the eastern rites."
		"Armenian Apostolic":
			return "The witness marked the person among those who kept the Apostolic chapel and the customs of the Armenian faithful."

	return "The witness remembered a manner of prayer, though not the person''s name."


func getCultureLetterClue(target: Dictionary) -> String:
	var culture: String = str(target.get("culture", ""))

	match culture:
		"Armenian":
			return "He spoke of roads near Cilicia and the mountain people who gather by the Armenian quarter."
		"Arabic":
			return "His tongue carried the markets of the Arab coast, familiar to the men of Jaffa."
		"Syrian":
			return "His speech was of the northern caravan roads and the Syrian towns beyond the coast."
		"Egyptian":
			return "He was linked to the southern ships and the Nile road where Egyptian traders bring their goods."
		"Hebrew":
			return "His name was remembered in the manner of the Hebrew families and their careful house records."
		"Byzantine", "Greek":
			return "His words were polished with Greek speech, like those who come through imperial harbors."
		"Venetian":
			return "He bore the manner of the western sea traders and the sharp habits of Venice."
		"Frankish", "Occitan":
			return "He carried the custom of the western knights and towns beyond the sea."
		"Persian":
			return "He was said to know the roads beyond Mesopotamia, where eastern silks and Persian speech travel together."
		"Yemeni":
			return "He was remembered among the men of the southern incense roads."
		"Turkic":
			return "He was linked to horse traders from the eastern marches."

	return "His origin was not named plainly, but his speech and company marked him."


func getFamilyLetterClue(target: Dictionary) -> String:
	var surname: String = str(target.get("surname", ""))

	if surname.contains("bat "):
		return "The family name speaks of a daughter line, and such marks are not placed by accident."
	if surname.contains("ben "):
		return "The family name carries the form of a son remembered through his father."
	if surname.contains("ibn "):
		return "The name follows the father through the older tongue, as many houses of the coast preserve it."
	if surname.contains("de "):
		return "The name carries the western habit of place and house."
	if surname.contains("of "):
		return "The name points toward a place as much as a family."

	return "The family mark is plain enough for a careful reader."


func getLanguageLetterClue(target: Dictionary) -> String:
	var language: String = getLanguage(target)

	match language:
		"Arabic":
			return "The quarrel needed a tongue suited to Arabic speech, yet the assigned voice was absent."
		"Hebrew":
			return "The matter touched Hebrew speech and required one who could carry it cleanly to the guards."
		"Greek":
			return "Greek speech was part of the confusion, and the needed interpreter was not at the pier."
		"Armenian":
			return "The words of the Armenian merchants could not be carried properly without the assigned interpreter."
		"Latin":
			return "Latin orders were part of the quarrel, but the man assigned to bridge them did not appear."
		"Venetian":
			return "The western sea tongue sharpened the dispute, and the proper interpreter was missing."
		"Persian":
			return "Eastern speech was heard in the matter, but the assigned interpreter was absent."
		"Turkic":
			return "The speech of the eastern marches was not understood when it was needed."

	return "The assigned tongue was needed, and the assigned person was absent."





# Gets generated records matching the correct answer IDs.
func getRecordsByIds(records: Array, ids: Array[String]) -> Array:
	var foundRecords: Array = []

	for record in records:
		var recordId := str(record.get("record_id", ""))

		if ids.has(recordId):
			foundRecords.append(record)

	return foundRecords


# Builds clue phrases based on the visible level headers.
func buildCluePhrasesFromHeaders(levelData: Dictionary, targetRecords: Array) -> Array:
	if targetRecords.is_empty():
		return []

	var columns: Array = levelData.get("columns", [])
	var firstTarget: Dictionary = targetRecords[0]
	var caseType := str(levelData.get("case_type", ""))

	if str(levelData.get("selection_mode", "single")) == "multiple":
		return buildMultipleCluePhrases(caseType)

	var cluePhrases: Array = []

	for column in columns:
		var key := str(column.get("key", ""))

		match key:
			"name":
				addUniqueClue(cluePhrases, getNameMemoryPhrase(firstTarget))
			"surname":
				addUniqueClue(cluePhrases, getSurnameMemoryPhrase(firstTarget))
			"culture":
				addUniqueClue(cluePhrases, getCultureMemoryPhrase(str(firstTarget.get("culture", ""))))
			"religion":
				addUniqueClue(cluePhrases, getReligionMemoryPhrase(str(firstTarget.get("religion", ""))))
			"last_seen":
				addUniqueClue(cluePhrases, str(firstTarget.get("last_seen", "")))
			"prayer_site":
				addUniqueClue(cluePhrases, str(firstTarget.get("prayer_site", "")))
			"health_mark":
				addUniqueClue(cluePhrases, str(firstTarget.get("health_mark", "")))
			"quarantine_status":
				addUniqueClue(cluePhrases, str(firstTarget.get("quarantine_status", "")))
			"departure_status":
				addUniqueClue(cluePhrases, str(firstTarget.get("departure_status", "")))
			"declared_role":
				addUniqueClue(cluePhrases, str(firstTarget.get("declared_role", "")))
			"cargo":
				addUniqueClue(cluePhrases, str(firstTarget.get("cargo", "")))
			"pilgrim_group":
				addUniqueClue(cluePhrases, str(firstTarget.get("pilgrim_group", "")))
			"seal_condition":
				addUniqueClue(cluePhrases, str(firstTarget.get("seal_condition", "")))
			"inspection_note":
				addUniqueClue(cluePhrases, str(firstTarget.get("inspection_note", "")))
			"family_line":
				addUniqueClue(cluePhrases, str(firstTarget.get("family_line", "")))
			"ledger_status":
				addUniqueClue(cluePhrases, str(firstTarget.get("ledger_status", "")))
			"night_access":
				addUniqueClue(cluePhrases, "night passage")
			"assigned_area":
				addUniqueClue(cluePhrases, str(firstTarget.get("assigned_area", "")))
			"key_status":
				addUniqueClue(cluePhrases, str(firstTarget.get("key_status", "")))
			"witness_location":
				addUniqueClue(cluePhrases, str(firstTarget.get("witness_location", "")))
			"alibi_status":
				addUniqueClue(cluePhrases, str(firstTarget.get("alibi_status", "")))
			"escort_status":
				addUniqueClue(cluePhrases, str(firstTarget.get("escort_status", "")))
			"letter_bearer":
				addUniqueClue(cluePhrases, "letter duty")
			"language":
				addUniqueClue(cluePhrases, str(firstTarget.get("language", "")))
			"interpreter_assigned":
				addUniqueClue(cluePhrases, "assigned to interpret")
			"status":
				addUniqueClue(cluePhrases, str(firstTarget.get("status", "")))
			"seal_date":
				addUniqueClue(cluePhrases, str(firstTarget.get("seal_date", "")))
			"clerk_status":
				addUniqueClue(cluePhrases, str(firstTarget.get("clerk_status", "")))
			"claimed_origin":
				addUniqueClue(cluePhrases, str(firstTarget.get("claimed_origin", "")))
			"recorded_origin":
				addUniqueClue(cluePhrases, str(firstTarget.get("recorded_origin", "")))
			"witness_match":
				addUniqueClue(cluePhrases, str(firstTarget.get("witness_match", "")))
			"warning_note":
				addUniqueClue(cluePhrases, str(firstTarget.get("warning_note", "")))
			"road_clearance":
				addUniqueClue(cluePhrases, str(firstTarget.get("road_clearance", "")))

	while cluePhrases.size() > 4:
		cluePhrases.pop_back()

	return cluePhrases


# Multiple-selection clues are based on the contradiction pattern.
func buildMultipleCluePhrases(caseType: String) -> Array:
	match caseType:
		CASE_SPOILED_GRAIN:
			return ["rotten grain", "altered manifests", "disputed at the scales", "more than one stained record"]
		CASE_SAFE_CONDUCT_ENVOY:
			return ["safe conduct", "mismatched escort", "questioned seal", "more than one dangerous entry"]
		CASE_DEAD_CLERK_SEAL:
			return ["dead clerk", "After Death", "Questioned", "borrowed a dead hand"]
		CASE_CARAVAN_SPY:
			return ["false origin", "witness did not match", "Cleared", "more than one borrowed identity"]
		CASE_FINAL_CLEARANCE:
			return ["warning sign", "Cleared", "Approved", "wrongly passed toward Jerusalem"]

	return ["more than one record", "hidden contradiction", "dangerous approval", "archive warning"]


func addUniqueClue(clues: Array, clue: String) -> void:
	var cleanClue := clue.strip_edges()

	if cleanClue.is_empty():
		return

	if clues.has(cleanClue):
		return

	clues.append(cleanClue)


# Builds a 4-page immersive message report from visible headers and generated target data.
func buildMessageReportFromHeaders(levelData: Dictionary, targetRecords: Array, cluePhrases: Array) -> String:
	var caseType := str(levelData.get("case_type", ""))
	var selectionMode := str(levelData.get("selection_mode", "single"))

	if selectionMode == "multiple":
		return buildMultipleMessageReport(levelData, cluePhrases)

	if targetRecords.is_empty():
		return buildFallbackMessageReport()

	var target: Dictionary = targetRecords[0]

	match caseType:
		CASE_MISSING_MERCHANT:
			return buildMissingMerchantMessage(target, cluePhrases)
		CASE_QUARANTINE_CLEARANCE:
			return buildQuarantineMessage(target, cluePhrases)
		CASE_FALSE_PILGRIM:
			return buildFalsePilgrimMessage(target, cluePhrases)
		CASE_RELIGIOUS_WITNESS:
			return buildReligiousWitnessMessage(target, cluePhrases)
		CASE_CARGO_DISPUTE:
			return buildCargoMessage(target, cluePhrases)
		CASE_FAMILY_LEDGER:
			return buildFamilyLedgerMessage(target, cluePhrases)
		CASE_STOREHOUSE_THEFT:
			return buildStorehouseMessage(target, cluePhrases)
		CASE_CHAPEL_QUARREL:
			return buildChapelQuarrelMessage(target, cluePhrases)
		CASE_DIPLOMATIC_ATTENDANT:
			return buildDiplomaticMessage(target, cluePhrases)
		CASE_MISSING_INTERPRETER:
			return buildInterpreterMessage(target, cluePhrases)

	return buildFallbackMessageReport()


func buildMissingMerchantMessage(_target: Dictionary, clues: Array) -> String:
	return (
		"To the keeper newly seated at the harbor desk,\n\n"
		+ "This message was carried by a salt-stained clerk who swore the missing merchant stood in the roll before sunrise. By the hour of sealing, the entry had vanished."
		+ "|||"
		+ "The dockhand could not give the whole name. He only remembered %s, and said the sound was spoken uncertainly above the noise of ropes, gulls, and traders." % getSafeClue(clues, 0)
		+ "|||"
		+ "He also remembered %s, and another clerk wrote that the person carried the manners of %s. These fragments are not idle decoration. They are the shape of the missing entry." % [getSafeClue(clues, 1), getSafeClue(clues, 2)]
		+ "|||"
		+ "Search for the merchant whose record agrees with the remembered sound, the people around him, and %s. Do not choose by name alone.\n\nSigned,\nThomas of Tyre" % getSafeClue(clues, 3)
	)


func buildQuarantineMessage(_target: Dictionary, clues: Array) -> String:
	return (
		"To the examiner of the quay,\n\n"
		+ "The physician's runner delivered this message in haste. Fever had been seen aboard the ship, and certain travelers were ordered held under watch."
		+ "|||"
		+ "One name was marked with %s, yet the hand that wrote the departure roll treated the matter too lightly." % getSafeClue(clues, 0)
		+ "|||"
		+ "The tents required %s, but the road record still carried %s. That is not mercy. That is danger written in ink." % [getSafeClue(clues, 1), getSafeClue(clues, 2)]
		+ "|||"
		+ "Find the traveler whose body should have stopped the record from being cleared.\n\nSigned,\nPhysician Musa al-Iskandari"
	)


func buildFalsePilgrimMessage(_target: Dictionary, clues: Array) -> String:
	return (
		"To the keeper of pilgrim passage,\n\n"
		+ "A traveler arrived wearing humility like a cloak and asked for the mercy given to those bound for holy roads."
		+ "|||"
		+ "Yet the baggage spoke more loudly than the mouth. It carried %s, and the chapel roll did not receive him cleanly." % getSafeClue(clues, 1)
		+ "|||"
		+ "He claimed %s, but %s rested in the record like a hidden weight." % [getSafeClue(clues, 0), getSafeClue(clues, 2)]
		+ "|||"
		+ "Find the one whose holy claim bends beneath merchant evidence.\n\nSigned,\nBedros Hovhannisian"
	)


func buildReligiousWitnessMessage(_target: Dictionary, clues: Array) -> String:
	return (
		"To the servant who must hear witnesses through broken tongues,\n\n"
		+ "A dockhand remembered no written name, but he remembered the place of prayer where the person stood before the crowd shifted."
		+ "|||"
		+ "The place was %s. That detail was repeated twice, as if the witness feared you would mistake it for ordinary stone." % getSafeClue(clues, 0)
		+ "|||"
		+ "The prayer detail points toward %s, while the record should carry the same habit in its faith and people." % getSafeClue(clues, 1)
		+ "|||"
		+ "Find the entry whose prayer place and recorded identity speak the same truth.\n\nSigned,\nInterpreter Nasir al-Dimashqi"
	)


func buildCargoMessage(_target: Dictionary, clues: Array) -> String:
	return (
		"To the judge of wax and freight,\n\n"
		+ "The Venetians complain loudly, but this time the parchment complains with them."
		+ "|||"
		+ "A crate was said to be sealed, yet the mark upon the record shows %s." % getSafeClue(clues, 0)
		+ "|||"
		+ "The cargo note then speaks of %s. A clean inspection should not need such a correction after the seal is questioned." % getSafeClue(clues, 1)
		+ "|||"
		+ "Find the cargo entry whose seal and note cannot both be honest.\n\nSigned,\nMatteo of Acre"
	)


func buildFamilyLedgerMessage(_target: Dictionary, clues: Array) -> String:
	return (
		"To the keeper of copied family names,\n\n"
		+ "A ledger from the quarter of scribes came folded inside a cloth, as though the sender feared the name might vanish again."
		+ "|||"
		+ "The family form was remembered as %s. Such markings are not placed by accident." % getSafeClue(clues, 0)
		+ "|||"
		+ "The copied roll should have carried the person into the proper community, yet the line bears %s." % getSafeClue(clues, 1)
		+ "|||"
		+ "Find the record whose family identity remains visible while the ledger itself shows the wound.\n\nSigned,\nYehuda ben Aaron"
	)


func buildStorehouseMessage(_target: Dictionary, clues: Array) -> String:
	return (
		"To the examiner of keys,\n\n"
		+ "Blades vanished from a locked room, and men already blame the easiest hands near the quay."
		+ "|||"
		+ "The record speaks instead of %s, a passage that should not be ignored." % getSafeClue(clues, 0)
		+ "|||"
		+ "The place named was %s, and the key line carried %s. A thief needs a door before he needs courage." % [getSafeClue(clues, 1), getSafeClue(clues, 2)]
		+ "|||"
		+ "Find the entry whose access made the theft possible.\n\nSigned,\nHugh de Jaffa"
	)


func buildChapelQuarrelMessage(_target: Dictionary, clues: Array) -> String:
	return (
		"To the keeper placed between angry merchants,\n\n"
		+ "The chapel quarter is loud with accusation, but anger is not yet proof."
		+ "|||"
		+ "The witness placed the suspect at %s, though the accused swore another path." % getSafeClue(clues, 0)
		+ "|||"
		+ "The record carries %s. An alibi that breaks against a place is already half a confession." % getSafeClue(clues, 1)
		+ "|||"
		+ "Find the entry whose own witness account defeats its alibi.\n\nSigned,\nBedros Hovhannisian"
	)


func buildDiplomaticMessage(_target: Dictionary, clues: Array) -> String:
	return (
		"To the keeper of foreign courtesy,\n\n"
		+ "A letter bound for Jerusalem arrived under an imperial seal, and the envoy's patience thins by the hour."
		+ "|||"
		+ "The party list carries %s where it should stand firm." % getSafeClue(clues, 0)
		+ "|||"
		+ "The duty of %s was remembered, but a diplomatic party cannot travel safely when its escort record fails." % getSafeClue(clues, 1)
		+ "|||"
		+ "Find the attendant whose record threatens the envoy's passage.\n\nSigned,\nMatthaios Kallistos"
	)


func buildInterpreterMessage(_target: Dictionary, clues: Array) -> String:
	return (
		"To the keeper of order at the pier,\n\n"
		+ "A quarrel rose because words crossed badly between merchants and guards."
		+ "|||"
		+ "The needed tongue was %s, and the pier record expected a voice to carry it." % getSafeClue(clues, 0)
		+ "|||"
		+ "The entry says %s, but the status line answers %s. That absence is the heart of the quarrel." % [getSafeClue(clues, 1), getSafeClue(clues, 2)]
		+ "|||"
		+ "Find the interpreter recorded as needed but missing when called.\n\nSigned,\nRashid al-Suri"
	)


func buildMultipleMessageReport(levelData: Dictionary, clues: Array) -> String:
	var title := str(levelData.get("level_title", "case"))

	return (
		("To the final hand over this %s,\n\n" % title)
		+ "This message does not accuse one record alone. The corruption appears in several places, and careless reading will leave some of it behind."
		+ "|||"
		+ "The first marked thread is %s. The second is %s. When these appear together, the archive begins to darken." % [getSafeClue(clues, 0), getSafeClue(clues, 1)]
		+ "|||"
		+ "Watch also for %s. One false clearance may be a mistake, but several make a pattern." % getSafeClue(clues, 2)
		+ "|||"
		+ "Select every record touched by these signs. Do not stop at the first correct answer.\n\nSigned,\nThe Harbor Archive"
	)


func buildFallbackMessageReport() -> String:
	return (
		"To the servant of the archive,\n\n"
		+ "A troubled report has reached your desk."
		+ "|||"
		+ "The witnesses disagree, but the records still carry fragments of the truth."
		+ "|||"
		+ "Read the message carefully and follow the clues left in the parchment."
		+ "|||"
		+ "Find the record that agrees with the strongest signs."
	)


func buildHintsFromClues(levelData: Dictionary, cluePhrases: Array) -> Array:
	var selectionMode := str(levelData.get("selection_mode", "single"))

	if cluePhrases.is_empty():
		return [
			"The message hides the useful detail in plain sight.",
			"Read it again as a witness statement, not a summary.",
			"One line points more strongly than the others.",
			"The answer is the record that fits the strongest signs."
		]

	if selectionMode == "multiple":
		return [
			"The first marked words in the message reveal the kind of corruption you are hunting.",
			"The second marked thread shows that this is not a single accident.",
			"Several records may share the same stain. Do not stop early.",
			"The correct records are the ones carrying the marked danger signs together."
		]

	return [
		"The first marked words in the message are not decoration.",
		"The next marked phrase narrows the person more sharply.",
		"By now, the message is pointing at a particular kind of record.",
		"The marked clues should leave only one record that truly fits."
	]


func getSafeClue(clues: Array, index: int) -> String:
	if clues.is_empty():
		return "a troubling detail"

	if index < 0:
		return str(clues[0])

	if index >= clues.size():
		return str(clues[clues.size() - 1])

	return str(clues[index])


func getNameMemoryPhrase(record: Dictionary) -> String:
	var name := str(record.get("name", ""))

	match name:
		"Alexios":
			return "Alexander, shortened by Greek lips"
		"Yusuf":
			return "Joseph, carried in the local tongue"
		"Miriam":
			return "Miriam, a name the witness linked with old family prayers"
		"Aram":
			return "Aram, spoken like a northern name"
		"Guillaume":
			return "William, but in the Frankish manner"
		"Marco":
			return "Mark, sharpened by Venetian speech"
		"Stephanos":
			return "Stephen, spoken in the Greek way"
		"Tigran":
			return "Tigran, a hard mountain name"
		"Raymond":
			return "Raymond, a western knightly sound"
		"Niketas":
			return "Niketas, a name the Greeks carried proudly"

	if name.length() > 0:
		return "a name beginning with %s" % name.substr(0, 1)

	return "a half-remembered name"


func getSurnameMemoryPhrase(record: Dictionary) -> String:
	var surname := str(record.get("surname", ""))

	if surname.contains("ben "):
		return "a family name carried through the father"
	if surname.contains("bat "):
		return "a daughter-line name remembered by the scribes"
	if surname.contains("ibn "):
		return "a father's name in the older tongue"
	if surname.contains("de "):
		return "a western house name"
	if surname.contains("of "):
		return "a name tied to a place rather than a trade"

	if not surname.is_empty():
		return "a house name the clerk thought important"

	return "a damaged family name"


func getCultureMemoryPhrase(culture: String) -> String:
	match culture:
		"Armenian":
			return "roads near Cilicia and the Armenian quarter"
		"Arabic":
			return "the speech of the Arab coast"
		"Syrian":
			return "the northern caravan roads"
		"Egyptian":
			return "ships from the Nile road"
		"Hebrew":
			return "the careful house records of the Hebrew families"
		"Byzantine", "Greek":
			return "polished Greek speech from the eastern empire"
		"Venetian":
			return "the sharp habits of Venice"
		"Frankish", "Occitan":
			return "the custom of the western knights"
		"Persian":
			return "eastern silks and Persian speech"
		"Yemeni":
			return "the southern incense roads"
		"Turkic":
			return "horse traders from the eastern marches"

	return "an origin hidden in speech and company"


func getReligionMemoryPhrase(religion: String) -> String:
	match religion:
		"Muslim":
			return "the call to prayer and Allah's mercy"
		"Jewish":
			return "the scribes who keep the old names of Israel"
		"Catholic":
			return "Latin prayers and the western sign of the cross"
		"Orthodox":
			return "Greek prayers before the icons"
		"Armenian Apostolic":
			return "the Apostolic chapel of the Armenian faithful"

	return "a remembered manner of prayer"