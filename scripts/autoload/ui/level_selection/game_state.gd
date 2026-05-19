extends Node

# Deprecated shim: keep this file so old references don't break.
# Forwards calls to the canonical autoload `LevelProgress`.

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	if get_node_or_null("/root/LevelProgress") == null:
		push_warning("Deprecated shim 'scripts/autoload/ui/level_selection/game_state.gd' is loaded but '/root/LevelProgress' is missing. Consider removing this file.")


func _get_level_progress_node():
	return get_node_or_null("/root/LevelProgress")


func getUnlockedLevel(chapterId: int) -> int:
	var lp = _get_level_progress_node()
	if lp == null:
		return 1
	return lp.call("getUnlockedLevel", chapterId)


func getStars(chapterId: int, levelNumber: int) -> int:
	var lp = _get_level_progress_node()
	if lp == null:
		return 0
	return lp.call("getStars", chapterId, levelNumber)


func completeLevel(chapterId: int, levelNumber: int, stars: int) -> void:
	var lp = _get_level_progress_node()
	if lp == null:
		return
	lp.call("completeLevel", chapterId, levelNumber, stars)