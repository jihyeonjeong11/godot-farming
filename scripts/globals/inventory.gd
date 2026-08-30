extends Node

signal inventory_updated
signal selected_slot_changed(index: int)

const BASE_INVENTORY_LIMIT = 30
const QUICKBAR_LIMIT = 10

## 각 칸은 ItemStack, 빈 칸은 null.
var inventory: Array[ItemStack] = []
var selected_slot: int = 0
## 플레이어 씬이 둘이라 타입을 좁게 박지 않는다. 떨군 자리를 잡는 데만 쓴다.
var player_node: Node2D
var world_scene_cache: Dictionary = {}

func _ready():
	inventory.resize(BASE_INVENTORY_LIMIT)

func get_item(i: int) -> ItemStack:
	if i < 0 or i >= inventory.size():
		return null
	return inventory[i]

func select_slot(index: int) -> void:
	if index < 0 or index >= QUICKBAR_LIMIT:
		return
	if index == selected_slot:
		return
	selected_slot = index
	selected_slot_changed.emit(index)

func get_selected_item() -> Items:
	var stack := get_item(selected_slot)
	if stack == null:
		return null
	return stack.item

func add_item(item: Items) -> bool:
	if item == null:
		return false

	for i in inventory.size():
		var stack := inventory[i]
		if stack != null and stack.can_stack(item):
			stack.amount += 1
			inventory_updated.emit()
			return true

	for i in inventory.size():
		if inventory[i] == null:
			inventory[i] = ItemStack.new(item, 1)
			inventory_updated.emit()
			return true

	return false

func remove_item(i: int, amount: int = 1) -> bool:
	var stack := get_item(i)
	if stack == null or amount <= 0:
		return false

	stack.amount -= amount
	if stack.amount <= 0:
		inventory[i] = null

	inventory_updated.emit()
	return true

## 인벤토리 전체에서 이 아이템이 몇 개인지. 칸이 여러 개로 쪼개져 있어도 합쳐서 센다.
func count_item(item: Items) -> int:
	if item == null:
		return 0

	var total := 0
	for stack in inventory:
		if stack != null and stack.item == item:
			total += stack.amount
	return total


## 앞 칸부터 훑으며 amount 만큼 뺀다. 모자라면 아무것도 건드리지 않고 실패한다.
## 반쯤 깎다 멈추면 재료만 날아가므로 먼저 세고 나서 뺀다.
func consume_item(item: Items, amount: int) -> bool:
	if item == null or amount <= 0:
		return false
	if count_item(item) < amount:
		return false

	var left := amount
	for i in inventory.size():
		if left <= 0:
			break
		var stack := inventory[i]
		if stack == null or stack.item != item:
			continue

		var take: int = mini(left, stack.amount)
		stack.amount -= take
		left -= take
		if stack.amount <= 0:
			inventory[i] = null

	inventory_updated.emit()
	return true


## 결과물을 받아줄 자리가 있는지. 재료를 뺀 뒤에 자리가 없으면 만든 물건이 증발한다.
func has_room_for(item: Items) -> bool:
	if item == null:
		return false

	for stack in inventory:
		if stack == null:
			return true
		if stack.can_stack(item):
			return true
	return false


func can_craft(recipe: CraftRecipe) -> bool:
	if recipe == null or recipe.result == null:
		return false

	for need in recipe.ingredients:
		if need == null or need.item == null:
			return false
		if count_item(need.item) < need.amount:
			return false

	return has_room_for(recipe.result)


## 재료를 깎고 결과물을 넣는다. 한 번이라도 모자라면 시작조차 하지 않는다.
func craft(recipe: CraftRecipe) -> bool:
	if not can_craft(recipe):
		return false

	for need in recipe.ingredients:
		consume_item(need.item, need.amount)

	for _n in maxi(recipe.result_amount, 1):
		add_item(recipe.result)

	inventory_updated.emit()
	return true


func swap_items(from: int, to: int) -> bool:
	if from == to:
		return false
	if from < 0 or from >= inventory.size():
		return false
	if to < 0 or to >= inventory.size():
		return false

	var moved := inventory[from]
	inventory[from] = inventory[to]
	inventory[to] = moved

	inventory_updated.emit()
	return true

func drop_item(i: int) -> bool:
	var stack := get_item(i)
	if stack == null:
		return false

	var scene := get_world_scene(stack.item)
	if scene == null:
		return false

	if player_node == null or not is_instance_valid(player_node):
		push_warning("플레이어가 없어 아이템을 떨굴 수 없습니다.")
		return false

	var host := player_node.get_parent()
	if host == null:
		return false

	var amount := stack.amount
	for _n in amount:
		var drop := scene.instantiate() as Node2D
		if drop == null:
			continue
		# 공용 dropped_item.tscn은 자기가 무엇인지 모른다. 붙이기 전에 꽂아준다.
		if drop is DroppedItem:
			drop.item = stack.item
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

func set_player_reference(player: Node2D) -> void:
	player_node = player
	
	
