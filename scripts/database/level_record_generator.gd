extends RefCounted

const RECORD_ID_PREFIX := "R"

var db: Object
var random := RandomNumberGenerator.new()


# Stores the database connection used by the generator.
func _init(database: Object) -> void:
	db = database
	random.randomize()


# Generates a missing merchant level from database pools.
func generateMissingMerchantLevel(levelData: Dictionary) -> Dictionary:
	var targetRole: String = str(levelData.get("target_role", "Merchant"))
	var recordCount: int = int(levelData.get("record_count", 50))

	var people: Array = loadPeopleByRole(targetRole)

	if people.is_empty():
		push_error("No people found for role: %s" % targetRole)
		return levelData

	people.shuffle()

	var target: Dictionary = people[random.randi_range(0, people.size() - 1)].duplicate(true)
	var generatedRecords: Array = buildRecords(people, target, recordCount)
	var correctRecordId: String = str(target.get("record_id", ""))

	levelData["records"] = generatedRecords
	levelData["correct_record_id"] = correctRecordId
	levelData["correct_record_ids"] = [correctRecordId]
	levelData["objective"] = buildObjective(target)
	levelData["story"] = buildStory(target)
	levelData["hints"] = buildHints(target)

	return levelData


# Loads people from the database by role.
func loadPeopleByRole(roleName: String) -> Array:
	var success: bool = db.query_with_bindings(
		"SELECT name, surname, culture, religion, sex, role FROM person_pool WHERE role = ?;",
		[roleName]
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


# Builds generated table records and assigns record IDs.
func buildRecords(people: Array, target: Dictionary, recordCount: int) -> Array:
	var selectedPeople: Array = []
	selectedPeople.append(target)

	for person in people:
		if selectedPeople.size() >= recordCount:
			break

		if isSamePerson(person, target):
			continue

		selectedPeople.append(person.duplicate(true))

	selectedPeople.shuffle()

	var records: Array = []

	for index in range(selectedPeople.size()):
		var person: Dictionary = selectedPeople[index]
		var recordId: String = makeRecordId(index + 1)

		var record := {
			"record_id": recordId,
			"name": str(person.get("name", "")),
			"surname": str(person.get("surname", "")),
			"culture": str(person.get("culture", "")),
			"religion": str(person.get("religion", ""))
		}

		records.append(record)

		if isSamePerson(person, target):
			target["record_id"] = recordId

	return records


# Checks if two people are the same generated person.
func isSamePerson(a: Dictionary, b: Dictionary) -> bool:
	return (
		str(a.get("name", "")) == str(b.get("name", "")) and
		str(a.get("surname", "")) == str(b.get("surname", "")) and
		str(a.get("culture", "")) == str(b.get("culture", "")) and
		str(a.get("religion", "")) == str(b.get("religion", "")) and
		str(a.get("sex", "")) == str(b.get("sex", ""))
	)


# Creates R001, R002, R003 style IDs.
func makeRecordId(number: int) -> String:
	return "%s%03d" % [RECORD_ID_PREFIX, number]


# Builds a short objective for the level.
func buildObjective(_target: Dictionary) -> String:
	return "Identify the missing merchant hidden among the harbor records."


# Builds a subtle info/story text.
# This gives narrative evidence, not direct database answers.
func buildStory(target: Dictionary) -> String:
	var clueText: String = buildNarrativeClue(target)

	return "A merchant's entry vanished before the departure roll was sealed. %s Search the surviving records and identify which entry belongs to the missing case." % clueText


# Builds one indirect narrative clue based on culture/religion.
func buildNarrativeClue(target: Dictionary) -> String:
	var religion: String = str(target.get("religion", "")).to_lower()
	var culture: String = str(target.get("culture", "")).to_lower()

	if religion == "muslim":
		return "A dockhand last saw the merchant near the harbor mosque before the prayer call."

	if religion == "jewish":
		return "A clerk remembered the merchant near the synagogue scribes who kept family ledgers."

	if religion == "catholic":
		return "A guard recalled the merchant speaking with Latin pilgrims near the chapel by the quay."

	if religion == "orthodox":
		return "Witnesses placed the merchant near Greek-speaking clerics by the eastern quay."

	if religion == "armenian apostolic":
		return "A porter saw the merchant enter the quarter where Armenian traders kept chapel records."

	if culture == "venetian":
		return "The last witness mentioned a trader speaking in the manner of sailors from the western sea."

	if culture == "frankish" or culture == "occitan":
		return "The guards described the merchant as dressed in the fashion of western chivalric lands."

	if culture == "byzantine" or culture == "greek":
		return "A clerk remembered polished Greek speech among the merchant's companions."

	if culture == "syrian":
		return "The merchant was last seen speaking with traders from the northern caravan road."

	if culture == "egyptian":
		return "The merchant was linked to goods arriving from the southern Nile routes."

	if culture == "persian":
		return "A witness mentioned eastern silks and speech from lands beyond Mesopotamia."

	if culture == "turkic":
		return "A stablehand recalled the merchant among horse traders from the eastern marches."

	if culture == "armenian":
		return "The merchant was last seen near traders from the mountain roads of Cilicia."

	return "Only a witness fragment remains, pointing to habits and companions rather than a clear name."


# Builds progressive hints from broad to specific.
func buildHints(target: Dictionary) -> Array:
	var culture: String = str(target.get("culture", ""))
	var religion: String = str(target.get("religion", ""))
	var surname: String = str(target.get("surname", ""))

	return [
		"Start with the story clue, not the record ID.",
		"The witness clue points toward a merchant recorded as %s." % religion,
		"Narrow the list to the %s entries." % culture,
		"The surname begins with %s." % getSurnameLead(surname)
	]


# Returns a short leading clue from the surname.
func getSurnameLead(surname: String) -> String:
	if surname.length() <= 3:
		return surname

	return surname.substr(0, 3)