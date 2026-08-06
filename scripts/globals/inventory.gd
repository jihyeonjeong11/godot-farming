extends Node

signal inventory_updated

const BASE_INVENTORY_LIMIT = 30
const QUICKBAR_LIMIT = 10

var inventory = []
var player_node: ApoPlayer
var world_scene_cache: Dictionary = {}

# initial inventory limit size
func _ready():
	inventory.resize(BASE_INVENTORY_LIMIT)

func get_item(i: int):
	if i < 0 or i >= inventory.size():
		return null
	return inventory[i]
	
func add_item(item: Items) -> bool:
	if item == null:
		return false

	if item.max_stack > 0:
		for i in inventory.size():
			var slot = inventory[i]
			if slot == null:
				continue
			if slot["item"] != item:
				continue
			if slot["amount"] >= item.max_stack:
				continue
			slot["amount"] += 1
			inventory_updated.emit()
			return true

	for i in inventory.size():
		if inventory[i] == null:
			inventory[i] = {"item": item, "amount": 1}
			inventory_updated.emit()
			return true

	return false

func remove_item(i: int, amount: int = 1) -> bool:
	var slot = get_item(i)
	if slot == null or amount <= 0:
		return false

	slot["amount"] -= amount
	if slot["amount"] <= 0:
		inventory[i] = null

	inventory_updated.emit()
	return true

## from 칸과 to 칸을 통째로 맞바꾼다. 같은 아이템이어도 스택을 합치지 않는다.
func swap_items(from: int, to: int) -> bool:
	if from == to:
		return false
	if from < 0 or from >= inventory.size():
		return false
	if to < 0 or to >= inventory.size():
		return false

	var moved = inventory[from]
	inventory[from] = inventory[to]
	inventory[to] = moved

	inventory_updated.emit()
	return true

func drop_item(i: int) -> bool:
	var slot = get_item(i)
	if slot == null:
		return false

	var scene := get_world_scene(slot["item"])
	if scene == null:
		return false

	if player_node == null or not is_instance_valid(player_node):
		push_warning("플레이어가 없어 아이템을 떨굴 수 없습니다.")
		return false

	var host := player_node.get_parent()
	if host == null:
		return false

	var amount: int = slot["amount"]
	for _n in amount:
		var drop := scene.instantiate() as Node2D
		if drop == null:
			continue
		host.add_child(drop)
		drop.global_position = player_node.global_position

	return remove_item(i, amount)


func get_world_scene(item: Items) -> PackedScene:
	if item == null or item.world_scene_path.is_empty():
		return null

	if world_scene_cache.has(item.world_scene_path):
		return world_scene_cache[item.world_scene_path]

	var scene := load(item.world_scene_path) as PackedScene
	if scene == null:
		push_warning("월드 씬을 불러오지 못했습니다: %s" % item.item_name)
		return null

	world_scene_cache[item.world_scene_path] = scene
	return scene


func increase_iventory_size():
	inventory_updated.emit()

func set_player_reference(player: ApoPlayer) -> void:
	player_node = player
	
	
