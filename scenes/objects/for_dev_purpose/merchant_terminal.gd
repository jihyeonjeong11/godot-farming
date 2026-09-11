extends Sprite2D

const STOCK_MIN := 2
const STOCK_MAX := 20

@onready var inventory_component: ContainerInventoryComponent = $ContainerInventoryComponent


func _ready() -> void:
	var items: Array[Item] = []
	var amounts: Array[int] = []

	for id in ItemDB.all_ids():
		var item := ItemDB.get_item(id)
		if item == null:
			continue

		items.append(item)
		amounts.append(stock_amount(item))

	inventory_component.slot_count = items.size()
	inventory_component.slots.resize(items.size())
	inventory_component.fill(items, amounts)


func stock_amount(item: Item) -> int:
	var capacity := ItemStack.slot_capacity(item)
	if capacity <= 1:
		return 1

	return randi_range(STOCK_MIN, mini(STOCK_MAX, capacity))


func interact() -> void:
	SignalBus.barter_opened.emit(inventory_component.slots)
