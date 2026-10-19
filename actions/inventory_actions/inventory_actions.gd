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
	
static func drop() -> void:
	pass
	
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
	
