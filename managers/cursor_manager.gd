extends Node

# TODO: range in GLOBAL_VARS

const OBJECT_GROUP := &"object"
const PROPS_GROUP := &"props"
const CROP_INSTANCE := preload("res://scenes/objects/placables/crop_instance.tscn")
const OBJECT_INSTANCE := preload("res://scenes/objects/placables/object_instance.tscn")

var tilemap: TileMapLayer
# props - 지금 울타리만 박아둠. 모든 액션 불가가
# tilled_soil - 모든 행동 가능. seed 사용 가능. 물주면 watered_soil로 변경. place 시 사라짐 곡괭이 사용 시 dirt로 돌아감
# watered_soil - 모든 행동 가능. place 시 사라짐 곡괭이 상둉시 dirt로 돌아감. 날짜가 바뀌면 tilledSoil로 돌아감
# water - 모든 액션 불가
# TODO: city_ruins 정리안된 레이어 다 추가해야함
var tile_layers = ["TilledSoil", "WateredSoil", "Props", "Water", "Land"]

var player: Player
var player_feet: Node2D
var held: Item
var land: TileMapLayer
var water: TileMapLayer
var tilled_soil: TileMapLayer
var watered_soil: WateredSoilLayer
var objects_layer: Node2D
var _placeable_cache: Dictionary = {}


@export var place_ok_tint := Color(0.6, 1.0, 0.6, 0.6)
@export var place_blocked_tint := Color(1.0, 0.45, 0.45, 0.6)
@export var highlight_color := Color(0.3, 0.55, 1.0, 0.4)

var target_pos: Vector2
var is_locked := false

@onready var place_preview: Sprite2D = $PlacePreview
@onready var tile_highlight: Polygon2D = $TileHighlight


# mousepos 클릭 순간, mouse position 저장,
# 플레이어한테 애니메이션 finished 요청 왔을떄 해당 저장된 포지션으로 판별함

func _process(_delta: float) -> void:
	if player_feet == null or tilemap == null:
		tile_highlight.visible = false
		place_preview.visible = false
		return
	if not is_locked:
		held = Inventory.get_selected_item()
		target_pos = cell_center(clamp_to_reach(cell_of(player.get_global_mouse_position()), reach_of(held)))
	update_tile_highlight()
	update_place_preview()


func update_tile_highlight() -> void:
	if not highlights(held):
		tile_highlight.visible = false
		return
	var cell := cell_of(target_pos)
	var half := Vector2.ONE * GlobalVars.tile_size * 0.5
	tile_highlight.polygon = PackedVector2Array([
		-half, Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)
	])
	tile_highlight.global_transform = Transform2D(
		0.0, tilemap.global_transform.get_scale(), 0.0, cell_center(cell)
	)
	tile_highlight.color = highlight_color
	tile_highlight.visible = true


func update_place_preview() -> void:
	var object := placeable_of(held)
	if object == null:
		place_preview.visible = false
		return

	place_preview.texture = object.object_texture
	place_preview.centered = object.centered
	place_preview.offset = Vector2(object.offset)
	place_preview.scale = Vector2.ONE * object.sprite_scale
	place_preview.global_position = target_pos
	place_preview.modulate = place_ok_tint if can_place_at(object, target_pos) else place_blocked_tint
	place_preview.visible = true


func cell_of(point: Vector2) -> Vector2i:
	return Vector2i((tilemap.to_local(point) / GlobalVars.tile_size).floor())


func cell_center(cell: Vector2i) -> Vector2:
	return tilemap.to_global((Vector2(cell) + Vector2(0.5, 0.5)) * GlobalVars.tile_size)


func reach_of(item: Item) -> int:
	if placeable_of(item) != null:
		return GlobalVars.base_place_range / GlobalVars.tile_size
	return GlobalVars.tool_reach_tiles


func clamp_to_reach(cell: Vector2i, reach_tiles: int) -> Vector2i:
	var origin := cell_of(player_feet.global_position)
	var offset := Vector2(cell - origin)
	var reach := float(reach_tiles)
	var longest := maxf(absf(offset.x), absf(offset.y))
	if longest > reach:
		offset = (offset / longest * reach).round()
	return origin + Vector2i(offset)


func _unhandled_input(event: InputEvent) -> void:
	if player == null or tilemap == null or is_locked or player.is_freeze:
		return
	if event.is_action_pressed("hit"):
		if held == null:
			return
		if held.item_type == DataTypes.ItemType.Seeds:
			plant_seed(target_pos)
		elif held.item_type == DataTypes.ItemType.Placeable:
			place_object(target_pos)
		elif player.tool_layer.has_tool():
			is_locked = true
	elif event.is_action_pressed("interact"):
		interact(target_pos)


func _ready() -> void:
	# When Scene swap happend, cursor tilemap and layers terrains
	#
	SignalBus.level_loaded.connect(on_level_loaded)
	SignalBus.tool_used.connect(on_tool_used)
	# TODO: interact can be called after animation -> chest opening and such

func interact(point: Vector2) -> void:
	# search object to interact
	var object := get_object(point)
	if object != null:
		object.interact()
	else:
		player.consume_selected()


func is_tile_occupied(point: Vector2) -> bool:
	return get_object(point) != null


func get_object(point: Vector2) -> ObjectInstance:
	var cell := cell_of(point)
	for node in get_tree().get_nodes_in_group(OBJECT_GROUP):
		var instance := node as ObjectInstance
		if instance == null or instance.object == null or instance.is_queued_for_deletion():
			continue
		if cell_of(instance.global_position) == cell:
			return instance

	return null


func hit_target(point: Vector2) -> ObjectInstance:
	var closest: ObjectInstance = null
	var closest_distance := INF

	for node in get_tree().get_nodes_in_group(OBJECT_GROUP):
		var instance := node as ObjectInstance
		if instance == null or instance.object == null or instance.is_queued_for_deletion():
			continue

		var aim := instance.global_position + Vector2(instance.object.hurtbox_offset)
		var distance := aim.distance_to(point)
		if distance > float(instance.object.hurtbox_radius) or distance >= closest_distance:
			continue

		closest = instance
		closest_distance = distance

	return closest


func has_cell(layer: TileMapLayer, point: Vector2) -> bool:
	return layer != null and layer.get_cell_source_id(layer.local_to_map(layer.to_local(point))) != -1


func is_blocked(point: Vector2) -> bool:
	if has_cell(water, point):
		return true
	for node in get_tree().get_nodes_in_group(PROPS_GROUP):
		if has_cell(node as TileMapLayer, point):
			return true
	return false


func is_tillable(point: Vector2) -> bool:
	if land == null:
		return false
	var tile := land.get_cell_tile_data(land.local_to_map(land.to_local(point)))
	return tile != null and tile.get_custom_data(&"tillable")


# player animation ends
# this function only affects with tiles
func on_tool_used(tool: Item) -> void:
	if tool == null or tilemap == null or is_blocked(target_pos):
		is_locked = false
		return

	var target := hit_target(target_pos)
	if target != null and tool.tool_type != DataTypes.Tools.None:
		var knockback := player_feet.global_position.direction_to(target.global_position)
		if target.hurt_component.receive_hit(tool.tool_type, maxi(tool.melee_damage, 1), knockback):
			is_locked = false
			return

	match tool.tool_type:
		# watering can only affects tilled_soil, making them into watered soil
		DataTypes.Tools.WaterCrops:
			water_cell(target_pos)
		# pickaxe affects with ores, rocks, tilled soil
		DataTypes.Tools.MineRock:
			if get_object(target_pos) == null:
				untill_cell(target_pos)
		# hoe affects with dirt tile, making them tilled soil
		DataTypes.Tools.TillGround:
			if get_object(target_pos) == null and target == null:
				till_cell(target_pos)

	is_locked = false


func till_cell(point: Vector2) -> void:
	if tilled_soil == null or not is_tillable(point):
		return

	tilled_soil.set_cells_terrain_connect(
		[tilled_soil.local_to_map(tilled_soil.to_local(point))],
		DataTypes.SOIL_TERRAIN_SET, DataTypes.SoilTerrains.TilledDirt, true
	)
	SignalBus.sound_requested.emit(AudioManager.SFX_TILLING_GROUND)


func untill_cell(point: Vector2) -> void:
	if not has_cell(tilled_soil, point):
		return

	var cell := tilled_soil.local_to_map(tilled_soil.to_local(point))
	tilled_soil.set_cells_terrain_connect([cell], DataTypes.SOIL_TERRAIN_SET, -1, true)
	if watered_soil != null:
		watered_soil.dry_cell(cell)


func water_cell(point: Vector2) -> void:
	if watered_soil == null or not has_cell(tilled_soil, point):
		return

	watered_soil.water_cell(tilled_soil.local_to_map(tilled_soil.to_local(point)), tilled_soil)
	SignalBus.sound_requested.emit(AudioManager.SFX_WATERING_CROPS)

	var crop := get_object(point) as CropInstance
	if crop != null:
		crop.on_watered()


func plant_seed(point: Vector2) -> void:
	if objects_layer == null or held.crop_object == null or is_blocked(point):
		return
	if not has_cell(tilled_soil, point) or get_object(point) != null:
		return

	var crop := CROP_INSTANCE.instantiate() as CropInstance
	crop.object = held.crop_object
	crop.global_position = point
	objects_layer.add_child(crop)

	Inventory.remove_item(Inventory.selected_slot, 1)
	SignalBus.sound_requested.emit(AudioManager.SFX_TILLING_GROUND)


func place_object(point: Vector2) -> void:
	var object := placeable_of(held)
	if object == null or objects_layer == null or not can_place_at(object, point):
		return

	untill_cell(point)

	var placed := OBJECT_INSTANCE.instantiate() as ObjectInstance
	placed.object = object
	objects_layer.add_child(placed)
	placed.global_position = point

	Inventory.remove_item(Inventory.selected_slot, 1)
	SignalBus.sound_requested.emit(AudioManager.SFX_TILLING_GROUND)


func can_place_at(object: PlaceableObject, point: Vector2) -> bool:
	if get_object(point) != null or is_blocked(point):
		return false

	return not overlaps_player(object, point)


func overlaps_player(object: PlaceableObject, center: Vector2) -> bool:
	var hurt_box := player.get_node_or_null(^"HurtComponent") as HurtComponent
	if hurt_box == null:
		return false

	var circle := CircleShape2D.new()
	circle.radius = float(object.collision_radius)

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, center + Vector2(object.collision_offset))
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = hurt_box.collision_layer

	for hit in player.get_world_2d().direct_space_state.intersect_shape(query):
		if hit.collider == hurt_box:
			return true

	return false


func placeable_of(item: Item) -> PlaceableObject:
	if item == null or item.item_type != DataTypes.ItemType.Placeable:
		return null
	if item.placeable_object_path.is_empty():
		return null

	var path := item.placeable_object_path
	if not _placeable_cache.has(path):
		_placeable_cache[path] = load(path) as PlaceableObject
	return _placeable_cache[path]


func highlights(item: Item) -> bool:
	return item != null and (
		item.item_type == DataTypes.ItemType.Tool
		or item.item_type == DataTypes.ItemType.Seeds
	)


func on_level_loaded() -> void:
	player = get_tree().get_first_node_in_group(&"player")
	player_feet = player.get_node_or_null(^"CollisionShape2D") as Node2D if player != null else null
	is_locked = false
	var level = SaveAndLoad.current_level
	tilemap = level.get_node_or_null(^"Tilemap") as TileMapLayer if level != null else null
	land = tilemap.get_node_or_null(^"Land") as TileMapLayer if tilemap != null else null
	water = tilemap.get_node_or_null(^"Water") as TileMapLayer if tilemap != null else null
	tilled_soil = tilemap.get_node_or_null(^"TilledSoil") as TileMapLayer if tilemap != null else null
	watered_soil = tilemap.get_node_or_null(^"WateredSoil") as WateredSoilLayer if tilemap != null else null
	objects_layer = level.get_node_or_null(^"Level/Objects") as Node2D if level != null else null
