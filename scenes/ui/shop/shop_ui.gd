extends CanvasLayer

const INVENTORY_SLOT = preload("uid://byt1lfm4vsyc4")

const COLOR_OK := Color(0.95, 0.78, 0.35)
const COLOR_BAD := Color(0.9, 0.35, 0.3)

@export var sell_slot_count: int = 6
@export var buy_slot_count: int = 6
@export var shop_slot_count: int = 30

@onready var my_inventory_grid: GridContainer = %MyInventoryGrid
@onready var barter_inventory_grid: GridContainer = %BarterInventoryGrid
@onready var shop_inventory_grid: GridContainer = %ShopInventoryGrid
@onready var gold_label: Label = %GoldLabel
@onready var slot_label: Label = %SlotLabel
@onready var confirm_button: Button = %ConfirmButton
@onready var cancel_button: Button = %CancelButton

var sell_multiplier: float = GlobalVars.default_sell_multiplier

var sell_slots: Array[ItemStack] = []
var buy_slots: Array[ItemStack] = []
var shop_slots: Array[ItemStack] = []

var _my_cells: Array[InventorySlot] = []
var _sell_cells: Array[InventorySlot] = []
var _buy_cells: Array[InventorySlot] = []
var _shop_cells: Array[InventorySlot] = []


func _ready() -> void:
	Inventory.inventory_updated.connect(refresh)
	confirm_button.pressed.connect(on_confirm)
	cancel_button.pressed.connect(on_cancel)

	sell_slots.resize(sell_slot_count)
	buy_slots.resize(buy_slot_count)
	shop_slots.resize(shop_slot_count)

	_build_my_cells()
	_build_barter_cells()
	_build_shop_cells()

	refresh()


func _exit_tree() -> void:
	if Inventory.inventory_updated.is_connected(refresh):
		Inventory.inventory_updated.disconnect(refresh)
	_restore_table()


func setup(stocks: Array[ItemStack]) -> void:
	_restore_table()

	shop_slots = stocks
	if _shop_cells.size() != shop_slots.size():
		_build_shop_cells()
	else:
		for cell in _shop_cells:
			cell.source = shop_slots
	refresh()


func refresh() -> void:
	_paint(_my_cells, Inventory.inventory)
	_paint(_sell_cells, sell_slots)
	_paint(_buy_cells, buy_slots)
	_paint(_shop_cells, shop_slots)
	_update_settle()


func _build_my_cells() -> void:
	_clear_grid(my_inventory_grid)
	_my_cells.clear()

	for i in Inventory.BASE_INVENTORY_LIMIT:
		var cell := _make_cell("MySlot%d" % i, i, Inventory.inventory, "판매가")
		cell.pressed.connect(on_sell.bind(i))
		cell.right_pressed.connect(on_sell.bind(i, true))
		my_inventory_grid.add_child(cell)
		_my_cells.append(cell)


func _build_barter_cells() -> void:
	_clear_grid(barter_inventory_grid)
	_sell_cells.clear()
	_buy_cells.clear()

	for i in sell_slots.size():
		var cell := _make_cell("SellSlot%d" % i, i, sell_slots, "판매가")
		cell.pressed.connect(on_sell_return.bind(i))
		cell.right_pressed.connect(on_sell_return.bind(i, true))
		barter_inventory_grid.add_child(cell)
		_sell_cells.append(cell)

	for i in buy_slots.size():
		var cell := _make_cell("BuySlot%d" % i, i, buy_slots, "구매가")
		cell.pressed.connect(on_buy_return.bind(i))
		cell.right_pressed.connect(on_buy_return.bind(i, true))
		barter_inventory_grid.add_child(cell)
		_buy_cells.append(cell)


func _build_shop_cells() -> void:
	_clear_grid(shop_inventory_grid)
	_shop_cells.clear()

	for i in shop_slots.size():
		var cell := _make_cell("ShopSlot%d" % i, i, shop_slots, "구매가")
		cell.pressed.connect(on_buy.bind(i))
		cell.right_pressed.connect(on_buy.bind(i, true))
		shop_inventory_grid.add_child(cell)
		_shop_cells.append(cell)


func on_confirm() -> void:
	var stats := _player_stats()
	if stats == null:
		return

	var net := _net_value()
	if net < 0 and stats.gold < -net:
		return
	if _slots_after_trade() > Inventory.BASE_INVENTORY_LIMIT:
		return

	for i in buy_slots.size():
		if buy_slots[i] == null:
			continue
		if Inventory.add_item(buy_slots[i]):
			buy_slots[i] = null

	for i in sell_slots.size():
		if sell_slots[i] == null:
			continue
		_transfer(sell_slots, i, shop_slots, sell_slots[i].amount)

	stats.gold += net
	Inventory.inventory_updated.emit()
	refresh()


func on_cancel() -> void:
	_restore_table()
	refresh()


func _update_settle() -> void:
	var net := _net_value()
	var used := _slots_after_trade()
	var stats := _player_stats()

	var over := used > Inventory.BASE_INVENTORY_LIMIT
	var broke := net < 0 and (stats == null or stats.gold < -net)

	gold_label.text = "0" if net == 0 else "%+d" % net
	gold_label.modulate = COLOR_BAD if broke else COLOR_OK
	slot_label.text = "%d / %d" % [used, Inventory.BASE_INVENTORY_LIMIT]
	slot_label.modulate = COLOR_BAD if over else COLOR_OK
	confirm_button.disabled = over or broke or _table_is_empty()


func _net_value() -> int:
	var gain := 0
	var cost := 0

	for stack in sell_slots:
		if stack != null:
			gain += roundi(stack.item.value * sell_multiplier) * stack.amount
	for stack in buy_slots:
		if stack != null:
			cost += stack.item.value * stack.amount

	return gain - cost


func _slots_after_trade() -> int:
	var room: Dictionary = {}
	var used := 0

	for stack in Inventory.inventory:
		if stack == null:
			continue
		used += 1
		var space := stack.free_space()
		if space > 0:
			room[stack.item.item_id] = room.get(stack.item.item_id, 0) + space

	for stack in buy_slots:
		if stack == null:
			continue

		var id: String = stack.item.item_id
		var poured: int = mini(room.get(id, 0), stack.amount)
		room[id] = room.get(id, 0) - poured

		var left := stack.amount - poured
		if left <= 0:
			continue

		var per := ItemStack.slot_capacity(stack.item)
		var added := ceili(left / float(per))
		used += added
		room[id] = room.get(id, 0) + added * per - left

	return used


func _table_is_empty() -> bool:
	return sell_slots.count(null) == sell_slots.size() and buy_slots.count(null) == buy_slots.size()


func _player_stats() -> BaseCharacterStats:
	var player := get_tree().get_first_node_in_group("player") as Player
	return player.stats if player != null else null


func on_sell(index: int, half: bool = false) -> void:
	_move(Inventory.inventory, index, sell_slots, half)


func on_sell_return(index: int, half: bool = false) -> void:
	_move(sell_slots, index, Inventory.inventory, half)


func on_buy(index: int, half: bool = false) -> void:
	_move(shop_slots, index, buy_slots, half)


func on_buy_return(index: int, half: bool = false) -> void:
	_move(buy_slots, index, shop_slots, half)


func _move(from: Array[ItemStack], index: int, to: Array[ItemStack], half: bool) -> void:
	var stack: ItemStack = from[index] if index >= 0 and index < from.size() else null
	if stack == null or not stack.is_valid():
		return

	var count: int = ceili(stack.amount / 2.0) if half else 1
	if _transfer(from, index, to, count) <= 0:
		return

	if is_same(from, Inventory.inventory) or is_same(to, Inventory.inventory):
		Inventory.inventory_updated.emit()
	refresh()


func _transfer(from: Array[ItemStack], index: int, to: Array[ItemStack], count: int) -> int:
	var stack := from[index]
	var moved := 0

	while moved < count and stack.amount > 0 and _push(to, stack.item):
		stack.amount -= 1
		moved += 1

	if stack.amount <= 0:
		from[index] = null

	return moved


func _push(slots: Array[ItemStack], spec: Item) -> bool:
	var incoming := ItemStack.new(spec, 1)

	for stack in slots:
		if stack != null and stack.can_stack(incoming):
			stack.amount += 1
			return true

	var free := slots.find(null)
	if free == -1:
		return false

	slots[free] = incoming
	return true


func _restore_table() -> void:
	_drain(sell_slots, Inventory.inventory)
	_drain(buy_slots, shop_slots)
	Inventory.inventory_updated.emit()


func _drain(from: Array[ItemStack], to: Array[ItemStack]) -> void:
	for i in from.size():
		if from[i] == null:
			continue
		_transfer(from, i, to, from[i].amount)


func _make_cell(cell_name: String, index: int, source: Array, price_label: String) -> InventorySlot:
	var cell: InventorySlot = INVENTORY_SLOT.instantiate()
	cell.name = cell_name
	cell.slot_index = index
	cell.source = source
	cell.expand_icon = true
	cell.draggable = false
	cell.price_label = price_label
	return cell


func _clear_grid(grid: GridContainer) -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()


func _paint(cells: Array[InventorySlot], source: Array) -> void:
	for i in cells.size():
		var stack: ItemStack = source[i] if i < source.size() else null
		if stack == null:
			cells[i].clear()
		else:
			cells[i].set_slot(stack)
