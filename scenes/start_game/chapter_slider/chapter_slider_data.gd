extends RefCounted

const TUTORIAL_HEADER: Texture2D = preload("res://assets/interface/ui/start_game/tutorial_header.png")
const TUTORIAL_ILLUSTRATION: Texture2D = preload("res://assets/interface/illustrations/ill_chapter_0.png")

const CHAPTER_1_HEADER: Texture2D = preload("res://assets/interface/ui/start_game/chapter_one_header.png")
const CHAPTER_2_HEADER: Texture2D = preload("res://assets/interface/ui/start_game/chapter_two_header.png")
const CHAPTER_3_HEADER: Texture2D = preload("res://assets/interface/ui/start_game/chapter_three_header.png")

const CHAPTER_1_ILLUSTRATION: Texture2D = preload("res://assets/interface/illustrations/ill_chapter_1.png")
const CHAPTER_2_ILLUSTRATION: Texture2D = preload("res://assets/interface/illustrations/ill_chapter_2.png")
const CHAPTER_3_ILLUSTRATION: Texture2D = preload("res://assets/interface/illustrations/ill_chapter_3.png")


static func getPages() -> Array[Dictionary]:
	return [
		{
			"id": "tutorial",
			"header": TUTORIAL_HEADER,
			"illustration": TUTORIAL_ILLUSTRATION,
			"title": "Tutorial",
			"description": "Before reaching the Port of Jaffa, the journey begins upon open waters, where the first lessons unfold aboard a weathered vessel bound for Jerusalem."
		},
		{
			"id": "chapter_1",
			"header": CHAPTER_1_HEADER,
			"illustration": CHAPTER_1_ILLUSTRATION,
			"title": "Level 1 / 15",
			"description": "At Jaffa, every arrival is recorded through customs ledgers, merchant manifests, and cargo inspections. Multiple overlapping records create inconsistencies in ownership and movement."
		},
		{
			"id": "chapter_2",
			"header": CHAPTER_2_HEADER,
			"illustration": CHAPTER_2_ILLUSTRATION,
			"title": "Level 16 / 30",
			"description": "Within Jerusalem, records form a dense civic system, tax registries, market transactions, and population archives interconnected across institutions."
		},
		{
			"id": "chapter_3",
			"header": CHAPTER_3_HEADER,
			"illustration": CHAPTER_3_ILLUSTRATION,
			"title": "Level 31 / 45",
			"description": "At the sacred center, the final records are sealed within restricted archives. Royal decrees, religious manuscripts, and hidden registries converge into a tightly controlled system of truth."
		}
	]