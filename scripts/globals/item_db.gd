extends Node

const ITEM_ROOT := "res://scripts/resources/item"

var _by_id: Dictionary[StringName, Item] = {}


func _ready() -> void:
	_scan(ITEM_ROOT)

func get_item(id: StringName) -> Item:
	if id.is_empty():
		return null

	var item: Item = _by_id.get(id)
	if item == null:
		push_warning("[ItemDB] 모르는 item_id: %s" % id)
	return item


func has_item(id: StringName) -> bool:
	return not id.is_empty() and _by_id.has(id)


## 표에 있는 id 전부. 검증과 디버그용이다.
func all_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_by_id.keys())
	ids.sort()
	return ids

func of_type(item_type: DataTypes.ItemType) -> Array[Item]:
	var found: Array[Item] = []
	for item in _by_id.values():
		if item.item_type == item_type:
			found.append(item)
	return found


func _scan(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("[ItemDB] 폴더를 열지 못했다: %s" % path)
		return

	for sub_dir in dir.get_directories():
		_scan("%s/%s" % [path, sub_dir])

	for file_name in dir.get_files():
		# 내보낸 빌드에서는 .tres 가 .tres.remap 으로 보인다. 이 꼬리를 안 떼면
		# 에디터에서만 되고 빌드에서는 표가 통째로 비는 사고가 난다.
		var res_name := file_name.trim_suffix(".remap")
		if not res_name.ends_with(".tres"):
			continue

		var res_path := "%s/%s" % [path, res_name]
		var item := load(res_path) as Item
		if item == null:
			continue

		_register(item, res_path)


func _register(item: Item, res_path: String) -> void:
	var id := StringName(item.item_id)

	if id.is_empty():
		push_error("[ItemDB] item_id 가 비어 있다: %s" % res_path)
		return

	if _by_id.has(id):
		push_error("[ItemDB] item_id 가 겹친다: %s (%s / %s)"
				% [id, res_path, _by_id[id].resource_path])
		return

	_by_id[id] = item
	
func dev_get_random_item_by_type(type: DataTypes.ItemType) -> Item:
	return of_type(type).pick_random()
