class_name FarmSpawner
extends Node
## 농장의 하루 갱신. 스타듀 Farm.DayUpdate 를 옮긴 것.
##
## 잔해(풀·돌·가지)는 이미 있는 잔해 옆 3x3 으로만 번지고, 풀은 빈 칸에 조금씩 새로 나고,
## 다 자란 나무는 주변에 묘목을 떨군다. 농장을 비운 사이 지난 날은 씬이 다시 뜰 때
## last_day 부터 몰아서 돌린다.

const OBJECT_INSTANCE := preload("res://scenes/objects/placables/object_instance.tscn")
const TREE_INSTANCE := preload("res://scenes/objects/placables/tree_instance.tscn")
const OBJECT_GROUP := &"object"
const NEIGHBOURS: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]

@export var layer_id: StringName = &"farm_spawner"
@export var land: TileMapLayer
## 이 레이어들에 타일이 있는 칸은 막힌 칸이다 (물, 울타리, 집).
@export var blockers: Array[TileMapLayer]
@export var tilled_soil: TileMapLayer
@export var watered_soil: WateredSoilLayer
@export var objects_layer: Node2D
## 셀 단위. 울타리 안쪽.
@export var area: Rect2i = Rect2i(4, 5, 42, 26)

@export_group("Debris")
@export var grass_object: PlaceableObject
@export var stone_object: PlaceableObject
@export var twig_object: PlaceableObject
## 하루에 번지는 잔해 수. 비 오면 두 배.
@export var debris_count: int = 6
@export var grass_attempts_min: int = 2
@export var grass_attempts_max: int = 4
@export_range(0.0, 1.0) var grass_chance: float = 0.15

var last_day: int = -1

var _cells: Dictionary = {}


func _ready() -> void:
	add_to_group(LevelLayer.GROUP)
	apply(SaveAndLoad.load_layer(self, layer_id))
	# 오브젝트 레이어가 세이브를 다 깐 뒤에 돌아야 한다. 같은 프레임의 _ready 가
	# 전부 끝난 다음이 deferred 다.
	_catch_up.call_deferred()
	SignalBus.time_tick_day.connect(on_time_tick_day)


func _catch_up() -> void:
	var today := _today()
	if last_day < 0:
		last_day = today
	while last_day < today:
		last_day += 1
		run_day()


func _today() -> int:
	var tm := TimeManager.find(get_tree())
	return tm.today() if tm != null else 0


func on_time_tick_day(day: int) -> void:
	while last_day < day:
		last_day += 1
		run_day()


func capture() -> Variant:
	return {"last_day": last_day}


func apply(state: Variant) -> void:
	if state is not Dictionary:
		return

	last_day = int(state.get("last_day", last_day))


func run_day() -> void:
	if land == null or objects_layer == null:
		return

	_index_cells()
	_update_trees()
	_spread_debris()
	_sprout_grass()


func _index_cells() -> void:
	_cells.clear()
	for child in objects_layer.get_children():
		if child.is_queued_for_deletion() or not child.is_in_group(OBJECT_GROUP):
			continue
		var node := child as Node2D
		if node == null:
			continue
		_cells[_cell_of(node)] = node


func _update_trees() -> void:
	for node in _cells.values():
		var tree_node := node as TreeInstance
		if tree_node == null or tree_node.tree == null:
			continue

		tree_node.day_update()
		if not tree_node.is_mature() or randf() >= tree_node.tree.spread_chance:
			continue

		var radius := tree_node.tree.spread_radius
		var target := _cell_of(tree_node) + Vector2i(randi_range(-radius, radius), randi_range(-radius, radius))
		if not _is_open(target) or _cells.has(target) or _is_tilled(target):
			continue

		_spawn(TREE_INSTANCE, tree_node.tree, target)


func _spread_debris() -> void:
	var parents: Array[Node2D] = []
	for node in _cells.values():
		if _debris_kind(node) != null:
			parents.append(node)
	if parents.is_empty():
		return

	var weather := WeatherManager.find(get_tree())
	var count := debris_count * (2 if weather != null and weather.is_raining() else 1)
	for i in count:
		var parent: Node2D = parents.pick_random()
		var target: Vector2i = _cell_of(parent) + NEIGHBOURS.pick_random()
		if not _is_open(target):
			continue

		var occupant: Node2D = _cells.get(target)
		if occupant != null:
			if occupant is not CropInstance:
				continue
			occupant.queue_free()
			_cells.erase(target)

		if _is_tilled(target):
			_untill(target)

		var kind := _debris_kind(parent)
		var spawned_object: PlaceableObject = grass_object
		if kind != grass_object:
			spawned_object = stone_object if randf() < 0.5 else twig_object
		_spawn(OBJECT_INSTANCE, spawned_object, target)


func _sprout_grass() -> void:
	if grass_object == null:
		return

	var attempts := randi_range(grass_attempts_min, grass_attempts_max)
	for i in attempts:
		for retry in 3:
			var target := Vector2i(
				randi_range(area.position.x, area.end.x - 1),
				randi_range(area.position.y, area.end.y - 1),
			)
			if randf() >= grass_chance:
				continue
			if not _is_open(target) or _cells.has(target) or _is_tilled(target):
				continue

			_spawn(OBJECT_INSTANCE, grass_object, target)
			break


func _spawn(packed: PackedScene, resource: PlaceableObject, cell: Vector2i) -> void:
	if resource == null:
		return

	var instance := packed.instantiate() as ObjectInstance
	instance.object = resource
	instance.name = "%s_%d_%d" % [resource.object_id, cell.x, cell.y]
	instance.global_position = _world_of(cell)
	objects_layer.add_child(instance)
	_cells[cell] = instance


func _debris_kind(node: Node) -> PlaceableObject:
	var instance := node as ObjectInstance
	if instance == null or instance is CropInstance or instance is TreeInstance:
		return null

	for candidate in [grass_object, stone_object, twig_object]:
		if candidate != null and instance.object == candidate:
			return candidate

	return null


func _is_open(cell: Vector2i) -> bool:
	if not area.has_point(cell):
		return false
	if land.get_cell_source_id(cell) == -1:
		return false

	var world := _world_of(cell)
	for blocker in blockers:
		if blocker == null:
			continue
		if blocker.get_cell_source_id(blocker.local_to_map(blocker.to_local(world))) != -1:
			return false

	return true


func _is_tilled(cell: Vector2i) -> bool:
	return tilled_soil != null and tilled_soil.get_cell_source_id(cell) != -1


func _untill(cell: Vector2i) -> void:
	tilled_soil.set_cells_terrain_connect([cell], DataTypes.SOIL_TERRAIN_SET, -1, true)
	if watered_soil != null:
		watered_soil.dry_cell(cell)


func _cell_of(node: Node2D) -> Vector2i:
	return land.local_to_map(land.to_local(node.global_position))


func _world_of(cell: Vector2i) -> Vector2:
	return land.to_global(land.map_to_local(cell))
