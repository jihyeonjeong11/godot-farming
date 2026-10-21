extends Node

# index, 
signal updated_inventory()
signal updated_equipment()
signal consumed()
signal stack_selected(index: int)
signal half_stack_selected()
signal held_changed()

const BASE_INVENTORY_LIMIT = 30
const QUICKBAR_LIMIT = 10
const EQUIPMENT_SLOT_LIMIT = 1

var held_stack: ItemStack

# TODO: 나중에 current_inventory = 10 추가하고 업그레이드할 수 있

func _ready() -> void:
	GameState.inventory.resize(BASE_INVENTORY_LIMIT)

# 아이템 스택 crud
# 스택 이동


func get_stacks() -> void:
	pass
	
func is_inventory_full() -> void:
	pass

func is_stackable() -> void:
	pass

func add_item_stack(stack: ItemStack) -> int:
	if stack == null or not stack.is_valid():
		return 0

	var inventory := GameState.inventory
	var left := stack.amount

	for slot in inventory:
		if left <= 0:
			break
		if slot == null or not slot.is_same_kind(stack.item):
			continue
		var put := mini(slot.free_space(), left)
		slot.amount += put
		left -= put

	var per_slot := ItemStack.slot_capacity(stack.item)
	for i in inventory.size():
		if left <= 0:
			break
		if inventory[i] != null:
			continue
		var put := mini(per_slot, left)
		inventory[i] = ItemStack.new(stack.item, put)
		left -= put

	if left < stack.amount:
		updated_inventory.emit()
	return left

func has_room_for(item: Item, amount: int = 1) -> bool:
	if item == null or amount <= 0:
		return false

	var per_slot := ItemStack.slot_capacity(item)
	var room := 0
	for slot in GameState.inventory:
		if slot == null:
			room += per_slot
		elif slot.is_same_kind(item):
			room += slot.free_space()
		if room >= amount:
			return true
	return false

func get_item_stack_by_index(index: int) -> ItemStack:
	if index < 0 or index >= GameState.inventory.size():
		return null
	return GameState.inventory[index]
	
func delete_stack(index: int) -> bool:
	if get_item_stack_by_index(index) != null:
		GameState.inventory[index] = null
		return true
	return false

func place_stack(index: int, stack: ItemStack) -> bool:
	if index < 0 or index >= GameState.inventory.size():
		return false
	if GameState.inventory[index] != null:
		return false
	GameState.inventory[index] = stack
	return true

func update_stack() -> void:
	pass

func remove_item(item: Item, amount: int) -> bool:
	if item == null or amount <= 0 or count_item(item) < amount:
		return false
	var inventory := GameState.inventory
	var left := amount
	for i in inventory.size():
		if left <= 0:
			break
		var slot := inventory[i]
		if slot == null or not slot.is_same_kind(item):
			continue
		var take := mini(slot.amount, left)
		slot.amount -= take
		left -= take
		if slot.amount <= 0:
			inventory[i] = null
	updated_inventory.emit()
	return true

func count_item(item: Item) -> int:
	if item == null:
		return 0
	var total := 0
	for slot in GameState.inventory:
		if slot != null and slot.is_same_kind(item):
			total += slot.amount
	return total
