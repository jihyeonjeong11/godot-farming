extends Node

signal inventory_updated
signal item_gained(item: Item, amount: int)
signal equipment_updated
signal selected_slot_changed(index: int)

const BASE_INVENTORY_LIMIT = 30
const QUICKBAR_LIMIT = 10
## 부위당 한 칸. 늘어나면 여기만 키우고 UI가 칸을 더 꽂으면 된다.
const EQUIPMENT_SLOT_LIMIT = 1

## 각 칸은 ItemStack, 빈 칸은 null.
var inventory: Array[ItemStack] = []
## 착용 칸도 같은 ItemStack 배열이다. 그래야 InventorySlot 이 인벤토리와 장비를
## 구분하지 않고 배열끼리 맞바꾸는 것만으로 입고 벗기가 된다.
var armor: Array[ItemStack] = []
var boots: Array[ItemStack] = []
var selected_slot: int = 0
## 플레이어 씬이 둘이라 타입을 좁게 박지 않는다. 떨군 자리를 잡는 데만 쓴다.
var player_node: Node2D
var world_scene_cache: Dictionary = {}

func _ready():
	inventory.resize(BASE_INVENTORY_LIMIT)
	# 크기를 안 잡아두면 armor[0]이 범위를 벗어나고,
	# InventorySlot._drop_data 도 to_source.size()가 0이라 드롭을 통째로 무시한다.
	armor.resize(EQUIPMENT_SLOT_LIMIT)
	boots.resize(EQUIPMENT_SLOT_LIMIT)

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

## 들고 있는 뭉치. 인스턴스 상태(탄약 등)를 봐야 하는 쪽은 이걸 쓴다.
func get_selected_stack() -> ItemStack:
	return get_item(selected_slot)

## 들고 있는 물건의 스펙만. 무엇을 들었는지만 궁금한 쪽은 이걸 쓴다.
func get_selected_item() -> Item:
	var stack := get_selected_stack()
	if stack == null:
		return null
	return stack.item

## 뭉치 하나를 통째로 넣는다. 쌓을 수 있는 칸부터 붓고 남으면 빈 칸을 쓴다.
## 전부 들어갈 자리가 없으면 아무것도 넣지 않는다 — 절반만 먹고 나머지가
## 증발하면 어디로 갔는지 알 길이 없다.
func add_item(stack: ItemStack) -> bool:
	if stack == null or not stack.is_valid():
		return false
	if not has_room_for(stack.item, stack.amount):
		return false

	var left := stack.amount

	for i in inventory.size():
		if left <= 0:
			break
		var slot := inventory[i]
		if slot == null or not slot.can_stack(stack):
			continue

		var put: int = mini(slot.free_space(), left)
		slot.amount += put
		left -= put

	# 남은 만큼은 빈 칸에 새 뭉치로 만든다. 넘겨받은 스택을 그대로 꽂지 않는다 —
	# 준 쪽(땅에 떨어진 아이템 등)과 칸이 같은 뭉치를 공유하게 된다.
	var per_slot := ItemStack.slot_capacity(stack.item)
	for i in inventory.size():
		if left <= 0:
			break
		if inventory[i] != null:
			continue

		var put: int = mini(per_slot, left)
		inventory[i] = ItemStack.new(stack.item, put)
		left -= put

	inventory_updated.emit()
	item_gained.emit(stack.item, stack.amount - left)
	return left <= 0

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
func count_item(item: Item) -> int:
	if item == null:
		return 0

	var total := 0
	for stack in inventory:
		if stack != null and stack.is_same_kind(item):
			total += stack.amount
	return total


## 앞 칸부터 훑으며 amount 만큼 뺀다. 모자라면 아무것도 건드리지 않고 실패한다.
## 반쯤 깎다 멈추면 재료만 날아가므로 먼저 세고 나서 뺀다.
func consume_item(item: Item, amount: int) -> bool:
	if item == null or amount <= 0:
		return false
	if count_item(item) < amount:
		return false

	var left := amount
	for i in inventory.size():
		if left <= 0:
			break
		var stack := inventory[i]
		if stack == null or not stack.is_same_kind(item):
			continue

		var take: int = mini(left, stack.amount)
		stack.amount -= take
		left -= take
		if stack.amount <= 0:
			inventory[i] = null

	inventory_updated.emit()
	return true


## 결과물을 받아줄 자리가 있는지. 재료를 뺀 뒤에 자리가 없으면 만든 물건이 증발한다.
## 빈 칸뿐 아니라 이미 쌓여 있는 칸의 여유도 같이 센다.
func has_room_for(item: Item, amount: int = 1) -> bool:
	if item == null or amount <= 0:
		return false

	var per_slot := ItemStack.slot_capacity(item)
	var room := 0

	for stack in inventory:
		if stack == null:
			room += per_slot
		elif stack.is_same_kind(item):
			room += stack.free_space()

		if room >= amount:
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

	return has_room_for(recipe.result, maxi(recipe.result_amount, 1))


## 재료를 깎고 결과물을 넣는다. 한 번이라도 모자라면 시작조차 하지 않는다.
func craft(recipe: CraftRecipe) -> bool:
	if not can_craft(recipe):
		return false

	for need in recipe.ingredients:
		consume_item(need.item, need.amount)

	add_item(ItemStack.new(recipe.result, maxi(recipe.result_amount, 1)))

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
	if stack == null or stack.item == null:
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
	var drop := scene.instantiate() as Node2D
	if drop == null:
		return false

	# 칸 하나는 땅에서도 뭉치 하나다. 10개를 버리면 10개짜리 노드가 하나 떨어진다.
	# 공용 item_stack_instance.tscn은 자기가 무엇인지 모른다. 붙이기 전에 꽂아준다.
	# 넘겨받은 뭉치를 그대로 꽂지 않는다 — 칸과 땅이 같은 것을 공유하면 안 된다.
	if drop is ItemStackInstance:
		drop.stack = ItemStack.new(stack.item, amount)
	host.add_child(drop)
	drop.global_position = player_node.global_position

	return remove_item(i, amount)


func get_world_scene(item: Item) -> PackedScene:
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


## 착용 부위에 해당하는 배열. UI와 세이브가 같은 표를 보게 한다.
func equipment_source(slot: DataTypes.WearSlot) -> Array:
	match slot:
		DataTypes.WearSlot.Armor:
			return armor
		DataTypes.WearSlot.Boots:
			return boots
	return []


## 이 배열이 착용 칸인가. 드롭 한 번에 어느 쪽이든 걸렸으면 장비가 바뀐 것이다.
## InventorySlot 이 인벤토리와 장비를 구분하지 않으므로 판단은 여기서 한다.
func is_equipment_source(source: Array) -> bool:
	return is_same(source, armor) or is_same(source, boots)


## 지금 입고 있는 것들이 더해주는 값의 합.
## 스탯 리소스는 이 오토로드를 모르므로, 값만 뽑아 넘겨주는 쪽이 이 함수를 쓴다.
func equipment_bonus() -> Dictionary:
	var total := {"defense": 0, "speed": 0}

	for source in [armor, boots]:
		for stack in source:
			if stack == null or stack.item == null:
				continue
			total["defense"] += stack.item.defense
			total["speed"] += stack.item.speed

	return total


func increase_iventory_size():
	inventory_updated.emit()

func set_player_reference(player: Node2D) -> void:
	player_node = player
