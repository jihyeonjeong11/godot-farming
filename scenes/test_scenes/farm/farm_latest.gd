extends Base_level


func _enter() -> void:
	build_farm_map()
	restore_snapshot_tiles()
	restore_snapshot_objects()


func build_farm_map() -> void:
	if not GameState.farm_map.is_empty():
		return
	var back := get_node_or_null(^"Tilemap/Back") as TileMapLayer
	if back == null:
		return
	var back_layers: Array[TileMapLayer] = [back]
	var tile_layers: Array[TileMapLayer] = []
	for layer_name in CursorActions.TILE_LAYERS:
		var layer := get_node_or_null(NodePath("Tilemap/%s" % layer_name)) as TileMapLayer
		if layer != null:
			tile_layers.append(layer)
	var buildings := get_tree().get_nodes_in_group(Building.GROUP)
	var size := Vector2.ONE * Constants.tile_size
	for cell in back.get_used_cells():
		var pos := (Vector2(cell) + Vector2(0.5, 0.5)) * Constants.tile_size
		var layers: Array[String] = []
		for layer in tile_layers:
			if layer.get_cell_source_id(layer.local_to_map(layer.to_local(pos))) != -1:
				layers.append(String(layer.name))
		var area := Rect2(Vector2(cell) * Constants.tile_size, size)
		var has_building := buildings.any(func(b: Node) -> bool: return b is Building and b.overlaps(area))
		GameState.farm_map[cell] = {
			"terrain": TileUtils.terrain_at(back_layers, pos),
			"layers": layers,
			"building": has_building,
		}


func restore_snapshot_tiles() -> void:
	var tilled := get_node_or_null(^"Tilemap/TilledSoil") as TileMapLayer
	var watered := get_node_or_null(^"Tilemap/WateredSoil") as WateredSoilLayer
	if tilled == null or watered == null:
		return
	if not GameState.farm_soil_seeded:
		for cell in tilled.get_used_cells():
			SnapshotActions.till(cell)
		GameState.farm_soil_seeded = true
		return
	tilled.clear()
	var soil_cells := SnapshotActions.cells_with(SnapshotActions.SOIL)
	tilled.set_cells_terrain_connect(soil_cells, DataTypes.SOIL_TERRAIN_SET, DataTypes.SoilTerrains.TilledDirt, true)
	for cell in soil_cells:
		if SnapshotActions.get_slot(cell, SnapshotActions.SOIL).get("watered", false):
			watered.water_cell(cell, tilled)


func restore_snapshot_objects() -> void:
	var occupied := {}
	for node in get_tree().get_nodes_in_group(&"object"):
		if node is not NatureSpawner:
			occupied[SnapshotActions.get_cell_from_pos(node.global_position)] = true
	for cell: Vector2i in SnapshotActions.cells_with(SnapshotActions.OBJECT):
		var id: String = SnapshotActions.get_slot(cell, SnapshotActions.OBJECT).get("id", "")
		if id.is_empty() or occupied.has(cell):
			continue
		var object := WorldObjectDB.create(id)
		if object == null:
			continue
		object.position = SnapshotActions.get_pos_from_cell(cell)
		add_child(object)
