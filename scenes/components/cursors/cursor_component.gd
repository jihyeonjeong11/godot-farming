extends Node2D

const OBJECT_GROUP := &"object"
const PROPS_GROUP := &"props"
const CROP_INSTANCE := preload("res://scenes/objects/placables/crop_instance.tscn")


@export var tilemap: TileMapLayer
@export var tilled_soil_tilemap_layer: TileMapLayer
@export var crops_layer: Node2D
@export var terrain_set: int = DataTypes.SOIL_TERRAIN_SET
@export var terrain: int = DataTypes.SoilTerrains.TilledDirt
@export var interaction_range: float = 88.0

var mouse_position: Vector2
var target_position: Vector2
var cell_position: Vector2i
var object_target: ObjectInstance
var props_target: TileMapLayer
var held: Item


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

	if GameInputEvents.is_use_tool():
		held = Inventory.get_selected_item()
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

		if object_target != null:
			return

		if held.tool_type == DataTypes.Tools.TillGround:
			if props_target == null and object_at_cell() == null:
				till_cell()
		if held.tool_type == DataTypes.Tools.MineRock:
			untill_cell()

	if GameInputEvents.interact():
		# 만약 오브젝트가 있다면, interact 시도함
		if object_target == null:
			return

		object_target.interact()


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


func is_cell_dirt() -> bool:
	var tile := tilemap.get_cell_tile_data(cell_position)
	return tile != null and tile.get_custom_data(&"tillable")


func object_at_cell() -> ObjectInstance:
	for node in get_tree().get_nodes_in_group(OBJECT_GROUP):
		var instance := node as ObjectInstance
		if instance == null or instance.is_queued_for_deletion():
			continue

		if tilemap.local_to_map(tilemap.to_local(instance.global_position)) == cell_position:
			return instance

	return null


func crop_at_cell() -> CropInstance:
	for child in crops_layer.get_children():
		var crop := child as CropInstance
		if crop == null or crop.is_queued_for_deletion():
			continue

		if tilemap.local_to_map(tilemap.to_local(crop.global_position)) == cell_position:
			return crop

	return null


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
	for node in get_tree().get_nodes_in_group(PROPS_GROUP):
		var layer := node as TileMapLayer
		if layer == null:
			continue

		var cell := layer.local_to_map(layer.to_local(target_position))
		if layer.get_cell_source_id(cell) != -1:
			return layer

	return null


func uses_cursor(item: Item) -> bool:
	if item == null:
		return false

	return (
		item.item_type == DataTypes.ItemType.Tool
		or item.item_type == DataTypes.ItemType.Seeds
	)


func clamp_to_reach(point: Vector2) -> Vector2:
	if player == null:
		return point

	var origin := player.global_position
	return origin + (point - origin).limit_length(interaction_range)
