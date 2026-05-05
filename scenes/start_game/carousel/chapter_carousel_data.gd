extends RefCounted

const TUTORIAL_HEADER: Texture2D = preload("res://assets/interface/ui/start_game/tutorial_header.png")
const TUTORIAL_ILLUSTRATION: Texture2D = preload("res://assets/interface/illustrations/tutorial_illustration.png")

const CHAPTER_ONE_HEADER: Texture2D = preload("res://assets/interface/ui/start_game/chapter_one_header.png")
const CHAPTER_TWO_HEADER: Texture2D = preload("res://assets/interface/ui/start_game/chapter_two_header.png")
const CHAPTER_THREE_HEADER: Texture2D = preload("res://assets/interface/ui/start_game/chapter_three_header.png")

const CHAPTER_ONE_ILLUSTRATION: Texture2D = preload("res://assets/interface/illustrations/chapter_one_illustration.png")
const CHAPTER_TWO_ILLUSTRATION: Texture2D = preload("res://assets/interface/illustrations/chapter_two_illustration.png")
const CHAPTER_THREE_ILLUSTRATION: Texture2D = preload("res://assets/interface/illustrations/chapter_three_illustration.png")


static func get_pages() -> Array[Dictionary]:
	return [
		{
			"id": "tutorial",
			"header": TUTORIAL_HEADER,
			"illustration": TUTORIAL_ILLUSTRATION,
			"title": "Tutorial",
			"description": "Before reaching the Port of Jaffa, the journey begins upon open waters, where the first lessons unfold aboard a weathered vessel bound for Jerusalem."
		},
		{
			"id": "chapter_one",
			"header": CHAPTER_ONE_HEADER,
			"illustration": CHAPTER_ONE_ILLUSTRATION,
			"title": "Level 1 / 15",
			"description": "At Jaffa, every arrival is recorded through customs ledgers, merchant manifests, and cargo inspections. Multiple overlapping records create inconsistencies in ownership and movement."
		},
		{
			"id": "chapter_two",
			"header": CHAPTER_TWO_HEADER,
			"illustration": CHAPTER_TWO_ILLUSTRATION,
			"title": "Level 16 / 30",
			"description": "Within Jerusalem, records form a dense civic system, tax registries, market transactions, and population archives interconnected across institutions."
		},
		{
			"id": "chapter_three",
			"header": CHAPTER_THREE_HEADER,
			"illustration": CHAPTER_THREE_ILLUSTRATION,
			"title": "Level 31 / 45",
			"description": "At the sacred center, the final records are sealed within restricted archives. Royal decrees, religious manuscripts, and hidden registries converge into a tightly controlled system of truth."
		}
	]