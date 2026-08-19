class_name BuidableCursorComponent
extends Node

@export var grass_tilemap_layer: TileMapLayer
@export var tilled_soil_tilemap_layer: TileMapLayer
@export var terrain_set: int = 0
@export var terrain: int = 4

@export var watered_terrain: int = 5

@onready var player: Node2D = get_tree().get_first_node_in_group("player")

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
		# 타일에 isWatered 추가
		get_cell_under_mouse()
		add_watered_soil_cell(item)
	elif item.tool_type != null && item.tool_type == DataTypes.Tools.MineRock:
		get_cell_under_mouse()
		remove_tilled_soil_cell(item)

func add_watered_soil_cell(item: Items) -> void:
	if distance < item.use_range && cell_source_id != -1:
		tilled_soil_tilemap_layer.set_cells_terrain_connect([cell_position], terrain_set, watered_terrain, true)

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
	if distance < item.use_range && cell_source_id != -1:
		tilled_soil_tilemap_layer.set_cells_terrain_connect([cell_position], 0, -1, true)
