extends Node

const DATA_ROOT := "res://world_objects/tres"
const CROP_SCENE := "res://world_objects/crops/crop_object.tscn"
const TREE_SCENE := "res://world_objects/nature/tree_object.tscn"
## 작물은 전부 같은 씬이라 type으로 정하고, 나머지는 id로 정한다.
const SCENES: Dictionary[StringName, String] = {
	&"bonfire": "res://world_objects/furniture/bonfire.tscn",
	&"grass": "res://world_objects/nature/grass_object.tscn",
	&"rock": "res://world_objects/nature/rock_object.tscn",
	&"oak_tree": TREE_SCENE,
	&"pine_tree": TREE_SCENE,
}

var _by_id: Dictionary[StringName, WorldObjectData] = {}


func _ready() -> void:
	_scan(DATA_ROOT)


func get_data(id: StringName) -> WorldObjectData:
	var data: WorldObjectData = _by_id.get(id)
	if data == null:
		push_warning("[WorldObjectDB] 모르는 id: %s" % id)
	return data


## data는 사본을 넣는다. 원본 tres를 공유하면 growth_stage가 같은 종류 전체에 번진다.
func create(id: StringName) -> WorldObject:
	var data := get_data(id)
	if data == null:
		return null
	var path: String = CROP_SCENE if data.type == DataTypes.ObjectType.Crops else SCENES.get(id, "")
	if path.is_empty():
		push_warning("[WorldObjectDB] 씬이 없는 id: %s" % id)
		return null
	var object := (load(path) as PackedScene).instantiate() as WorldObject
	object.data = data.duplicate() as WorldObjectData
	return object


func _scan(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("[WorldObjectDB] 폴더를 열지 못했다: %s" % path)
		return

	for sub_dir in dir.get_directories():
		_scan("%s/%s" % [path, sub_dir])

	for file_name in dir.get_files():
		# 내보낸 빌드에서는 .tres가 .tres.remap으로 보인다.
		var res_name := file_name.trim_suffix(".remap")
		if not res_name.ends_with(".tres"):
			continue

		var res_path := "%s/%s" % [path, res_name]
		var data := load(res_path) as WorldObjectData
		if data != null:
			_register(data, res_path)


func _register(data: WorldObjectData, res_path: String) -> void:
	if data.id.is_empty():
		push_warning("[WorldObjectDB] id가 비어 있다: %s" % res_path)
		return

	if _by_id.has(data.id):
		push_error("[WorldObjectDB] id가 겹친다: %s (%s / %s)"
				% [data.id, res_path, _by_id[data.id].resource_path])
		return

	_by_id[data.id] = data
