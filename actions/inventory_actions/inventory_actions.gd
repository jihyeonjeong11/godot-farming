class_name InventoryActions extends RefCounted

# 공통: signal toast 표시

# ingame_menu 아이템 우클릭으로 시작

# inventory_manager.is_consumable
# inventory_manager.update or delete
# stat_actions.update_stat 뭐 이런거고
# 아무 event emit. 이걸로 토스트 띄우고 퀘스트 같은거 업데이트하고 소리 띄우

# happens only from quickslot
static func consume() -> void:
	pass
	
static func drop(_stack: ItemStack) -> void:
	pass
	
static func click_slot(index: int) -> void:
	if InventoryManager.held_stack != null:
		_put_down(index)
		return
	var stack := InventoryManager.get_item_stack_by_index(index)
	if stack == null or not InventoryManager.delete_stack(index):
		return
	InventoryManager.held_stack = stack
	InventoryManager.held_changed.emit()
	InventoryManager.updated_inventory.emit()

static func _put_down(index: int) -> void:
	var held := InventoryManager.held_stack
	var target := InventoryManager.get_item_stack_by_index(index)
	if target == null:
		if not InventoryManager.place_stack(index, held):
			return
		InventoryManager.held_stack = null
	elif held.is_same_kind(target.item) and target.free_space() > 0:
		var put := mini(target.free_space(), held.amount)
		target.amount += put
		held.amount -= put
		if held.amount <= 0:
			InventoryManager.held_stack = null
	else:
		InventoryManager.delete_stack(index)
		InventoryManager.place_stack(index, held)
		InventoryManager.held_stack = target
	InventoryManager.held_changed.emit()
	InventoryManager.updated_inventory.emit()
		
static func split_slot(index: int, half: bool) -> void:
	var target := InventoryManager.get_item_stack_by_index(index)
	if target == null:
		return
	var held := InventoryManager.held_stack
	if held != null and not held.is_same_kind(target.item):
		return
	var take := maxi(target.amount / 2, 1) if half else 1
	if held != null:
		take = mini(take, held.free_space())
		if take <= 0:
			return
	target.amount -= take
	if target.amount <= 0:
		InventoryManager.delete_stack(index)
	if held == null:
		InventoryManager.held_stack = ItemStack.new(target.item, take)
	else:
		held.amount += take
	InventoryManager.held_changed.emit()
	InventoryManager.updated_inventory.emit()

static func return_held() -> void:
	var held := InventoryManager.held_stack
	if held == null:
		return
	InventoryManager.held_stack = null
	var left := InventoryManager.add_item_stack(held)
	if left > 0:
		held.amount = left
		drop(held)
	InventoryManager.held_changed.emit()

static func quickbar_select(index: int) -> void:
	if index < 0 or index >= InventoryManager.QUICKBAR_LIMIT:
		return
	if index == GameState.selected_slot:
		return
	GameState.selected_slot = index
	InventoryManager.stack_selected.emit(index)
	
static func obtain(stack: ItemStack) -> bool:
	if stack == null or not stack.is_valid():
		return false

	var left := InventoryManager.add_item_stack(stack)
	var gained := stack.amount - left
	if gained > 0:
		SignalBus.toast_requested.emit(stack.item.item_texture, "+%d" % gained)
	if left > 0:
		SignalBus.toast_requested.emit(stack.item.item_texture, "인벤토리가 가득 찼다")
	return left == 0
	
static func pickup(stack: ItemStack) -> bool:
	return obtain(stack)
	
# 인벤토리 옮기기
static func move() -> void:
	pass
	
static func equip() -> void:
	pass
	
static func unequip() -> void:
	pass
	
