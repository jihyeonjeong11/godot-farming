extends Node

## 메뉴에서 "불러오기"로 들어왔는가. "새 게임"이면 false라서 세이브가 있어도 무시한다.
## 레벨이 뜨는 시점엔 이미 메뉴가 사라진 뒤라, 그 의도를 여기에 남겨 전달한다.
var load_requested := false

const INVENTORY_SAVE_PATH := "user://inventory.sav"
const TIME_SAVE_PATH := "user://time.sav"

## 이번 실행에서 이미 읽은 레벨 세이브. 레이어 넷이 각자 파일을 열지 않게 한다.
## 저장할 때 여기도 같이 갱신하므로 세이브 직후 값이 어긋나지 않는다.
var _level_cache := {}


## 레벨 하나가 파일 하나. 그 안에 레이어별 상태가 통째로 들어간다.
## 레벨마다 나누는 이유는, 숲에서 저장하고 도시로 넘어가도 숲의 밭이 남아야 하기 때문이다.
func level_save_path(level_id: String) -> String:
	return "user://level_%s.sav" % level_id


## 레벨 안의 레이어를 전부 훑어 한 파일로 떠낸다.
## 무엇을 어떻게 떠낼지는 레이어가 정한다(LevelLayer.capture).
func save_level(level: Node) -> void:
	var level_id := _level_id_of(level)
	if level_id.is_empty():
		return

	var layers := {}

	for node in get_tree().get_nodes_in_group(LevelLayer.GROUP):
		# 다른 레벨이 아직 트리에 남아 있는 순간에 섞이지 않게 한다.
		if not level.is_ancestor_of(node):
			continue

		# 레이어는 Node2D(LevelLayer)일 수도, TileMapLayer(갈린 땅)일 수도 있다.
		# 공통 조상이 없어서 점으로 부르면 컴파일에서 막힌다. 이름으로 부른다.
		layers[String(node.get(&"layer_id"))] = node.call(&"capture")

	_level_cache[level_id] = layers
	_write(level_save_path(level_id), layers)


## 레이어가 _ready에서 자기 몫만 꺼내 간다.
## null이면 세이브가 없다는 뜻이고, 그때 무엇으로 시작할지는 레이어가 정한다.
func load_layer(layer: Node, layer_id: StringName) -> Variant:
	if not load_requested:
		return null

	# 레벨 씬 안에 놓인 노드의 owner는 그 레벨의 루트다.
	var level_id := _level_id_of(layer.owner if layer.owner != null else layer)
	if level_id.is_empty():
		return null

	return _read_level(level_id).get(String(layer_id))


## 세이브 파일 이름은 레벨 씬 파일 이름에서 딴다.
## 레벨 루트에 스크립트를 달아 id를 적어두지 않아도 되고, 씬을 늘려도 손댈 곳이 없다.
func _level_id_of(level: Node) -> String:
	var path := level.scene_file_path
	if path.is_empty():
		push_error("레벨 씬 경로를 알 수 없어 세이브를 다룰 수 없다: %s" % level.name)
		return ""

	return path.get_file().get_basename()


func _read_level(level_id: String) -> Dictionary:
	if _level_cache.has(level_id):
		return _level_cache[level_id]

	var parsed: Variant = _read(level_save_path(level_id))
	var layers: Dictionary = parsed if parsed is Dictionary else {}
	_level_cache[level_id] = layers

	return layers


## 인벤토리 30칸을 순서 그대로 떠낸다. 빈 칸은 null로 남겨야 자리가 밀리지 않는다.
## 아이템 자체(.tres)는 프로젝트 리소스라 저장하지 않고 경로만 적는다.
func save_inventory() -> void:
	var slots := []

	for stack in Inventory.inventory:
		if stack == null or stack.item == null:
			slots.append(null)
			continue

		# 코드로 만든 Items는 경로가 없어 다시 찾을 방법이 없다.
		if stack.item.resource_path.is_empty():
			push_warning("resource_path가 없어 저장할 수 없다: %s" % stack.item.item_name)
			slots.append(null)
			continue

		slots.append({
			"item": stack.item.resource_path,
			"amount": stack.amount,
		})

	_write(INVENTORY_SAVE_PATH, {
		"slots": slots,
		"selected_slot": Inventory.selected_slot,
	})


## 세이브가 있으면 인벤토리를 통째로 갈아끼운다. 없으면 아무것도 하지 않는다.
func load_inventory() -> void:
	var parsed: Variant = _read(INVENTORY_SAVE_PATH)
	if parsed is not Dictionary:
		return

	var slots: Array = parsed.get("slots", [])
	var restored: Array[ItemStack] = []
	restored.resize(Inventory.BASE_INVENTORY_LIMIT)

	for i in mini(slots.size(), restored.size()):
		var entry: Variant = slots[i]
		if entry is not Dictionary:
			continue

		# load는 같은 경로에 대해 같은 인스턴스를 돌려준다.
		# ItemStack.can_stack이 Items를 참조로 비교하므로 duplicate하면 안 된다.
		var item := load(entry["item"]) as Items
		if item == null:
			push_warning("아이템을 불러오지 못했다: %s" % entry["item"])
			continue

		restored[i] = ItemStack.new(item, entry["amount"])

	Inventory.inventory = restored
	Inventory.selected_slot = 0
	Inventory.select_slot(parsed.get("selected_slot", 0))
	Inventory.inventory_updated.emit()


## 날짜/시각은 전부 time 하나에서 파생된다(recalculate_time).
## 그래서 day/hour/minute을 따로 적을 필요가 없고, 적으면 오히려 어긋날 여지만 생긴다.
func save_time() -> void:
	_write(TIME_SAVE_PATH, {
		"time": DayAndNightCycle.time,
	})


func load_time() -> void:
	var parsed: Variant = _read(TIME_SAVE_PATH)
	if parsed is not Dictionary:
		return

	DayAndNightCycle.time = parsed.get("time", DayAndNightCycle.time)
	# 엣지 검출용 캐시라 그대로 두면 다음 틱까지 시계 UI가 옛 값을 붙들고 있다.
	# -1로 밀어 두면 첫 recalculate_time에서 반드시 한 번 쏜다.
	DayAndNightCycle.current_minute = -1


## 임시 파일에 먼저 쓰고 성공했을 때만 바꾼다.
## 그냥 덮어쓰면 쓰다가 죽었을 때 기존 세이브까지 같이 날아간다.
func _write(path: String, value: Variant) -> void:
	var tmp_path := path + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("세이브 파일을 열지 못했다: %s" % error_string(FileAccess.get_open_error()))
		return

	# var_to_str은 Vector2를 그대로 담는다. JSON은 x/y로 풀어야 한다.
	file.store_string(var_to_str(value))
	file.close()

	var err := DirAccess.rename_absolute(tmp_path, path)
	if err != OK:
		push_error("세이브 파일 교체 실패: %s" % error_string(err))


## 없거나 깨졌으면 null. 부른 쪽이 타입을 확인한다.
func _read(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("세이브 파일을 열지 못했다: %s" % error_string(FileAccess.get_open_error()))
		return null

	var parsed: Variant = str_to_var(file.get_as_text())
	file.close()

	if parsed == null:
		push_error("세이브 형식이 맞지 않는다: %s" % path)

	return parsed
