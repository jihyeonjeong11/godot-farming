class_name CursorActions extends RefCounted

const TILE_SIZE: int = 32
const BASE_TILE_RANGE: int = 2
const BASE_PLACEMENT_RANGE: int = 4

const CURSOR_DEFAULT := preload("res://assets/UI/cursor/cursor_default.png")
const CURSOR_INTERACT := preload("res://assets/UI/cursor/cursor_interact.png")
const CURSOR_DEFAULT_HOTSPOT := Vector2(2, 2)
const CURSOR_INTERACT_HOTSPOT := Vector2(16, 16)

static var _cursor: Texture2D

static func set_target_dict(origin: Vector2) -> void:
	set_target(origin)
	update_cursor()


static func update_cursor() -> void:
	var interactable := is_instance_valid(SessionState.target_dict["object"])
	var cursor: Texture2D = CURSOR_INTERACT if interactable else CURSOR_DEFAULT
	if cursor == _cursor:
		return
	_cursor = cursor
	Input.set_custom_mouse_cursor(cursor, Input.CURSOR_ARROW, CURSOR_INTERACT_HOTSPOT if interactable else CURSOR_DEFAULT_HOTSPOT)


static func set_target(origin: Vector2) -> void:
	var tilemap := current_land()
	if tilemap == null:
		SessionState.target_dict["pos"] = null
		SessionState.target_dict["tile"] = null
		SessionState.target_dict["object"] = null
		return
	var mouse_pos: Vector2 = SessionState.mouse_pos
	var reach := reach_of(Inventory.get_selected_item())
	var cell := clamp_to_reach(cell_of(tilemap, mouse_pos), cell_of(tilemap, origin), reach)
	var pos := cell_center(tilemap, cell)
	var level := (Engine.get_main_loop() as SceneTree).current_scene
	SessionState.target_dict["pos"] = pos
	SessionState.target_dict["tile"] = TileUtils.terrain_at(TileUtils.ground_layers(level), pos)
	SessionState.target_dict["object"] = object_at(cell_rect(tilemap, cell))


static func cell_rect(tilemap: TileMapLayer, cell: Vector2i) -> Rect2:
	var size := Vector2.ONE * GlobalVars.tile_size
	return tilemap.global_transform * Rect2(Vector2(cell) * size, size)


static func object_at(area: Rect2) -> ObjectInstance:
	var found: ObjectInstance = null
	for node in (Engine.get_main_loop() as SceneTree).get_nodes_in_group(&"object"):
		var instance := node as ObjectInstance
		if instance == null or instance.object == null or instance.is_queued_for_deletion():
			continue
		if not instance.global_interact_rect().intersects(area):
			continue
		if found == null or instance.global_position.y > found.global_position.y:
			found = instance
	return found


static func current_land() -> TileMapLayer:
	var level := (Engine.get_main_loop() as SceneTree).current_scene
	return level.get_node_or_null(^"Tilemap/Land") as TileMapLayer if level != null else null


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
