class_name GridActions extends Node

const TILLED_PATH := ^"Tilemap/TilledSoil"
const WATERED_PATH := ^"Tilemap/WateredSoil"
const NATURE_PATH := ^"NatureSpawners"


static func snapshot() -> Dictionary:
	var grid := {}
	var tilled := CursorActions.level_layer(TILLED_PATH)
	var watered := CursorActions.level_layer(WATERED_PATH)
	if tilled == null or watered == null:
		return grid
	_capture_layer(grid, tilled, "tilled")
	_capture_layer(grid, watered, "watered")
	_capture_children(grid, tilled, _level())
	_capture_children(grid, tilled, _level().get_node_or_null(NATURE_PATH))
	return grid


static func restore(grid: Dictionary) -> void:
	var tilled := CursorActions.level_layer(TILLED_PATH)
	var watered := CursorActions.level_layer(WATERED_PATH)
	if tilled == null or watered == null or grid.is_empty():
		return
	tilled.clear()
	watered.clear()
	for cell: Vector2i in grid:
		var entry: Dictionary = grid[cell]
		if entry.has("tilled"):
			_apply_tile(tilled, cell, entry["tilled"])
		if entry.has("watered"):
			_apply_tile(watered, cell, entry["watered"])
		if entry.has("object"):
			_spawn_object(entry["object"])


static func _level() -> Node:
	return (Engine.get_main_loop() as SceneTree).current_scene


static func _capture_layer(grid: Dictionary, layer: TileMapLayer, key: String) -> void:
	for cell in layer.get_used_cells():
		grid.get_or_add(cell, {})[key] = {
			"source": layer.get_cell_source_id(cell),
			"atlas": layer.get_cell_atlas_coords(cell),
			"alternative": layer.get_cell_alternative_tile(cell),
		}


static func _capture_children(grid: Dictionary, tilled: TileMapLayer, parent: Node) -> void:
	if parent == null:
		return
	for child in parent.get_children():
		var object := child as WorldObject
		if object == null or object.owner != null or object.is_queued_for_deletion():
			continue
		var cell := tilled.local_to_map(tilled.to_local(object.global_position))
		grid.get_or_add(cell, {})["object"] = {
			"scene": object.scene_file_path,
			"data": object.data,
			"parent": String(_level().get_path_to(parent)),
			"position": object.position,
			"state": object.capture_state(),
		}


static func _apply_tile(layer: TileMapLayer, cell: Vector2i, tile: Dictionary) -> void:
	layer.set_cell(cell, tile["source"], tile["atlas"], tile["alternative"])


static func _spawn_object(entry: Dictionary) -> void:
	var object := (load(entry["scene"]) as PackedScene).instantiate() as WorldObject
	object.data = entry["data"]
	object.apply_state(entry["state"])
	_level().get_node(entry["parent"]).add_child(object)
	object.position = entry["position"]
