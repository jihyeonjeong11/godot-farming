class_name CropsCursorComponent
extends Node


@export var tilled_soil_tilemap_layer: TileMapLayer
@export var crops_layer: Node2D
## TODO: 흐름이 잡히면 끈다. 셀 -> 오브젝트 -> 액션 순서로 어디서 끊기는지 찍는다.
@export var debug_log: bool = true

@onready var player: Node2D = get_tree().get_first_node_in_group("player")

var mouse_position: Vector2
var cell_position: Vector2i
var cell_source_id: int
var local_cell_position: Vector2
var distance: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.tool_used.connect(_on_tool_used)

	# 연결 자체가 안 됐을 때 아무 에러도 안 난다. 그 경우를 여기서 잡는다.
	if debug_log:
		print("[CropsCursor] 0) 연결됨 ", get_path(),
				"  밭=", tilled_soil_tilemap_layer,
				"  작물레이어=", crops_layer)

func _on_tool_used(item: Item, _user_position: Vector2, _target_position: Vector2) -> void:
	if item == null:
		return

	if item.item_type == "seeds":
		get_cell_under_mouse()
		if debug_log:
			print("[CropsCursor] 2) 액션=심기  아이템=", item.item_name)
		add_crop(item)
	elif item.tool_type == DataTypes.Tools.MineRock:
		get_cell_under_mouse()
		if debug_log:
			print("[CropsCursor] 2) 액션=제거  아이템=", item.item_name)
		remove_crop(item)
	elif debug_log:
		print("[CropsCursor] 2) 액션 없음  아이템=", item.item_name,
				"  종류=", item.item_type, "  도구=", item.tool_type)
	

func get_cell_under_mouse() -> void:
	mouse_position = tilled_soil_tilemap_layer.get_local_mouse_position()
	cell_position = tilled_soil_tilemap_layer.local_to_map(mouse_position)
	cell_source_id = tilled_soil_tilemap_layer.get_cell_source_id(cell_position)
	local_cell_position = tilled_soil_tilemap_layer.map_to_local(cell_position)
	distance = player.global_position.distance_to(local_cell_position)

	# source_id가 -1이면 그 칸은 아직 안 갈린 맨땅이다.
	if debug_log:
		print("[CropsCursor] 1) 셀=", cell_position,
				"  마우스=", mouse_position,
				"  타일source=", cell_source_id,
				"  거리=", snappedf(distance, 0.1))


func add_crop(item: Item) -> void:
	# TilledSoil 레이어에 타일이 없으면(-1) 안 갈린 맨땅이라 심을 수 없다.
	if distance >= item.use_range or cell_source_id == -1:
		if debug_log:
			print("[CropsCursor] 4) 심기 취소 — ",
					"사거리 밖" if distance >= item.use_range else "안 갈린 땅")
		return

	if item.crop_scene_path.is_empty():
		push_warning("crop_scene_path가 비어 있어 심을 수 없다: %s" % item.item_name)
		return

	# 한 칸에 하나만. 겹쳐 심으면 눈에도 안 띄고 수확도 꼬인다.
	if get_crop_at_cell() != null:
		if debug_log:
			print("[CropsCursor] 4) 심기 취소 — 이미 그 칸에 있음")
		return

	var packed := load(item.crop_scene_path) as PackedScene
	if packed == null:
		push_error("작물 씬을 불러오지 못했다: %s" % item.crop_scene_path)
		return

	var crop := packed.instantiate() as Node2D
	crop.position = local_cell_position
	crops_layer.add_child(crop)

	if debug_log:
		print("[CropsCursor] 4) 심었다 ", crop.name, " @", local_cell_position)

	# 씨앗은 심으면 하나 없어진다. 씬을 못 만든 경우엔 여기까지 오지 않는다.
	Inventory.remove_item(Inventory.selected_slot, 1)


func remove_crop(item: Item) -> void:
	if distance >= item.use_range:
		if debug_log:
			print("[CropsCursor] 4) 제거 취소 — 사거리 밖 ",
					snappedf(distance, 0.1), "/", item.use_range)
		return

	var target := get_crop_at_cell()
	if target != null:
		if debug_log:
			print("[CropsCursor] 4) 제거 ", target.name)
		target.queue_free()


## 칸으로 비교한다. 위치를 그대로 견주면 1px만 어긋나도 놓친다.
func get_crop_at_cell() -> Node2D:
	for child in crops_layer.get_children():
		var node := child as Node2D
		if node == null or node.is_queued_for_deletion():
			continue

		if tilled_soil_tilemap_layer.local_to_map(node.position) == cell_position:
			if debug_log:
				print("[CropsCursor] 3) 셀 위 오브젝트=", node.name,
						" @", node.position)
			return node

	if debug_log:
		print("[CropsCursor] 3) 셀 위 오브젝트 없음  레이어 자식수=",
				crops_layer.get_child_count())

	return null
