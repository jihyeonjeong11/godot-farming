class_name CursorActions extends RefCounted

const TILE_SIZE: int = 32
const BASE_TILE_RANGE: int = 2
const BASE_PLACEMENT_RANGE: int = 4

const BACK_LAYER := &"Back"
const TILLED_LAYER := &"TilledSoil"
const TILE_LAYERS: Array[StringName] = [BACK_LAYER, TILLED_LAYER, &"WateredSoil", &"Floors", &"Buildings"]

const CURSOR_DEFAULT := preload("res://assets/UI/cursor/cursor_default.png")
const CURSOR_INTERACT := preload("res://assets/UI/cursor/cursor_interact.png")
const CURSOR_DEFAULT_HOTSPOT := Vector2(2, 2)
const CURSOR_INTERACT_HOTSPOT := Vector2(11, 2)

static var _cursor: Texture2D

const PICKAXE = preload("uid://boqllg37niafw")
const AXE = preload("uid://dclgtskcouocj")
const HOE = preload("uid://b5ll7oh7g02ah")
const WATERING_CAN = preload("uid://s3cy4shkem8o")

const CROP_OBJECT := preload("res://world_objects/crops/crop_object.tscn")
const CROP_BASE_OFFSET := Vector2(0, 6)

static func set_target_dict(origin: Vector2) -> void:
	set_target(origin)
	update_cursor()


static func update_cursor() -> void:
	var interactable := is_instance_valid(SessionState.target_dict["object"]) or is_at_door()
	var cursor: Texture2D = CURSOR_INTERACT if interactable else CURSOR_DEFAULT
	if cursor == _cursor:
		return
	_cursor = cursor
	Input.set_custom_mouse_cursor(cursor, Input.CURSOR_ARROW, CURSOR_INTERACT_HOTSPOT if interactable else CURSOR_DEFAULT_HOTSPOT)


static func set_target(origin: Vector2) -> void:
	var tilemap := current_land()
	if tilemap == null:
		SessionState.target_dict["pos"] = null
		SessionState.target_dict["layers"] = []
		SessionState.target_dict["tile"] = null
		SessionState.target_dict["terrain"] = ""
		SessionState.target_dict["object"] = null
		SessionState.target_dict["building"] = null
		return
	var mouse_pos: Vector2 = SessionState.mouse_pos
	var reach := reach_of(Inventory.get_selected_item())
	var cell := clamp_to_reach(cell_of(tilemap, mouse_pos), cell_of(tilemap, origin), reach)
	var pos := cell_center(tilemap, cell)
	var layers := layers_at(pos)
	SessionState.target_dict["pos"] = pos
	SessionState.target_dict["layers"] = layers
	SessionState.target_dict["tile"] = null if layers.is_empty() else layers.back()
	SessionState.target_dict["terrain"] = back_terrain(pos)
	var rect := cell_rect(tilemap, cell)
	SessionState.target_dict["object"] = object_at(rect)
	SessionState.target_dict["building"] = building_at(rect)


static func layers_at(pos: Vector2) -> Array[StringName]:
	var found: Array[StringName] = []
	for layer_name in TILE_LAYERS:
		var layer := level_layer(NodePath("Tilemap/%s" % layer_name))
		if layer != null and layer.get_cell_source_id(layer.local_to_map(layer.to_local(pos))) != -1:
			found.append(layer_name)
	if not found.has(BACK_LAYER):
		found.clear()
	return found


static func back_terrain(pos: Vector2) -> String:
	var back := level_layer(NodePath("Tilemap/%s" % BACK_LAYER))
	if back == null:
		return ""
	var layers: Array[TileMapLayer] = [back]
	return TileUtils.terrain_at(layers, pos)


static func cell_rect(tilemap: TileMapLayer, cell: Vector2i) -> Rect2:
	var size := Vector2.ONE * GlobalVars.tile_size
	return tilemap.global_transform * Rect2(Vector2(cell) * size, size)


static func object_at(area: Rect2) -> WorldObject:
	var found: WorldObject = null
	for node in (Engine.get_main_loop() as SceneTree).get_nodes_in_group(&"object"):
		var instance := node as WorldObject
		if instance == null or instance.data == null or instance.is_queued_for_deletion():
			continue
		var rect := instance.global_collision_rect()
		if not rect.has_area() or not rect.intersects(area):
			continue
		if found == null or instance.global_position.y > found.global_position.y:
			found = instance
	return found


static func object_in_cell(tilemap: TileMapLayer, cell: Vector2i, except: Node = null) -> WorldObject:
	for node in (Engine.get_main_loop() as SceneTree).get_nodes_in_group(&"object"):
		var instance := node as WorldObject
		if instance == null or instance == except or instance.is_queued_for_deletion():
			continue
		if cell_of(tilemap, instance.global_position) == cell:
			return instance
	return null


static func building_at(area: Rect2) -> Building:
	var found: Building = null
	for node in (Engine.get_main_loop() as SceneTree).get_nodes_in_group(Building.GROUP):
		var building := node as Building
		if building == null or building.is_queued_for_deletion():
			continue
		if not building.overlaps(area):
			continue
		if found == null or building.global_position.y > found.global_position.y:
			found = building
	return found


static func is_at_door() -> bool:
	var building = SessionState.target_dict["building"]
	var pos = SessionState.target_dict["pos"]
	if not is_instance_valid(building) or pos == null:
		return false
	var size := Vector2.ONE * GlobalVars.tile_size
	return (building as Building).door_overlaps(Rect2(pos - size * 0.5, size))


static func current_land() -> TileMapLayer:
	var level := (Engine.get_main_loop() as SceneTree).current_scene
	var tilemap := level.get_node_or_null(^"Tilemap") if level != null else null
	if tilemap == null:
		return null
	var land := tilemap.get_node_or_null(^"Land") as TileMapLayer
	if land != null:
		return land
	for child in tilemap.get_children():
		if child is TileMapLayer:
			return child
	return null


static func cell_of(tilemap: TileMapLayer, point: Vector2) -> Vector2i:
	return Vector2i((tilemap.to_local(point) / GlobalVars.tile_size).floor())


static func cell_center(tilemap: TileMapLayer, cell: Vector2i) -> Vector2:
	return tilemap.to_global((Vector2(cell) + Vector2(0.5, 0.5)) * GlobalVars.tile_size)


static func clamp_to_reach(cell: Vector2i, origin: Vector2i, reach_tiles: int) -> Vector2i:
	var offset := Vector2(cell - origin)
	var reach := float(reach_tiles)
	var longest := maxf(absf(offset.x), absf(offset.y))
	if longest > reach:
		offset = (offset / longest * reach).round()
	return origin + Vector2i(offset)


static func reach_of(item: Item) -> int:
	if placeable_of(item) != null:
		return BASE_PLACEMENT_RANGE
	return BASE_TILE_RANGE


static func placeable_of(item: Item) -> PlaceableObject:
	if item == null or item.item_type != DataTypes.ItemType.Placeable or item.placeable_object_path.is_empty():
		return null
	return load(item.placeable_object_path) as PlaceableObject

static func is_tillable() -> bool:
	var t := SessionState.target_dict
	# if pos blocked by an object, return false
	if t["pos"] == null or is_instance_valid(t["object"]) or is_instance_valid(t["building"]):
		return false
	# if pos cover by another layer or pos is not in terrain dirt, return false
	return t["tile"] == BACK_LAYER and t["terrain"] in TileUtils.TILLABLE_TERRAINS

static func is_axeable() -> bool:
	return target_accepts(DataTypes.Tools.AxeWood)


static func is_piaxeable() -> bool:
	return target_accepts(DataTypes.Tools.MineRock)


static func use_tool(item: Item) -> bool:
	if item == null or item.item_type != DataTypes.ItemType.Tool:
		return false
	match item.tool_type:
		DataTypes.Tools.AxeWood:
			if is_axeable():
				hit_target(item)
				SoundManager.play_sound(AXE)
				return true
		DataTypes.Tools.MineRock:
			if is_piaxeable():
				hit_target(item)
				SoundManager.play_sound(PICKAXE)
				return true
		DataTypes.Tools.TillGround:
			if is_tillable():
				till_target()
				SoundManager.play_sound(HOE)
				return true
		DataTypes.Tools.WaterCrops:
			if is_waterable():
				water_target()
				SoundManager.play_sound(WATERING_CAN)
				return true
		DataTypes.Tools.Seed:
			print('seed')
			#if is_plantable():
				#water_target()
				#SoundManager.play_sound(WATERING_CAN)
				# seed.reduce
			return true
	return false

static func is_waterable() -> bool:
	return SessionState.target_dict["tile"] == TILLED_LAYER

static func is_plantable() -> bool:
	var t := SessionState.target_dict
	if t["pos"] == null or is_instance_valid(t["object"]) or is_instance_valid(t["building"]):
		return false
	return t["layers"].has(TILLED_LAYER)


static func plant_seed(item: Item) -> void:
	var data := item.crop_object.duplicate() as WorldObjectData
	data.growth_stage = 0
	var crop := CROP_OBJECT.instantiate() as CropObject
	crop.data = data
	(Engine.get_main_loop() as SceneTree).current_scene.add_child(crop)
	crop.global_position = SessionState.target_dict["pos"] + CROP_BASE_OFFSET
	InventoryManager.remove_item(item, 1)
	SoundManager.play_sound(HOE)


static func hit_target(item: Item) -> void:
	(SessionState.target_dict["object"] as WorldObject).on_hit(item.tool_type, maxi(item.melee_damage, 1))


static func till_target() -> void:
	var soil := level_layer(^"Tilemap/TilledSoil")
	if soil == null:
		return
	var cell := soil.local_to_map(soil.to_local(SessionState.target_dict["pos"]))
	soil.set_cells_terrain_connect([cell], DataTypes.SOIL_TERRAIN_SET, DataTypes.SoilTerrains.TilledDirt, true)


static func water_target() -> void:
	var soil := level_layer(^"Tilemap/TilledSoil")
	var watered := level_layer(^"Tilemap/WateredSoil") as WateredSoilLayer
	watered.water_cell(soil.local_to_map(soil.to_local(SessionState.target_dict["pos"])), soil)


static func level_layer(path: NodePath) -> TileMapLayer:
	var level := (Engine.get_main_loop() as SceneTree).current_scene
	return level.get_node_or_null(path) as TileMapLayer if level != null else null


static func target_accepts(tool: DataTypes.Tools) -> bool:
	var t := SessionState.target_dict
	if t["pos"] == null or is_instance_valid(t["building"]):
		return false
	var object := t["object"] as WorldObject
	return is_instance_valid(object) and object.accepts_tool(tool)
