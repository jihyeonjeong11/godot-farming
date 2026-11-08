class_name SnapshotActions extends Node

const OBJECT := "object"
const SOIL := "soil"
const FARM_SCENE_PATH := "res://scenes/test_scenes/farm/farm_latest.tscn"


static func populate(object_pos: Vector2, id: String, state: Dictionary) -> Dictionary:
	var cell := get_cell_from_pos(object_pos)
	var slot := get_slot(cell, OBJECT)
	if slot.has("state"):
		return slot["state"]
	set_slot(cell, OBJECT, {"id": id, "state": state})
	return state


static func remove(pos: Vector2) -> void:
	clear_slot(get_cell_from_pos(pos), OBJECT)


static func till(cell: Vector2i) -> void:
	if not is_farm() or not get_slot(cell, SOIL).is_empty():
		return
	set_slot(cell, SOIL, {"watered": false})


static func water(cell: Vector2i) -> void:
	if not is_farm():
		return
	var soil := get_slot(cell, SOIL)
	if not soil.is_empty():
		soil["watered"] = true


static func dry_all_soil() -> void:
	for cell: Vector2i in GameState.farm_snapshot:
		var soil := get_slot(cell, SOIL)
		if not soil.is_empty():
			soil["watered"] = false


static func cells_with(slot: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in GameState.farm_snapshot:
		if GameState.farm_snapshot[cell].has(slot):
			cells.append(cell)
	return cells


static func get_slot(cell: Vector2i, slot: String) -> Dictionary:
	return GameState.farm_snapshot.get(cell, {}).get(slot, {})


static func set_slot(cell: Vector2i, slot: String, value: Dictionary) -> void:
	GameState.farm_snapshot.get_or_add(cell, {})[slot] = value


static func clear_slot(cell: Vector2i, slot: String) -> void:
	var entry: Dictionary = GameState.farm_snapshot.get(cell, {})
	entry.erase(slot)
	if entry.is_empty():
		GameState.farm_snapshot.erase(cell)


static func is_farm() -> bool:
	var scene := (Engine.get_main_loop() as SceneTree).current_scene
	return scene != null and scene.scene_file_path == FARM_SCENE_PATH


static func get_cell_from_pos(pos: Vector2) -> Vector2i:
	return Vector2i((pos / Constants.tile_size).floor())


static func get_pos_from_cell(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * Constants.tile_size + CursorActions.PLACED_BASE_OFFSET
