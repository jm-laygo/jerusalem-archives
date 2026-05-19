DELETE FROM level_hints;
DELETE FROM level_answers;
DELETE FROM level_records;
DELETE FROM level_columns;
DELETE FROM levels;
DELETE FROM chapters;
DELETE FROM person_pool;

INSERT INTO chapters (chapter_id, chapter_title, chapter_description)
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
	target_role,
	success_text,
	failure_text,
	difficulty_tier
)
VALUES
(1, 1, 1, 'Missing Merchant',
'Identify the missing merchant hidden among the harbor records.',
'A clerk drags you into the harbor archive before your cloak has dried from the sea air. One merchant entry vanished before the departure roll was sealed. The witness remembers where the merchant was last seen, but not the name. Search the surviving records and restore the missing entry before the road to Jerusalem opens.',
'single', 1, 4, 240, 'generated', 'missing_merchant', 50, 'Merchant',
'The missing entry is restored before the harbor roll is sealed.',
'The roll is sealed with the wrong name still missing.',
1),

(2, 1, 2, 'Fever at the Quay',
'Find the traveler who should not have been cleared.',
'The fever bell rings from the quay after a ship arrives with sick passengers. The harbor physician orders the marked travelers held near the tents, yet one record shows a sick traveler cleared for departure. Find the record that should have remained under quarantine.',
'single', 1, 4, 230, 'generated', 'quarantine_clearance', 55, 'Any',
'The fevered traveler is stopped before reaching the Jerusalem road.',
'A sick traveler slips past the quay and disappears into the crowd.',
1),

(3, 1, 3, 'False Pilgrim Badge',
'Identify the false pilgrim in the harbor records.',
'A man wearing a pilgrim badge asks for inland passage, but the customs clerk finds trade weights and cargo slips among his baggage. Pilgrim rolls and customs records disagree. Find the traveler whose claim does not match the archive.',
'single', 1, 4, 230, 'generated', 'false_pilgrim', 55, 'Any',
'The false pilgrim is exposed before he avoids inspection.',
'The forged pilgrimage claim passes through the gate.',
1),

(4, 1, 4, 'Mosque Witness',
'Identify the record matching the witness account.',
'A dockhand gives testimony through a translator. He does not know the missing person''s name, only that the person was seen near the harbor mosque before prayer. Use the witness setting carefully and identify the matching record.',
'single', 1, 4, 230, 'generated', 'religious_witness', 55, 'Any',
'The witness account is matched to the correct archive entry.',
'The witness account is filed under the wrong person.',
1),

(5, 1, 5, 'Venetian Cargo Dispute',
'Find the suspicious cargo record.',
'Venetian traders accuse port guards of opening a sealed crate before inspection. The guards deny it, but one manifest was corrected after the seal was checked. Find the cargo record that carries the suspicious change.',
'single', 1, 4, 225, 'generated', 'cargo_dispute', 60, 'Any',
'The tampered cargo record is identified.',
'The dispute remains unresolved in the harbor ledger.',
1),

(6, 1, 6, 'Synagogue Ledger',
'Identify the missing person from the family ledger.',
'A family ledger from the Jewish quarter is brought to your desk. A woman''s name appears in one roll but disappears from another. The clue is not a direct name, but is hidden in family form and community records.','single', 1, 4, 220, 'generated', 'family_ledger', 60, 'Any',
'The family ledger is restored to the correct record.',
'The missing ledger entry remains unresolved.',
2),

(7, 1, 7, 'Frankish Storehouse',
'Identify the suspect with suspicious storehouse access.',
'A crate of Frankish blades disappears from a locked storehouse. The guard captain blames local workers, but the access list tells a different story. Find the record whose access does not belong.',
'single', 1, 4, 220, 'generated', 'storehouse_theft', 60, 'Any',
'The suspicious access record is found.',
'The stolen blades vanish from the storehouse record.',
2),

(8, 1, 8, 'Armenian Chapel Quarrel',
'Find the record that contradicts the alibi.',
'Armenian merchants demand justice after goods disappear near their chapel quarter. The accused porter claims he was elsewhere, but witness locations contradict the archive. Find the record that breaks the alibi.',
'single', 1, 4, 215, 'generated', 'chapel_quarrel', 65, 'Any',
'The false alibi is exposed.',
'The quarrel spreads through the merchant quarter.',
2),

(9, 1, 9, 'Byzantine Letter',
'Identify the missing diplomatic attendant.',
'A Byzantine emissary arrives with a sealed letter bound for Jerusalem. One attendant is missing from the diplomatic list, and the port cannot risk losing an imperial messenger. Find the record connected to the missing escort.',
'single', 1, 4, 215, 'generated', 'diplomatic_attendant', 65, 'Any',
'The diplomatic list is corrected before the emissary departs.',
'The missing attendant causes a diplomatic complaint.',
2),

(10, 1, 10, 'Missing Interpreter',
'Identify the missing interpreter.',
'Arabic-speaking merchants and Latin guards nearly come to blows after a mistranslated order. The assigned interpreter never reached the pier. Find the record showing who was assigned but absent.',
'single', 1, 4, 210, 'generated', 'missing_interpreter', 65, 'Any',
'The missing interpreter is identified before the quarrel worsens.',
'The dispute deepens without the right interpreter.',
2),

(11, 1, 11, 'Spoiled Grain Riot',
'Identify all suspicious grain records.',
'Rotten grain meant for the garrison sparks a fight at the customs scales. Several manifests were altered after inspection, and blame is shifting between ship captain, inspector, and porters. Select every grain record that shows suspicious tampering.',
'multiple', 3, 4, 260, 'generated', 'spoiled_grain', 75, 'Any',
'The altered grain records are separated from the clean manifests.',
'The riot spreads as forged grain records remain accepted.',
3),

(12, 1, 12, 'Safe-Conduct Envoy',
'Identify the records that threaten the safe-conduct list.',
'A Muslim envoy arrives under safe-conduct, and Frankish guards grow uneasy around his escort. One wrong record could turn courtesy into insult. Select every record with a dangerous mismatch in the safe-conduct list.',
'multiple', 3, 4, 260, 'generated', 'safe_conduct_envoy', 75, 'Any',
'The safe-conduct list is repaired before offense is given.',
'A diplomatic insult leaves the harbor archive stained.',
3),

(13, 1, 13, 'Dead Clerk Seal',
'Find every forged permit record.',
'A road permit bears the seal of a clerk who died days earlier. Several documents look official, but their dates and authorities cannot all be true. Select the forged permit records.',
'multiple', 2, 4, 255, 'generated', 'dead_clerk_seal', 70, 'Any',
'The forged permits are removed from the road bundle.',
'False permits pass toward Jerusalem.',
3),

(14, 1, 14, 'Caravan Spy',
'Identify the suspicious caravan records.',
'A caravan prepares to leave for Jerusalem. The commander suspects someone among the cleared travelers is hiding behind a false origin or mismatched testimony. Select the records whose claims do not align.',
'multiple', 3, 4, 270, 'generated', 'caravan_spy', 80, 'Any',
'The suspicious caravan records are stopped before departure.',
'A false traveler reaches the Jerusalem road.',
3),

(15, 1, 15, 'Final Clearance to Jerusalem',
'Identify every record wrongly cleared for Jerusalem.',
'Before the road opens, every cleared file must be reviewed. Sick travelers, forged permits, disputed cargo, and hidden warnings cannot pass inland. Select every record marked clear despite a warning sign.',
'multiple', 5, 4, 300, 'generated', 'final_clearance', 90, 'Any',
'The road opens with the dangerous records removed.',
'The road opens with corrupted files still marked clear.',
3);

UPDATE levels SET story =
'Newly landed servant of the archive, your first breath in Jaffa is not of rest, but of ink, salt, and accusation. The harbor does not wait for tired men.|||A merchant has vanished from the departure roll before the road to Jerusalem may open. The clerk swears the name was written. The sealed parchment says otherwise.|||The witness remembers no name, only the place where the merchant stood before disappearing into the crowd. Such places often reveal a man''s people, prayer, and company.|||Search the harbor records. Restore the missing merchant before the roll is sealed in error.'
WHERE level_id = 1;

UPDATE levels SET story =
'Keeper of the harbor roll, attend carefully. Sickness walks faster than pilgrims when men pretend not to see it.|||A ship has come to Jaffa with fever among its passengers. The physician marked those who must be held, yet one dangerous traveler was still cleared for departure.|||The name is not your first concern. Illness leaves marks in the record: health, quarantine, and permission to leave.|||Find the traveler whose clearance defies the physician''s order.'
WHERE level_id = 2;

UPDATE levels SET story =
'Faithful examiner of pilgrims, know this: not every badge worn near the quay belongs to a holy road.|||One traveler claims the mercy given to pilgrims, but his baggage speaks of trade: weights, slips, and goods meant for profit.|||A true pilgrim leaves a cleaner trail. Compare what he claims, what he carries, and whether his group truly receives him.|||Expose the false pilgrim before he passes inland under borrowed holiness.'
WHERE level_id = 3;

UPDATE levels SET story =
'Listen well, servant of the record, for some witnesses bring no names, only shadows.|||A dockhand speaks through a translator. He cannot name the missing person, but remembers the person near a place of prayer before the crowd broke apart.|||Prayer sites are not idle details. They point toward community, habit, and the faith written in the archive.|||Match the witness place to the proper record and name the one he saw.'
WHERE level_id = 4;

UPDATE levels SET story =
'Judge of seals and cargo marks, beware the merchant who shouts loudest, and the guard who answers too quickly.|||Venetian traders accuse the port watch of opening a sealed crate. The watch denies it, but the manifest was touched after inspection.|||A sound seal and a clean inspection should speak together. When seal, mark, and note disagree, the lie begins to show.|||Find the cargo record whose seal tells a different story from its inspection.'
WHERE level_id = 5;

UPDATE levels SET story =
'Patient keeper of family rolls, not all disappearances happen at sword point. Some are done with careless ink.|||A ledger from the Jewish quarter reaches your table. A woman is remembered by her house, yet missing from the copied harbor roll.|||Names of family are clues of their own. Daughter, son, house, and community may reveal what the damaged roll hides.|||Find the person whose family record should not have vanished.'
WHERE level_id = 6;

UPDATE levels SET story =
'Watchman of keys and night entries, theft is rarely done by the man blamed first.|||Frankish blades are missing from a locked storehouse. The captain points at dock workers, but the access list whispers otherwise.|||A thief needs more than desire. Look for night passage, a fitting place, and a key that should have returned.|||Find the record whose access makes the theft possible.'
WHERE level_id = 7;

UPDATE levels SET story =
'Keeper of quarrels, write slowly when anger enters the archive. Angry men often bring truth mixed with poison.|||Armenian merchants accuse a porter after goods vanish near their chapel quarter. The accused claims he stood elsewhere.|||Do not judge by accusation alone. Compare where witnesses place him against the alibi written in the record.|||Find the record where the alibi breaks under its own words.'
WHERE level_id = 8;

UPDATE levels SET story =
'Servant of the harbor seal, take care with imperial guests. A lost attendant may become a wounded alliance.|||A Byzantine emissary arrives bearing a sealed letter for Jerusalem. His party is counted, but one attendant is not properly accounted for.|||Diplomatic records depend on escort, seal, and duty. A missing listing among such people is no small clerical fault.|||Identify the attendant whose record threatens the envoy''s passage.'
WHERE level_id = 9;

UPDATE levels SET story =
'Interpreter of records, not tongues, you must still hear what confusion leaves behind.|||Arabic-speaking merchants and Latin guards nearly draw blades after an order is badly carried across languages. The interpreter assigned to the pier never appeared.|||The clue is not only language. Assignment, place, and status must agree if the record is honest.|||Find the interpreter who was expected, recorded, and absent.'
WHERE level_id = 10;

UPDATE levels SET story =
'Now the harbor grows louder, and one wrong record can feed a riot. Grain spoils faster than excuses.|||Rotten grain meant for the garrison has been found at the customs scales. Several manifests were altered after inspection.|||Spoilage alone is trouble, but spoilage joined with correction marks and disputed manifests suggests tampering. More than one record may be stained.|||Select every grain record that bears the mark of both rot and alteration.'
WHERE level_id = 11;

UPDATE levels SET story =
'Hold your hand steady, servant of the archive. Safe conduct is a promise, and broken promises make enemies.|||A Muslim envoy enters Jaffa under protection. Frankish guards distrust his escort, and the list before you carries dangerous inconsistencies.|||A protected guest must have a truthful escort, a sound seal, and no warning hidden beneath courtesy. More than one record may endanger the peace.|||Select every record that threatens the safe-conduct list.'
WHERE level_id = 12;

UPDATE levels SET story =
'Reader of seals, remember this: wax can lie when the dead are made to speak.|||A road permit bears the authority of a clerk already listed among the dead. Other permits look lawful, but their dates cannot all stand.|||Do not trust the seal alone. Compare the date, the authority, the clerk, and the status of the permit.|||Select every permit that could not have been honestly sealed.'
WHERE level_id = 13;

UPDATE levels SET story =
'Before dawn, the caravan gathers, and every traveler becomes a moving secret.|||The commander suspects one or more travelers of wearing false origins like borrowed cloaks. Their words and the archive do not fully agree.|||A lie may appear between claimed origin, recorded origin, witness match, and final clearance. More than one record may carry the same rot.|||Select the caravan records whose identities fail under comparison.'
WHERE level_id = 14;

UPDATE levels SET story =
'This is the final seal before Jerusalem. What passes your table may pass into the Holy City itself.|||The road opens at dawn, and all cleared files must be judged one last time. Some carry sickness, false permits, disputed marks, or warnings buried beneath approval.|||A dangerous record is not merely flawed. It is flawed and still cleared. Look for approval standing beside warning.|||Select every record wrongly cleared for the Jerusalem road.'
WHERE level_id = 15;

INSERT INTO level_columns (level_id, title, key, width_type, column_order) VALUES
(1, 'Record ID', 'record_id', 'normal', 1),
(1, 'Name', 'name', 'normal', 2),
(1, 'Surname', 'surname', 'long', 3),
(1, 'Culture', 'culture', 'normal', 4),
(1, 'Religion', 'religion', 'superlong', 5),
(1, 'Last Seen', 'last_seen', 'superlong', 6),

(2, 'Record ID', 'record_id', 'normal', 1),
(2, 'Name', 'name', 'normal', 2),
(2, 'Origin', 'origin', 'long', 3),
(2, 'Ship Name', 'ship_name', 'long', 4),
(2, 'Health Mark', 'health_mark', 'long', 5),
(2, 'Quarantine Status', 'quarantine_status', 'superlong', 6),
(2, 'Departure Status', 'departure_status', 'superlong', 7),

(3, 'Record ID', 'record_id', 'normal', 1),
(3, 'Name', 'name', 'normal', 2),
(3, 'Declared Role', 'declared_role', 'long', 3),
(3, 'Cargo', 'cargo', 'long', 4),
(3, 'Pilgrim Group', 'pilgrim_group', 'long', 5),
(3, 'Destination', 'destination', 'long', 6),
(3, 'Gate Pass', 'gate_pass', 'long', 7),

(4, 'Record ID', 'record_id', 'normal', 1),
(4, 'Name', 'name', 'normal', 2),
(4, 'Surname', 'surname', 'long', 3),
(4, 'Culture', 'culture', 'normal', 4),
(4, 'Religion', 'religion', 'superlong', 5),
(4, 'Prayer Site', 'prayer_site', 'superlong', 6),
(4, 'Last Seen', 'last_seen', 'superlong', 7),

(5, 'Record ID', 'record_id', 'normal', 1),
(5, 'Cargo Owner', 'cargo_owner', 'long', 2),
(5, 'Ship Name', 'ship_name', 'long', 3),
(5, 'Cargo Mark', 'cargo_mark', 'long', 4),
(5, 'Seal Condition', 'seal_condition', 'long', 5),
(5, 'Dock Clerk', 'dock_clerk', 'long', 6),
(5, 'Inspection Note', 'inspection_note', 'superlong', 7),

(6, 'Record ID', 'record_id', 'normal', 1),
(6, 'Name', 'name', 'normal', 2),
(6, 'Surname', 'surname', 'long', 3),
(6, 'Sex', 'sex', 'normal', 4),
(6, 'Family Line', 'family_line', 'long', 5),
(6, 'Religious Community', 'religious_community', 'superlong', 6),
(6, 'Ledger Status', 'ledger_status', 'long', 7),

(7, 'Record ID', 'record_id', 'normal', 1),
(7, 'Name', 'name', 'normal', 2),
(7, 'Role', 'role', 'long', 3),
(7, 'Night Access', 'night_access', 'normal', 4),
(7, 'Assigned Area', 'assigned_area', 'long', 5),
(7, 'Key Status', 'key_status', 'long', 6),
(7, 'Guard Post', 'guard_post', 'long', 7),

(8, 'Record ID', 'record_id', 'normal', 1),
(8, 'Name', 'name', 'normal', 2),
(8, 'Culture', 'culture', 'normal', 3),
(8, 'Warehouse Bay', 'warehouse_bay', 'long', 4),
(8, 'Witness Location', 'witness_location', 'superlong', 5),
(8, 'Alibi Status', 'alibi_status', 'long', 6),
(8, 'Dispute Reason', 'dispute_reason', 'superlong', 7),

(9, 'Record ID', 'record_id', 'normal', 1),
(9, 'Name', 'name', 'normal', 2),
(9, 'Role', 'role', 'long', 3),
(9, 'Envoy Origin', 'envoy_origin', 'long', 4),
(9, 'Diplomatic Seal', 'diplomatic_seal', 'long', 5),
(9, 'Escort Status', 'escort_status', 'long', 6),
(9, 'Letter Bearer', 'letter_bearer', 'long', 7),

(10, 'Record ID', 'record_id', 'normal', 1),
(10, 'Name', 'name', 'normal', 2),
(10, 'Language', 'language', 'long', 3),
(10, 'Assigned Pier', 'assigned_pier', 'long', 4),
(10, 'Interpreter Assigned', 'interpreter_assigned', 'superlong', 5),
(10, 'Status', 'status', 'long', 6),
(10, 'Witness Statement', 'witness_statement', 'superlong', 7),

(11, 'Record ID', 'record_id', 'normal', 1),
(11, 'Cargo', 'cargo', 'long', 2),
(11, 'Ship Name', 'ship_name', 'long', 3),
(11, 'Inspector', 'inspector', 'long', 4),
(11, 'Condition', 'condition', 'long', 5),
(11, 'Correction Mark', 'correction_mark', 'long', 6),
(11, 'Tax Clerk', 'tax_clerk', 'long', 7),
(11, 'Manifest Status', 'manifest_status', 'superlong', 8),

(12, 'Record ID', 'record_id', 'normal', 1),
(12, 'Name', 'name', 'normal', 2),
(12, 'Court Affiliation', 'court_affiliation', 'superlong', 3),
(12, 'Safe Conduct', 'safe_conduct', 'long', 4),
(12, 'Escort Name', 'escort_name', 'long', 5),
(12, 'Escort Status', 'escort_status', 'long', 6),
(12, 'Diplomatic Seal', 'diplomatic_seal', 'long', 7),
(12, 'Guard Warning', 'guard_warning', 'superlong', 8),

(13, 'Record ID', 'record_id', 'normal', 1),
(13, 'Name', 'name', 'normal', 2),
(13, 'Permit Type', 'permit_type', 'long', 3),
(13, 'Seal Date', 'seal_date', 'long', 4),
(13, 'Seal Authority', 'seal_authority', 'superlong', 5),
(13, 'Clerk', 'clerk', 'long', 6),
(13, 'Clerk Status', 'clerk_status', 'long', 7),
(13, 'Road Permit', 'road_permit', 'long', 8),

(14, 'Record ID', 'record_id', 'normal', 1),
(14, 'Name', 'name', 'normal', 2),
(14, 'Claimed Origin', 'claimed_origin', 'long', 3),
(14, 'Recorded Origin', 'recorded_origin', 'long', 4),
(14, 'Road Permit', 'road_permit', 'long', 5),
(14, 'Witness Match', 'witness_match', 'long', 6),
(14, 'Caravan', 'caravan', 'long', 7),
(14, 'Final Status', 'final_status', 'long', 8),

(15, 'Record ID', 'record_id', 'normal', 1),
(15, 'Name', 'name', 'normal', 2),
(15, 'Role', 'role', 'long', 3),
(15, 'Health Mark', 'health_mark', 'long', 4),
(15, 'Permit Status', 'permit_status', 'long', 5),
(15, 'Archive Mark', 'archive_mark', 'long', 6),
(15, 'Final Status', 'final_status', 'long', 7),
(15, 'Warning Note', 'warning_note', 'superlong', 8),
(15, 'Road Clearance', 'road_clearance', 'long', 9);

DELETE FROM level_hints;

INSERT INTO level_hints (level_id, hint_order, hint_text) VALUES
(1, 1, 'Open the case report and focus on the place where the merchant was last seen.'),
(1, 2, 'Last Seen should point toward a community or faith.'),
(1, 3, 'Compare Last Seen with Religion and Culture.'),
(1, 4, 'The correct record is the merchant whose identity fields agree with the witness place.'),

(2, 1, 'Look for a contradiction in the medical fields.'),
(2, 2, 'A Fevered traveler should not be allowed to depart.'),
(2, 3, 'Compare Health Mark, Quarantine Status, and Departure Status.'),
(2, 4, 'The answer is Fevered, Required, but still Cleared.'),

(3, 1, 'The false pilgrim is exposed by his belongings.'),
(3, 2, 'Compare Declared Role and Cargo first.'),
(3, 3, 'A Pilgrim with Trade Weights and no proper group is suspicious.'),
(3, 4, 'Find the record that claims holiness but carries merchant evidence.'),

(4, 1, 'The witness gave a place, not a name.'),
(4, 2, 'Prayer Site should agree with Religion.'),
(4, 3, 'Use the religious location to narrow the record.'),
(4, 4, 'The correct record matches the prayer place and religious community.'),

(5, 1, 'Start with Seal Condition.'),
(5, 2, 'A broken seal becomes suspicious when the inspection note was corrected.'),
(5, 3, 'Compare Seal Condition, Cargo Mark, and Inspection Note.'),
(5, 4, 'The answer is the crate whose seal and inspection do not agree.'),

(6, 1, 'This is a ledger identity problem.'),
(6, 2, 'Look at Sex, Family Line, and Religious Community.'),
(6, 3, 'Ledger Status should reveal the missing entry.'),
(6, 4, 'The correct record has a valid family identity but a broken ledger status.'),

(7, 1, 'The theft needed access.'),
(7, 2, 'Check Night Access before checking names.'),
(7, 3, 'Compare Night Access, Assigned Area, and Key Status.'),
(7, 4, 'The suspect had access to the storehouse and a key problem.'),

(8, 1, 'Ignore the accusation first. Compare the alibi.'),
(8, 2, 'Witness Location and Alibi Status are the main clues.'),
(8, 3, 'A contradicted alibi matters more than name or culture.'),
(8, 4, 'The answer is the record whose witness location breaks the alibi.'),

(9, 1, 'Start with Escort Status.'),
(9, 2, 'A diplomatic attendant should be properly listed.'),
(9, 3, 'Compare Diplomatic Seal, Escort Status, and Letter Bearer.'),
(9, 4, 'The correct record has diplomatic duty but is not properly accounted for.'),

(10, 1, 'Find someone assigned to help but absent.'),
(10, 2, 'Language and Assigned Pier should fit the incident.'),
(10, 3, 'Interpreter Assigned and Status must agree.'),
(10, 4, 'The answer is assigned Yes but Status Absent.'),

(11, 1, 'This level has multiple answers.'),
(11, 2, 'Spoiled grain alone is not enough. Look for tampering too.'),
(11, 3, 'Compare Condition, Correction Mark, and Manifest Status.'),
(11, 4, 'Select all Grain records that are Spoiled and Altered or Disputed.'),

(12, 1, 'This level has multiple answers.'),
(12, 2, 'Safe Conduct must match the escort record.'),
(12, 3, 'Guard Warning and Escort Status can expose the dangerous records.'),
(12, 4, 'Select all records with valid protection but mismatched or questioned escort details.'),

(13, 1, 'This level may have more than one forged permit.'),
(13, 2, 'Do not trust the seal alone.'),
(13, 3, 'Compare Seal Date with Clerk Status.'),
(13, 4, 'Select all records where a dead clerk appears to approve a later permit.'),

(14, 1, 'This level has multiple suspicious identities.'),
(14, 2, 'Compare Claimed Origin and Recorded Origin.'),
(14, 3, 'Witness Match should support the claimed identity.'),
(14, 4, 'Select all cleared records where origin and witness do not align.'),

(15, 1, 'This is the final review and has multiple answers.'),
(15, 2, 'Look for Warning Note or Archive Mark first.'),
(15, 3, 'Final Status and Road Clearance should not approve warned records.'),
(15, 4, 'Select every record that is warned but still cleared or approved.');

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
('Rivka', 'bat Natan', 'Hebrew', 'Jewish', 'Female', 'Merchant'),
('Anna', 'Komnene', 'Byzantine', 'Orthodox', 'Female', 'Merchant'),
('Amina', 'al-Masriya', 'Egyptian', 'Muslim', 'Female', 'Merchant'),
('Lucia', 'Contarini', 'Venetian', 'Catholic', 'Female', 'Merchant'),
('Anahid', 'Sarkisian', 'Armenian', 'Armenian Apostolic', 'Female', 'Merchant'),

('Hugh', 'de Jaffa', 'Frankish', 'Catholic', 'Male', 'Guard'),
('Odo', 'de Acre', 'Frankish', 'Catholic', 'Male', 'Guard'),
('Rashid', 'al-Suri', 'Syrian', 'Muslim', 'Male', 'Guard'),
('Basil', 'Argyros', 'Greek', 'Orthodox', 'Male', 'Guard'),

('Thomas', 'of Tyre', 'Frankish', 'Catholic', 'Male', 'Clerk'),
('Matthaios', 'Kallistos', 'Greek', 'Orthodox', 'Male', 'Clerk'),
('Yehuda', 'ben Aaron', 'Hebrew', 'Jewish', 'Male', 'Clerk'),
('Bedros', 'Hovhannisian', 'Armenian', 'Armenian Apostolic', 'Male', 'Clerk'),

('Nasir', 'al-Dimashqi', 'Syrian', 'Muslim', 'Male', 'Interpreter'),
('Raphael', 'ben Daniel', 'Hebrew', 'Jewish', 'Male', 'Interpreter'),
('Ioannes', 'Kantakouzenos', 'Byzantine', 'Orthodox', 'Male', 'Interpreter'),
('Samir', 'al-Halabi', 'Syrian', 'Muslim', 'Male', 'Interpreter'),

('Qasim', 'al-Yafi', 'Yemeni', 'Muslim', 'Male', 'Envoy'),
('Karim', 'al-Baghdadi', 'Persian', 'Muslim', 'Male', 'Envoy'),
('Demetrios', 'Lascaris', 'Greek', 'Orthodox', 'Male', 'Envoy'),

('Omar', 'ibn Said', 'Arabic', 'Muslim', 'Male', 'Porter'),
('Vahan', 'Sarkisian', 'Armenian', 'Armenian Apostolic', 'Male', 'Porter'),
('Luca', 'Gradenigo', 'Venetian', 'Catholic', 'Male', 'Porter'),

('Pierre', 'de Montpellier', 'Occitan', 'Catholic', 'Male', 'Pilgrim'),
('Isabella', 'de Jaffa', 'Frankish', 'Catholic', 'Female', 'Pilgrim'),
('Leah', 'bat Ezra', 'Hebrew', 'Jewish', 'Female', 'Pilgrim'),

('Musa', 'al-Iskandari', 'Egyptian', 'Muslim', 'Male', 'Inspector'),
('Andronikos', 'Angelos', 'Byzantine', 'Orthodox', 'Male', 'Inspector'),
('Enrico', 'Morosini', 'Venetian', 'Catholic', 'Male', 'Inspector');