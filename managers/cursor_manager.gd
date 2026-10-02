extends Node

# TODO: range in GLOBAL_VARS

const OBJECT_GROUP := &"object"
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
		return
	if not is_locked:
		target_pos = cell_center(clamp_to_reach(cell_of(player.get_global_mouse_position())))
	update_tile_highlight()


func update_tile_highlight() -> void:
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


func cell_of(point: Vector2) -> Vector2i:
	return Vector2i((tilemap.to_local(point) / GlobalVars.tile_size).floor())


func cell_center(cell: Vector2i) -> Vector2:
	return tilemap.to_global((Vector2(cell) + Vector2(0.5, 0.5)) * GlobalVars.tile_size)


func clamp_to_reach(cell: Vector2i) -> Vector2i:
	var origin := cell_of(player_feet.global_position)
	var offset := Vector2(cell - origin)
	var reach := float(GlobalVars.tool_reach_tiles)
	var longest := maxf(absf(offset.x), absf(offset.y))
	if longest > reach:
		offset = (offset / longest * reach).round()
	return origin + Vector2i(offset)


func _unhandled_input(event: InputEvent) -> void:
	if player == null or is_locked:
		return
	if event.is_action_pressed("hit"):
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


# player animation ends
func on_tool_used(item: Item) -> void:
	# ask mouse_pos tile is occupied and tile type
	print("item=", item.item_name if item != null else "null", " target_pos=", target_pos)
	is_locked = false
	
func on_level_loaded() -> void:
	player = get_tree().get_first_node_in_group(&"player")
	player_feet = player.get_node_or_null(^"CollisionShape2D") as Node2D if player != null else null
	is_locked = false
	var level = SaveAndLoad.current_level
	tilemap = level.get_node_or_null(^"Tilemap") as TileMapLayer if level != null else null
