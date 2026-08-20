class_name BuidableCursorComponent
extends Node

@export var grass_tilemap_layer: TileMapLayer
@export var tilled_soil_tilemap_layer: TileMapLayer
@export var terrain_set: int = DataTypes.SOIL_TERRAIN_SET
@export var terrain: int = DataTypes.SoilTerrains.TilledDirt

@onready var player: Node2D = get_tree().get_first_node_in_group("player")
## 물 준 칸을 그리는 레이어. 씬에 없으면 물주기만 조용히 넘어간다.
@onready var watered_soil_layer: WateredSoilLayer = (
	get_tree().get_first_node_in_group(WateredSoilLayer.GROUP) as WateredSoilLayer
)

var mouse_position: Vector2
var cell_position: Vector2i
var cell_source_id: int
var local_cell_position: Vector2
var distance: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.tool_used.connect(_on_tool_used)

func _on_tool_used(item: Items, _user_position: Vector2, _target_position: Vector2) -> void:
	if item.tool_type != null && item.tool_type == DataTypes.Tools.TillGround:
		get_cell_under_mouse()
		add_tilled_soil_cell(item)
	elif item.tool_type != null && item.tool_type == DataTypes.Tools.WaterCrops:
		get_cell_under_mouse()
		add_watered_soil_cell(item)
	elif item.tool_type != null && item.tool_type == DataTypes.Tools.MineRock:
		get_cell_under_mouse()
		remove_tilled_soil_cell(item)

## TilledSoil 은 건드리지 않는다. 젖은 칸을 거기에 다른 terrain 으로 칠하면
## 오토타일이 남남으로 보고 이어 붙이질 않아 밭이 동그란 섬으로 쪼개진다.
func add_watered_soil_cell(item: Items) -> void:
	if distance >= item.use_range or watered_soil_layer == null:
		return

	watered_soil_layer.water_cell(cell_position, tilled_soil_tilemap_layer)

func get_cell_under_mouse() -> void:
	mouse_position = grass_tilemap_layer.get_local_mouse_position()
	cell_position = grass_tilemap_layer.local_to_map(mouse_position)
	cell_source_id = grass_tilemap_layer.get_cell_source_id(cell_position)
	local_cell_position = grass_tilemap_layer.map_to_local(cell_position)
	distance = player.global_position.distance_to(local_cell_position)
	

func add_tilled_soil_cell(item: Items) -> void:
	if distance < item.use_range && cell_source_id != -1:
		tilled_soil_tilemap_layer.set_cells_terrain_connect([cell_position], terrain_set, terrain, true)

func remove_tilled_soil_cell(item: Items) -> void:
	if distance >= item.use_range or cell_source_id == -1:
		return

	tilled_soil_tilemap_layer.set_cells_terrain_connect([cell_position], terrain_set, -1, true)

	# 물기는 갈린 땅에 얹힌 것이다. 밭을 없애면 같이 지워야 젖은 타일만 덩그러니 남지 않는다.
	if watered_soil_layer != null:
		watered_soil_layer.dry_cell(cell_position)
