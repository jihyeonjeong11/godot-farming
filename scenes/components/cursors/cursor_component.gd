extends Node2D

const OBJECT_GROUP := &"object"
const PROPS_GROUP := &"props"
const CROP_INSTANCE := preload("res://scenes/objects/placables/crop_instance.tscn")
const OBJECT_INSTANCE := preload("res://scenes/objects/placables/object_instance.tscn")


@export var tilemap: TileMapLayer
@export var tilled_soil_tilemap_layer: TileMapLayer
@export var crops_layer: Node2D
@export var terrain_set: int = DataTypes.SOIL_TERRAIN_SET
@export var terrain: int = DataTypes.SoilTerrains.TilledDirt
@export var interaction_range: float = 88.0
@export var place_ok_tint := Color(0.6, 1.0, 0.6, 0.6)
@export var place_blocked_tint := Color(1.0, 0.45, 0.45, 0.6)

var mouse_position: Vector2
var target_position: Vector2
var cell_position: Vector2i
var object_target: ObjectInstance
var props_target: TileMapLayer
var held: Item
var _placeable_cache: Dictionary = {}

@onready var place_preview: Sprite2D = $PlacePreview

@onready var player: Node2D = get_tree().get_first_node_in_group(&"player")
@onready var watered_soil_layer: WateredSoilLayer = (
	get_tree().get_first_node_in_group(WateredSoilLayer.GROUP) as WateredSoilLayer
)

func _physics_process(_delta: float) -> void:
	mouse_position = get_global_mouse_position()
	target_position = clamp_to_reach(mouse_position)
	global_position = target_position
	cell_position = cell_under_cursor()
	object_target = object_under_cursor()
	props_target = props_under_cursor()
	held = Inventory.get_selected_item()

	update_place_preview()

	if GameInputEvents.interact():
		if object_target != null:
			object_target.interact()
		elif player != null:
			player.consume_selected()
		return

	if GameInputEvents.is_use_tool():
		if not uses_cursor(held):
			return
		# 1. 먼저 오브젝트 좌표계 열람, 오브젝트 있는지 확인
		# 있다면 여기엔 설치되거나 hoe를 사용할 수 없음.
		if held.tool_type == DataTypes.Tools.WaterCrops:
			water_cell()
			return

		if held.item_type == DataTypes.ItemType.Seeds:
			plant_seed()
			return

		if held.item_type == DataTypes.ItemType.Placeable:
			place_object()
			return

		if object_target != null:
			return

		if held.tool_type == DataTypes.Tools.TillGround:
			if props_target == null and object_at_cell() == null:
				till_cell()
		if held.tool_type == DataTypes.Tools.MineRock:
			untill_cell()


func till_cell() -> void:
	if tilemap == null or tilled_soil_tilemap_layer == null:
		return

	if not is_cell_dirt():
		return

	tilled_soil_tilemap_layer.set_cells_terrain_connect(
		[cell_position], terrain_set, terrain, true
	)
	SignalBus.sound_requested.emit(AudioManager.SFX_TILLING_GROUND)


func untill_cell() -> void:
	if tilled_soil_tilemap_layer == null:
		return

	if tilled_soil_tilemap_layer.get_cell_source_id(cell_position) == -1:
		return

	tilled_soil_tilemap_layer.set_cells_terrain_connect(
		[cell_position], terrain_set, -1, true
	)
	if watered_soil_layer != null:
		watered_soil_layer.dry_cell(cell_position)


func plant_seed() -> void:
	if tilemap == null or tilled_soil_tilemap_layer == null or crops_layer == null:
		return

	if held.crop_object == null:
		return

	if tilled_soil_tilemap_layer.get_cell_source_id(cell_position) == -1:
		return

	if crop_at_cell() != null:
		return

	var crop := CROP_INSTANCE.instantiate() as CropInstance
	crop.object = held.crop_object
	crop.global_position = tilemap.to_global(tilemap.map_to_local(cell_position))
	crops_layer.add_child(crop)

	Inventory.remove_item(Inventory.selected_slot, 1)
	SignalBus.sound_requested.emit(AudioManager.SFX_TILLING_GROUND)


func place_object() -> void:
	var object := placeable_of(held)
	if object == null or tilemap == null or crops_layer == null:
		return

	var cell := place_cell()
	var center := tilemap.to_global(tilemap.map_to_local(cell))
	if not can_place_at(object, cell, center):
		return

	var placed := OBJECT_INSTANCE.instantiate() as ObjectInstance
	placed.object = object
	crops_layer.add_child(placed)
	placed.global_position = center

	Inventory.remove_item(Inventory.selected_slot, 1)
	SignalBus.sound_requested.emit(AudioManager.SFX_TILLING_GROUND)


func is_cell_dirt() -> bool:
	var tile := tilemap.get_cell_tile_data(cell_position)
	return tile != null and tile.get_custom_data(&"tillable")


func object_at_cell(cell: Vector2i = cell_position) -> ObjectInstance:
	for node in get_tree().get_nodes_in_group(OBJECT_GROUP):
		var instance := node as ObjectInstance
		if instance == null or instance.is_queued_for_deletion():
			continue

		if tilemap.local_to_map(tilemap.to_local(instance.global_position)) == cell:
			return instance

	return null


func crop_at_cell(cell: Vector2i = cell_position) -> CropInstance:
	if crops_layer == null:
		return null

	for child in crops_layer.get_children():
		var crop := child as CropInstance
		if crop == null or crop.is_queued_for_deletion():
			continue

		if tilemap.local_to_map(tilemap.to_local(crop.global_position)) == cell:
			return crop

	return null


func props_at(point: Vector2) -> TileMapLayer:
	for node in get_tree().get_nodes_in_group(PROPS_GROUP):
		var layer := node as TileMapLayer
		if layer == null:
			continue

		if layer.get_cell_source_id(layer.local_to_map(layer.to_local(point))) != -1:
			return layer

	return null


func update_place_preview() -> void:
	var object := placeable_of(held)
	if object == null or tilemap == null:
		place_preview.visible = false
		return

	var cell := place_cell()
	var center := tilemap.to_global(tilemap.map_to_local(cell))

	place_preview.texture = object.object_texture
	place_preview.centered = object.centered
	place_preview.offset = Vector2(object.offset)
	place_preview.scale = Vector2.ONE * object.sprite_scale
	place_preview.global_position = center
	place_preview.modulate = place_ok_tint if can_place_at(object, cell, center) else place_blocked_tint
	place_preview.visible = true


func place_cell() -> Vector2i:
	var point := clamp_to_reach(mouse_position, float(GlobalVars.base_place_range))
	return tilemap.local_to_map(tilemap.to_local(point))


func can_place_at(object: PlaceableObject, cell: Vector2i, center: Vector2) -> bool:
	if object_at_cell(cell) != null or crop_at_cell(cell) != null or props_at(center) != null:
		return false

	return not overlaps_player(object, center)


func overlaps_player(object: PlaceableObject, center: Vector2) -> bool:
	var hurt := player.get_node_or_null(^"HurtComponent") as Area2D if player != null else null
	if hurt == null:
		return false

	var circle := CircleShape2D.new()
	circle.radius = float(object.collision_radius)

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, center + Vector2(object.collision_offset))
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = hurt.collision_layer

	for hit in get_world_2d().direct_space_state.intersect_shape(query):
		if hit.collider == hurt:
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


func water_cell() -> void:
	if tilled_soil_tilemap_layer == null or watered_soil_layer == null:
		return

	if tilled_soil_tilemap_layer.get_cell_source_id(cell_position) == -1:
		return

	watered_soil_layer.water_cell(cell_position, tilled_soil_tilemap_layer)
	SignalBus.sound_requested.emit(AudioManager.SFX_WATERING_CROPS)

	var watered_crop := object_target as CropInstance
	if watered_crop != null:
		watered_crop.on_watered()


func cell_under_cursor() -> Vector2i:
	if tilemap == null:
		return Vector2i.ZERO

	return tilemap.local_to_map(tilemap.to_local(target_position))


func object_under_cursor() -> ObjectInstance:
	var closest: ObjectInstance = null
	var closest_distance := INF

	for node in get_tree().get_nodes_in_group(OBJECT_GROUP):
		var instance := node as ObjectInstance
		if instance == null or instance.object == null:
			continue

		var aim := instance.global_position + Vector2(instance.object.hurtbox_offset)
		var distance := aim.distance_to(target_position)
		if distance > float(instance.object.hurtbox_radius) or distance >= closest_distance:
			continue

		closest = instance
		closest_distance = distance

	return closest


func props_under_cursor() -> TileMapLayer:
	return props_at(target_position)


func uses_cursor(item: Item) -> bool:
	if item == null:
		return false

	return (
		item.item_type == DataTypes.ItemType.Tool
		or item.item_type == DataTypes.ItemType.Seeds
		or item.item_type == DataTypes.ItemType.Placeable
	)


func clamp_to_reach(point: Vector2, reach: float = interaction_range) -> Vector2:
	if player == null:
		return point

	var origin := player.global_position
	return origin + (point - origin).limit_length(reach)
