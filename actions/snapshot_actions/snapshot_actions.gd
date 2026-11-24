class_name SnapshotActions extends Node

const OBJECT := "object"
const SOIL := "soil"
const FARM_SCENE_PATH := "res://levels/farm/farm_latest.tscn"

const WATER_COLLECTOR_ID := &"water_collector"
const WATER_PER_DAY := 10
const MAX_WATER := 30

static func collect_water() -> void:
	for cell: Vector2i in cells_with(OBJECT):
		var slot := get_slot(cell, OBJECT)
		if slot.get("id", &"") != WATER_COLLECTOR_ID or not slot.has("state"):
			continue
		var state: Dictionary = slot["state"]
		state["water_deposit"] = mini(int(state.get("water_deposit", 0)) + WATER_PER_DAY, MAX_WATER)

static func extinguish_fires() -> void:
	for cell: Vector2i in cells_with(OBJECT):
		var slot := get_slot(cell, OBJECT)
		if slot.get("id", &"") != &"bonfire" or not slot.has("state"):
			continue
		slot["state"]["is_on"] = false

static func populate(obj: WorldObject, state: Dictionary) -> Dictionary:
	var level_id := level_id_of(obj)
	if level_id.is_empty():
		return state
	var snapshot: Dictionary = GameState.snapshots.get_or_add(level_id, {})
	var cell := get_cell_from_pos(obj.global_position)
	var slot: Dictionary = snapshot.get(cell, {}).get(OBJECT, {})
	if slot.has("state"):
		return slot["state"]
	snapshot.get_or_add(cell, {})[OBJECT] = {"id": obj.data.id, "state": state}
	return state


static func remove(obj: WorldObject) -> void:
	var level_id := level_id_of(obj)
	if level_id.is_empty() or not obj.persistent:
		return
	var snapshot: Dictionary = GameState.snapshots.get(level_id, {})
	var cell := get_cell_from_pos(obj.global_position)
	var entry: Dictionary = snapshot.get(cell, {})
	entry.erase(OBJECT)
	if entry.is_empty():
		snapshot.erase(cell)


static func level_id_of(node: Node) -> String:
	var n := node
	while n != null and n is not BaseLevel:
		n = n.get_parent()
	return "" if n == null else String((n as BaseLevel).level_id)


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
	for cell: Vector2i in farm_snapshot():
		var soil := get_slot(cell, SOIL)
		if not soil.is_empty():
			soil["watered"] = false
			
static func spread() -> void:
	for cell: Vector2i in cells_with(OBJECT):
		var slot := get_slot(cell, OBJECT)
		var data := WorldObjectDB.get_data(slot.get("id", &""))
		if data == null or data.type != DataTypes.ObjectType.Nature or not slot.has("state"):
			continue
		if data is TreeObjectData:
			spread_tree(cell, slot, data)
			continue
		match data.id:
			&"grass", &"rock":
				spread_to_neighbors(cell, slot)

const SPREAD_CHANCE := 0.65
const NEIGHBOR_CHANCE := 0.25
const NEIGHBORS_4: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.UP]


static func spread_to_neighbors(cell: Vector2i, slot: Dictionary) -> void:
	if randf() >= SPREAD_CHANCE:
		return
	for dir in NEIGHBORS_4:
		var target := cell + dir
		if not is_spawnable(target) or randf() >= NEIGHBOR_CHANCE:
			continue
		set_slot(target, OBJECT, nature_entry(slot["id"]))


const TREE_SEED_CHANCE := 0.15
const TREE_SEED_RADIUS := 3
const NEIGHBORS_8: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]


static func spread_tree(cell: Vector2i, slot: Dictionary, data: TreeObjectData) -> void:
	if data.max_growth_stage == 0 or int(slot["state"].get("growth_stage", 0)) < data.max_growth_stage or randf() >= TREE_SEED_CHANCE:
		return
	var r := TREE_SEED_RADIUS
	var target := cell + Vector2i(randi_range(-r, r), randi_range(-r, r))
	if not is_spawnable(target):
		return
	set_slot(target, OBJECT, tree_entry(slot["id"], false))


static func spawn_nature(mature: bool) -> void:
	for cell: Vector2i in MapManager.farm_map:
		var table: Dictionary = MapManager.farm_map[cell].get("spawner", {})
		if table.is_empty() or not is_spawnable(cell):
			continue
		var entry := roll_nature(table, mature)
		if not entry.is_empty():
			set_slot(cell, OBJECT, entry)


static func roll_nature(table: Dictionary, mature: bool) -> Dictionary:
	match RandomNumberGenerator.new().rand_weighted(PackedFloat32Array(table["weights"])):
		0:
			var trees: Array = table["trees"]
			return {} if trees.is_empty() else tree_entry(trees.pick_random(), mature)
		1:
			return nature_entry(table["grass"])
		2:
			return nature_entry(table["rock"])
		3:
			return nature_entry(table["flower"])
		4:
			return nature_entry(table["blueberry"])
		5:
			return nature_entry(table["morel"])
		6:
			return nature_entry(table["chanterelle"])
	return {}


static func tree_entry(id: StringName, mature: bool) -> Dictionary:
	var data := WorldObjectDB.get_data(id) as TreeObjectData
	if data == null:
		return {}
	var stage := data.max_growth_stage if mature else 0
	return {"id": id, "state": {
		"health": data.health_at(stage),
		"growth_stage": stage,
		"days_until_harvest": data.days_until_harvest,
	}}


static func nature_entry(id: StringName) -> Dictionary:
	var data := WorldObjectDB.get_data(id)
	if data == null:
		return {}
	return {"id": id, "state": {
		"health": data.max_health,
		"variant": -1,
	}}


static func has_mature_tree_near(cell: Vector2i) -> bool:
	for dir in NEIGHBORS_8:
		var slot := get_slot(cell + dir, OBJECT)
		var data := WorldObjectDB.get_data(slot.get("id", &""))
		if data is TreeObjectData and int(slot.get("state", {}).get("growth_stage", 0)) >= data.max_growth_stage:
			return true
	return false


static func is_spawnable(cell: Vector2i) -> bool:
	if not farm_snapshot().get(cell, {}).is_empty():
		return false
	var tile: Dictionary = MapManager.farm_map.get(cell, {})
	if tile.is_empty() or tile["building"]:
		return false
	var layers: Array = tile["layers"]
	return layers.size() == 1 and layers[0] == String(CursorActions.BACK_LAYER) and tile["terrain"] in TileUtils.TILLABLE_TERRAINS


static func grow_objects() -> void:
	for cell: Vector2i in cells_with(OBJECT):
		var slot := get_slot(cell, OBJECT)
		var id: StringName = slot.get("id", "")
		var data := WorldObjectDB.get_data(id)
		if data == null or not slot.has("state"):
			continue
		if data.type == DataTypes.ObjectType.Crops:
			if get_slot(cell, SOIL).get("watered", false):
				CropObject.grow(slot["state"], data)
		elif data is TreeObjectData:
			TreeObject.grow(slot["state"], data, not has_mature_tree_near(cell))


static func cells_with(slot: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in farm_snapshot():
		if farm_snapshot()[cell].has(slot):
			cells.append(cell)
	return cells


static func get_slot(cell: Vector2i, slot: String) -> Dictionary:
	return farm_snapshot().get(cell, {}).get(slot, {})


static func set_slot(cell: Vector2i, slot: String, value: Dictionary) -> void:
	farm_snapshot().get_or_add(cell, {})[slot] = value


static func clear_slot(cell: Vector2i, slot: String) -> void:
	var entry: Dictionary = farm_snapshot().get(cell, {})
	entry.erase(slot)
	if entry.is_empty():
		farm_snapshot().erase(cell)


static func is_farm() -> bool:
	var scene := (Engine.get_main_loop() as SceneTree).current_scene
	return scene != null and scene.scene_file_path == FARM_SCENE_PATH


static func get_cell_from_pos(pos: Vector2) -> Vector2i:
	return Vector2i((pos / Constants.tile_size).floor())


static func get_pos_from_cell(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * Constants.tile_size + CursorActions.PLACED_BASE_OFFSET


static func farm_snapshot() -> Dictionary:
	return GameState.snapshots.get_or_add(GameState.FARM_LEVEL_ID, {})
