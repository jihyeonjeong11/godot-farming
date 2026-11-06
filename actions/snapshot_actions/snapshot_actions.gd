class_name SnapshotActions extends Node

const TILE_SIZE = 32

static func populate(object_pos: Vector2, id: String, state: Dictionary) -> Dictionary:
	var key := get_cell_from_pos(object_pos)
	var entry: Dictionary = GameState.farm_snapshot.get(key, {})
	if entry.has("state"):
		return entry["state"]
	create_snapshot_entry(key, id, state)
	return state

static func create_snapshot_entry(key: Vector2i, id: String, state: Dictionary) -> void:
	GameState.farm_snapshot[key] = {
		"id": id,
		"state": state
	}
	return
	
static func remove(pos: Vector2) -> void:
	GameState.farm_snapshot.erase(get_cell_from_pos(pos))


static func get_cell_from_pos(pos: Vector2) -> Vector2i:
	return Vector2i((pos / GlobalVars.tile_size).floor())


static func get_pos_from_cell(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * GlobalVars.tile_size + CursorActions.PLACED_BASE_OFFSET
