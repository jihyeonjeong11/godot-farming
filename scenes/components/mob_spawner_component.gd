class_name MobSpawnerComponent
extends Node2D

## 스폰 후보. 항목마다 가중치를 줘서 한 마리씩 뽑는다.
@export var mob_entries: Array[MobSpawnEntry] = []

## 게임 내 1시간이 바뀔 때마다 이만큼 스폰한다.
@export var mobs_per_hour: int = 3

## 이 일차가 되기 전에는 아무것도 스폰하지 않는다.
@export var first_spawn_day: int = 1

## 살아있는 몹이 이 수에 도달하면 시간이 지나도 더 안 나온다.
@export var max_mobs: int = 12

## 플레이어 눈앞에 튀어나오지 않도록 이 거리 밖에만 스폰한다.
@export var min_spawn_distance: float = 96.0
@export var max_spawn_distance: float = 240.0

## 네비게이션 위 임의 지점을 뽑을 때의 최대 시도 횟수. 다 실패하면 그 한 마리는 거른다.
@export var max_spawn_attempts: int = 12

var spawned_mobs: Array[Node2D] = []
var last_spawn_hour: int = -1


func _ready() -> void:
	SignalBus.time_tick.connect(on_time_tick)


## 시간은 게임 내 1분마다 들어온다. 시(hour)가 바뀐 순간에만 한 번 스폰한다.
func on_time_tick(day: int, hour: int, _minute: int) -> void:
	if hour == last_spawn_hour:
		return

	last_spawn_hour = hour

	if day < first_spawn_day:
		return

	spawn_wave()


func spawn_wave() -> void:
	prune_dead_mobs()

	var player: Player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	for _index in mobs_per_hour:
		if spawned_mobs.size() >= max_mobs:
			return

		var mob_scene: PackedScene = pick_mob_scene()
		if mob_scene == null:
			return

		var spawn_position: Variant = find_spawn_position(player)
		if spawn_position == null:
			continue

		spawn_mob(mob_scene, spawn_position)


## 가중치 합에서 하나를 뽑는다. 쓸 만한 항목이 없으면 null.
func pick_mob_scene() -> PackedScene:
	var total_weight: float = 0.0

	for entry in mob_entries:
		if is_usable_entry(entry):
			total_weight += entry.weight

	if total_weight <= 0.0:
		return null

	var roll: float = randf() * total_weight

	for entry in mob_entries:
		if not is_usable_entry(entry):
			continue

		roll -= entry.weight
		if roll <= 0.0:
			return entry.mob_scene

	return null


func is_usable_entry(entry: MobSpawnEntry) -> bool:
	return entry != null and entry.mob_scene != null and entry.weight > 0.0


## 네비게이션 맵에서 플레이어와 적당히 떨어진 지점을 찾는다. 못 찾으면 null.
func find_spawn_position(player: Player) -> Variant:
	var navigation_map: RID = get_world_2d().navigation_map

	for _attempt in max_spawn_attempts:
		var candidate: Vector2 = NavigationServer2D.map_get_random_point(navigation_map, 1, false)
		var distance_to_player: float = candidate.distance_to(player.global_position)

		if distance_to_player >= min_spawn_distance and distance_to_player <= max_spawn_distance:
			return candidate

	return null


func spawn_mob(mob_scene: PackedScene, spawn_position: Vector2) -> void:
	var mob: Node2D = mob_scene.instantiate()

	## 스포너 밑이 아니라 형제로 붙인다. 스포너 하위에 두면 Y 정렬이 스포너 위치 기준으로 뭉개진다.
	add_sibling(mob)
	mob.global_position = spawn_position

	spawned_mobs.append(mob)


func prune_dead_mobs() -> void:
	for index in range(spawned_mobs.size() - 1, -1, -1):
		if not is_instance_valid(spawned_mobs[index]):
			spawned_mobs.remove_at(index)
