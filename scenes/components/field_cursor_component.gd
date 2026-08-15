class_name BuidableCursorComponent
extends Node

@export var grass_tilemap_layer: TileMapLayer
@export var tilled_soil_tilemap_layer: TileMapLayer
@export var terrain_set: int = 0
@export var terrain: int = 1

## 씬마다 플레이어 스크립트가 다르다(ApoPlayer / ApoPlayerNew). 좁게 박으면 다른 쪽
## 씬에서 캐스팅이 깨진다. 여기선 위치만 쓰므로 Node2D면 충분하다.
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
	# and selected tool is tool
	if item.tool_type != null && item.tool_type == ApoDataTypes.Tools.TillGround:
		get_cell_under_mouse()
		add_tilled_soil_cell()
	elif item.tool_type != null && item.tool_type == ApoDataTypes.Tools.MineRock:
		get_cell_under_mouse()
		remove_tilled_soil_cell()
	

func get_cell_under_mouse() -> void:
	mouse_position = grass_tilemap_layer.get_local_mouse_position()
	cell_position = grass_tilemap_layer.local_to_map(mouse_position)
	cell_source_id = grass_tilemap_layer.get_cell_source_id(cell_position)
	local_cell_position = grass_tilemap_layer.map_to_local(cell_position)
	distance = player.global_position.distance_to(local_cell_position)
	

func add_tilled_soil_cell() -> void:
	if distance < 20.0 && cell_source_id != -1:
		tilled_soil_tilemap_layer.set_cells_terrain_connect([cell_position], terrain_set, terrain, true)

func remove_tilled_soil_cell() -> void:
	if distance < 20.0 && cell_source_id != -1:
		tilled_soil_tilemap_layer.set_cells_terrain_connect([cell_position], 0, -1, true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
