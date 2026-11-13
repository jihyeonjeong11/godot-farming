extends Node

const FARM_SCENE := "res://scenes/test_scenes/farm/farm_latest.tscn"


func _ready() -> void:
	build_farm_map()
	seed_farm()


func build_farm_map() -> void:
	var root := (load(FARM_SCENE) as PackedScene).instantiate()
	var back := root.get_node_or_null(NodePath("Tilemap/%s" % CursorActions.BACK_LAYER)) as TileMapLayer
	GameState.farm_map.clear()
	if back == null:
		root.free()
		return
	var tile_layers: Array[TileMapLayer] = []
	for layer_name in CursorActions.TILE_LAYERS:
		var layer := root.get_node_or_null(NodePath("Tilemap/%s" % layer_name)) as TileMapLayer
		if layer != null:
			tile_layers.append(layer)
	var building_rects: Array[Rect2] = []
	var spawners: Array[NatureSpawner] = []
	for node in root.find_children("*", "", true, false):
		if node is Building:
			building_rects.append_array(_building_rects(node, root))
		elif node is NatureSpawner:
			spawners.append(node)
	var size := Vector2.ONE * Constants.tile_size
	var back_xform := _to_root(back, root)
	for cell in back.get_used_cells():
		var pos := back_xform * back.map_to_local(cell)
		var layers: Array[String] = []
		for layer in tile_layers:
			if layer.get_cell_source_id(layer.local_to_map(_to_root(layer, root).affine_inverse() * pos)) != -1:
				layers.append(String(layer.name))
		var map_cell := SnapshotActions.get_cell_from_pos(pos)
		var area := Rect2(Vector2(map_cell) * Constants.tile_size, size)
		GameState.farm_map[map_cell] = {
			"terrain": _terrain_name(back, cell),
			"layers": layers,
			"building": building_rects.any(func(rect: Rect2) -> bool: return rect.intersects(area)),
		}
	for spawner in spawners:
		var cell := SnapshotActions.get_cell_from_pos(_to_root(spawner, root).origin)
		if GameState.farm_map.has(cell):
			GameState.farm_map[cell]["spawner"] = spawner.spawn_table()
	root.free()


func seed_farm() -> void:
	GameState.farm_snapshot = {}
	for cell: Vector2i in GameState.farm_map:
		if String(CursorActions.TILLED_LAYER) in GameState.farm_map[cell]["layers"]:
			SnapshotActions.set_slot(cell, SnapshotActions.SOIL, {"watered": false})
	SnapshotActions.spawn_nature(true)


func _terrain_name(layer: TileMapLayer, cell: Vector2i) -> String:
	var data := layer.get_cell_tile_data(cell)
	if data == null or data.terrain < 0:
		return ""
	return layer.tile_set.get_terrain_name(data.terrain_set, data.terrain)


func _building_rects(building: Building, root: Node) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for shape_node in [building.footprint_shape, building.door_shape]:
		var rect_shape := (shape_node.shape if shape_node != null else null) as RectangleShape2D
		if rect_shape == null:
			continue
		var rect: Rect2 = _to_root(shape_node, root) * Rect2(-rect_shape.size * 0.5, rect_shape.size)
		if rect.has_area():
			rects.append(rect)
	return rects


func _to_root(node: Node, root: Node) -> Transform2D:
	var xform := Transform2D.IDENTITY
	while node != null and node != root:
		if node is Node2D:
			xform = (node as Node2D).transform * xform
		node = node.get_parent()
	return xform
