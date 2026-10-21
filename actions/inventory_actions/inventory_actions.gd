class_name InventoryActions extends RefCounted

# 공통: signal toast 표시

# ingame_menu 아이템 우클릭으로 시작

# inventory_manager.is_consumable
# inventory_manager.update or delete
# stat_actions.update_stat 뭐 이런거고
# 아무 event emit. 이걸로 토스트 띄우고 퀘스트 같은거 업데이트하고 소리 띄우

const BULK_CRAFT_COUNT := 5


static func consume(index: int) -> bool:
	var stack := InventoryManager.get_item_stack_by_index(index)
	if stack == null:
		return false
	if stack.item.item_type == DataTypes.ItemType.Consumable:
		var stats := GameState.player_stat
		if stats != null:
			stats.health += stack.item.heal
			stats.hunger += stack.item.hunger
			stats.thirst += stack.item.thirst
		if stack.amount > 1:
			stack.amount -= 1
		else:
			InventoryManager.delete_stack(index)
		InventoryManager.updated_inventory.emit()
		SoundManager.play_ui_sound(AudioManager.SOUND_EFFECTS[AudioManager.SFX_EATING])
		return true
	else:
		return false
	
static func drop(_stack: ItemStack) -> void:
	pass
	
static func select_stack(index: int) -> void:
	if InventoryManager.held_stack != null:
		_put_down(index)
		return
	var stack := InventoryManager.get_item_stack_by_index(index)
	if stack == null or not InventoryManager.delete_stack(index):
		return
	InventoryManager.held_stack = stack
	InventoryManager.held_changed.emit()
	InventoryManager.updated_inventory.emit()
	
static func craft(recipe: CraftRecipe, times: int = 1) -> int:
	if recipe == null:
		return 0
	var result := recipe.result_item()
	var made := 0
	while made < times and recipe.can_craft():
		if not InventoryManager.has_room_for(result, recipe.result_amount):
			SignalBus.toast_requested.emit(result.item_texture, "인벤토리가 가득 찼다")
			break
		for id in recipe.ingredients:
			InventoryManager.remove_item(ItemDB.get_item(id), recipe.ingredients[id])
		InventoryManager.add_item_stack(ItemStack.new(result, recipe.result_amount))
		made += 1
	if made > 0:
		SignalBus.toast_requested.emit(result.item_texture, "+%d" % (made * recipe.result_amount))
		SoundManager.play_ui_sound(AudioManager.SOUND_EFFECTS[AudioManager.SFX_CRAFT])
	return made

static func craft_bulk(recipe: CraftRecipe) -> int:
	return craft(recipe, BULK_CRAFT_COUNT)

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
		
static func select_split_stack(index: int, half: bool) -> void:
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

static func select_equipment(index: int, slot_type: DataTypes.WearSlot) -> void:
	var held := InventoryManager.held_stack
	if held != null and held.item.wear_slot != slot_type:
		return
	var worn := InventoryManager.get_equipment(index)
	if held == null and worn == null:
		return
	if not InventoryManager.set_equipment(index, held):
		return
	StatActions.apply_equipment()
	InventoryManager.held_stack = worn
	InventoryManager.held_changed.emit()

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

static func trash_held() -> bool:
	if InventoryManager.held_stack == null:
		return false
	InventoryManager.held_stack = null
	InventoryManager.held_changed.emit()
	SoundManager.play_ui_sound(AudioManager.SOUND_EFFECTS[AudioManager.SFX_TRASH])
	return true

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
