extends Base_level


func _enter() -> void:
	restore_snapshot_tiles()
	restore_snapshot_objects()


func restore_snapshot_tiles() -> void:
	var tilled := get_node_or_null(^"Tilemap/TilledSoil") as TileMapLayer
	var watered := get_node_or_null(^"Tilemap/WateredSoil") as WateredSoilLayer
	if tilled == null or watered == null:
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
		if object.data.initial_scale != Vector2.ZERO:
			object.scale = object.data.initial_scale
		add_child(object)
