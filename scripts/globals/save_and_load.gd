extends Node

# This is Temp File!

## 메뉴에서 "불러오기"로 들어왔는가. "새 게임"이면 false라서 세이브가 있어도 무시한다.
## 레벨이 뜨는 시점엔 이미 메뉴가 사라진 뒤라, 그 의도를 여기에 남겨 전달한다.
var load_requested := false

## 메뉴에서 새 판으로 들어온 순간에만 true. 포탈로 씬만 옮길 때는 false다.
## 플레이어가 스탯을 다시 채울지 말지를 이걸로 가른다.
var fresh_start := false


## 한 번만 답한다. 읽는 순간 내려가므로 씬을 옮겨도 다시 true가 되지 않는다.
func consume_fresh_start() -> bool:
	var value := fresh_start
	fresh_start = false
	return value

const SLOT_COUNT := 3
const SAVE_ROOT := "user://saves"

const INVENTORY_FILE := "inventory"
const TIME_FILE := "time"
const STATS_FILE := "stats"
const META_FILE := "meta"

## 지금 읽고 쓰는 슬롯. 메뉴에서 고른 순간 정해지고 그 판이 끝날 때까지 유지된다.
## 인게임 저장이 어느 슬롯으로 가는지도 이 값 하나로 정해진다.
var current_slot := 1

## 지금 플레이 중인 레벨. 저장 버튼은 UIManager 밑에 붙은 메뉴가 누르는데,
## 거기서는 부모를 타고 올라가도 레벨이 나오지 않는다. 씬을 바꾸는 쪽(game.gd)이
## 여기에 적어두는 편이 확실하다. 메인메뉴에 있으면 null이다.
var current_level: Node = null

## 이번 실행에서 이미 읽은 레벨 세이브. 레이어 넷이 각자 파일을 열지 않게 한다.
## 저장할 때 여기도 같이 갱신하므로 세이브 직후 값이 어긋나지 않는다.
var _level_cache := {}


## 슬롯 하나가 폴더 하나. 레벨 세이브가 레벨 수만큼 늘어나도 슬롯끼리 섞이지 않는다.
func slot_dir(slot: int = -1) -> String:
	return "%s/slot_%d" % [SAVE_ROOT, current_slot if slot < 0 else slot]


func _slot_file(file_name: String, slot: int = -1) -> String:
	return "%s/%s.sav" % [slot_dir(slot), file_name]


## 슬롯을 갈아타면 앞 슬롯에서 읽어둔 레벨 상태는 남의 것이 된다. 반드시 버린다.
## 같은 슬롯을 다시 골라도 버린다. 한 번 실행하는 동안 새 게임과 불러오기를
## 오갈 수 있고, 그때 앞 판의 밭이 남아 있으면 안 되기 때문이다.
func select_slot(slot: int) -> void:
	current_slot = slot
	_level_cache.clear()


## 새 게임은 그 슬롯의 옛 판을 지우고 시작한다. 파일을 남겨두면 이번 판에서
## 가보지 않은 레벨의 옛 상태가 그대로 딸려온다.
func clear_slot(slot: int = -1) -> void:
	_level_cache.clear()

	var dir := DirAccess.open(slot_dir(slot))
	if dir == null:
		return

	for file_name in dir.get_files():
		dir.remove(file_name)


## 슬롯 목록에 뿌릴 한 줄 요약. null이면 빈 슬롯이다.
func slot_meta(slot: int) -> Variant:
	var parsed: Variant = _read(_slot_file(META_FILE, slot))
	return parsed if parsed is Dictionary else null


func has_save(slot: int) -> bool:
	return slot_meta(slot) != null


## 저장은 전부 이 문으로 들어온다. 부르는 쪽이 항목을 하나씩 챙기게 두면
## 나중에 저장할 것이 늘었을 때 빠뜨리는 자리가 생긴다.
func save_game() -> void:
	if not is_instance_valid(current_level):
		push_error("플레이 중인 레벨이 없어 저장할 수 없다")
		return

	save_level(current_level)
	save_inventory()
	save_time()

	# 플레이어는 레벨 씬마다 따로 박혀 있어서 여기서 찾아 쓴다.
	var player := get_tree().get_first_node_in_group(&"player")
	if player != null:
		save_stats(player.get(&"stats") as BaseCharacterStats)

	_save_meta(current_level)


## 오토로드에 얹히는 것만 여기서 처리한다. 레벨 안의 레이어와 스탯은 씬이 뜬 뒤
## 각자 load_layer/load_stats로 가져간다.
func load_game() -> void:
	load_requested = true
	load_inventory()
	load_time()


## 목록에 뿌릴 값만 담는다. 복원에 쓰이지 않으므로 형식이 바뀌어도 세이브는 멀쩡하다.
func _save_meta(level: Node) -> void:
	var total_minutes := int(DayAndNightCycle.time / DayAndNightCycle.GAME_MINUTE_DURARTION)

	_write(_slot_file(META_FILE), {
		# 목록에 그대로 뿌릴 현지 시각 문자열. 유닉스 초로 두면 읽는 쪽이 시간대를 다시 맞춰야 한다.
		"saved_at": Time.get_datetime_string_from_system(),
		"day": total_minutes / DayAndNightCycle.MINUTES_PER_DAY,
		"level": _level_id_of(level),
	})


## 레벨 하나가 파일 하나. 그 안에 레이어별 상태가 통째로 들어간다.
## 레벨마다 나누는 이유는, 숲에서 저장하고 도시로 넘어가도 숲의 밭이 남아야 하기 때문이다.
func level_save_path(level_id: String) -> String:
	return _slot_file("level_%s" % level_id)


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


## 칸 배열 하나를 순서 그대로 떠낸다. 빈 칸은 null로 남겨야 자리가 밀리지 않는다.
## 아이템 자체(.tres)는 프로젝트 리소스라 저장하지 않고 경로만 적는다.
func _capture_slots(source: Array) -> Array:
	var slots := []

	for stack in source:
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

	return slots


## 이미 있는 배열에 채워 넣는다. 새 배열로 갈아끼우면 그 배열을 source 로 들고 있는
## UI 칸들(인벤토리 격자, 장비 칸)이 옛 배열을 계속 보게 된다.
func _restore_slots(target: Array, saved: Variant, size: int) -> void:
	target.resize(size)
	target.fill(null)

	if saved is not Array:
		return

	for i in mini((saved as Array).size(), size):
		var entry: Variant = saved[i]
		if entry is not Dictionary:
			continue

		# load는 같은 경로에 대해 같은 인스턴스를 돌려준다.
		# ItemStack.can_stack이 Items를 참조로 비교하므로 duplicate하면 안 된다.
		var item := load(entry["item"]) as Items
		if item == null:
			push_warning("아이템을 불러오지 못했다: %s" % entry["item"])
			continue

		target[i] = ItemStack.new(item, entry["amount"])


## 인벤토리 30칸과 착용 칸을 한 파일에 담는다. 장비를 따로 두면 슬롯을 지울 때
## 한쪽만 남아 입은 채로 빈 인벤토리가 되는 짝이 생긴다.
func save_inventory() -> void:
	_write(_slot_file(INVENTORY_FILE), {
		"slots": _capture_slots(Inventory.inventory),
		"armor": _capture_slots(Inventory.armor),
		"boots": _capture_slots(Inventory.boots),
		"selected_slot": Inventory.selected_slot,
	})


## 세이브가 있으면 인벤토리와 장비를 그 상태로 되돌린다. 없으면 아무것도 하지 않는다.
func load_inventory() -> void:
	var parsed: Variant = _read(_slot_file(INVENTORY_FILE))
	if parsed is not Dictionary:
		return

	_restore_slots(Inventory.inventory, parsed.get("slots", []), Inventory.BASE_INVENTORY_LIMIT)
	# 장비가 없던 시절의 세이브에는 이 키가 없다. 그때는 빈 칸으로 시작한다.
	_restore_slots(Inventory.armor, parsed.get("armor", []), Inventory.EQUIPMENT_SLOT_LIMIT)
	_restore_slots(Inventory.boots, parsed.get("boots", []), Inventory.EQUIPMENT_SLOT_LIMIT)

	Inventory.selected_slot = 0
	Inventory.select_slot(parsed.get("selected_slot", 0))
	Inventory.inventory_updated.emit()
	Inventory.equipment_updated.emit()


## 현재값만 적는다. 기준값은 player_stats.tres에 있으니 저장할 이유가 없고,
## 적어두면 나중에 밸런스를 고쳤을 때 옛 세이브가 옛 값을 붙들게 된다.
func save_stats(stats: BaseCharacterStats) -> void:
	if stats == null:
		return

	_write(_slot_file(STATS_FILE), {
		"health": stats.health,
		"stamina": stats.stamina,
		"hunger": stats.hunger,
		"thirst": stats.thirst,
		"gold": stats.gold,
	})


## 세이브가 없거나 "새 게임"으로 들어왔으면 null. 그때 무엇으로 시작할지는
## 부른 쪽이 정한다(load_layer와 같은 계약).
func load_stats() -> Variant:
	if not load_requested:
		return null

	var parsed: Variant = _read(_slot_file(STATS_FILE))
	return parsed if parsed is Dictionary else null


## 날짜/시각은 전부 time 하나에서 파생된다(recalculate_time).
## 그래서 day/hour/minute을 따로 적을 필요가 없고, 적으면 오히려 어긋날 여지만 생긴다.
func save_time() -> void:
	_write(_slot_file(TIME_FILE), {
		"time": DayAndNightCycle.time,
	})


func load_time() -> void:
	var parsed: Variant = _read(_slot_file(TIME_FILE))
	if parsed is not Dictionary:
		return

	DayAndNightCycle.time = parsed.get("time", DayAndNightCycle.time)
	# 엣지 검출용 캐시라 그대로 두면 다음 틱까지 시계 UI가 옛 값을 붙들고 있다.
	# -1로 밀어 두면 첫 recalculate_time에서 반드시 한 번 쏜다.
	DayAndNightCycle.current_minute = -1

	# 날짜는 반대로, 불러온 시각에 맞춰 미리 맞춰둔다. 메뉴에 머무는 동안에도
	# 오토로드는 계속 돌아서 current_day가 이미 딴 날에 가 있고, 그대로 두면 첫
	# recalculate_time이 하루가 넘어간 줄 알고 time_tick_day를 쏜다. 그러면 방금
	# 복원한 물기가 바로 마르고 작물은 하루치를 공짜로 먹는다.
	var total_minutes := int(DayAndNightCycle.time / DayAndNightCycle.GAME_MINUTE_DURARTION)
	DayAndNightCycle.current_day = total_minutes / DayAndNightCycle.MINUTES_PER_DAY


## 임시 파일에 먼저 쓰고 성공했을 때만 바꾼다.
## 그냥 덮어쓰면 쓰다가 죽었을 때 기존 세이브까지 같이 날아간다.
func _write(path: String, value: Variant) -> void:
	# 슬롯 폴더는 첫 저장 때 생긴다. 없으면 파일 열기부터 실패한다.
	var dir_path := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		var mkdir_err := DirAccess.make_dir_recursive_absolute(dir_path)
		if mkdir_err != OK:
			push_error("세이브 폴더를 만들지 못했다: %s" % error_string(mkdir_err))
			return

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
