class_name CropsCursorComponent
extends Node


@export var tilled_soil_tilemap_layer: TileMapLayer
## 심은 작물이 들어갈 레이어. 여기 자식으로 붙어야 세이브에 같이 딸려 나간다.
@export var crops_layer: Node2D

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
	if item == null:
		return

	# 씨앗 종류를 tool_type으로 가리지 않는다. 종류가 늘 때마다 여기에 if가 붙는다.
	# 무엇이 자랄지는 씨앗이 crop_scene_path로 직접 들고 있다.
	if item.item_type == "seeds":
		get_cell_under_mouse()
		add_crop(item)
	elif item.tool_type == ApoDataTypes.Tools.MineRock:
		get_cell_under_mouse()
		remove_crop()
	

func get_cell_under_mouse() -> void:
	mouse_position = tilled_soil_tilemap_layer.get_local_mouse_position()
	cell_position = tilled_soil_tilemap_layer.local_to_map(mouse_position)
	cell_source_id = tilled_soil_tilemap_layer.get_cell_source_id(cell_position)
	local_cell_position = tilled_soil_tilemap_layer.map_to_local(cell_position)
	distance = player.global_position.distance_to(local_cell_position)
	

func add_crop(item: Items) -> void:
	# TilledSoil 레이어에 타일이 없으면(-1) 안 갈린 맨땅이라 심을 수 없다.
	if distance >= 20.0 or cell_source_id == -1:
		return

	if item.crop_scene_path.is_empty():
		push_warning("crop_scene_path가 비어 있어 심을 수 없다: %s" % item.item_name)
		return

	# 한 칸에 하나만. 겹쳐 심으면 눈에도 안 띄고 수확도 꼬인다.
	if get_crop_at_cell() != null:
		return

	var packed := load(item.crop_scene_path) as PackedScene
	if packed == null:
		push_error("작물 씬을 불러오지 못했다: %s" % item.crop_scene_path)
		return

	var crop := packed.instantiate() as Node2D
	crop.position = local_cell_position
	crops_layer.add_child(crop)

	# 씨앗은 심으면 하나 없어진다. 씬을 못 만든 경우엔 여기까지 오지 않는다.
	Inventory.remove_item(Inventory.selected_slot, 1)


func remove_crop() -> void:
	if distance >= 20.0:
		return

	var target := get_crop_at_cell()
	if target != null:
		target.queue_free()


## 칸으로 비교한다. 위치를 그대로 견주면 1px만 어긋나도 놓친다.
func get_crop_at_cell() -> Node2D:
	for child in crops_layer.get_children():
		var node := child as Node2D
		if node == null or node.is_queued_for_deletion():
			continue

		if tilled_soil_tilemap_layer.local_to_map(node.position) == cell_position:
			return node

	return null
