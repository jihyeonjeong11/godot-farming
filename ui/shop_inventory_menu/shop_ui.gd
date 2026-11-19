class_name ShopUI
extends CanvasLayer

const SLOT := preload("res://ui/reusables/bases/base_inventory_slot.tscn")
const COLUMNS := 5
const COLOR_OK := Color(0.95, 0.78, 0.35)
const COLOR_BAD := Color(0.9, 0.35, 0.3)

@export var sell_slot_count: int = 5
@export var buy_slot_count: int = 5

@onready var inventory_panel: PanelContainer = %InventoryPanel
@onready var sell_grid: GridContainer = %SellGrid
@onready var buy_grid: GridContainer = %BuyGrid
@onready var shop_grid: GridContainer = %ShopGrid
@onready var gold_label: Label = %GoldLabel
@onready var confirm_button: Button = %ConfirmButton
@onready var cancel_button: Button = %CancelButton

var shop_slots: Array = []
var sell_slots: Array = []
var buy_slots: Array = []

var _sell_cells: Array[BaseInventorySlot] = []
var _buy_cells: Array[BaseInventorySlot] = []
var _shop_cells: Array[BaseInventorySlot] = []


func _ready() -> void:
	SignalBus.pause_game()
	inventory_panel.inventory_grid.columns = COLUMNS
	InventoryManager.held_changed.connect(refresh)
	InventoryManager.updated_inventory.connect(refresh)
	confirm_button.pressed.connect(on_confirm)
	cancel_button.pressed.connect(on_cancel)

	sell_slots.resize(sell_slot_count)
	buy_slots.resize(buy_slot_count)

	_sell_cells = _build_cells(sell_grid, sell_slots.size(), _on_sell_clicked)
	_buy_cells = _build_cells(buy_grid, buy_slots.size(), _on_buy_clicked)
	_shop_cells = _build_cells(shop_grid, shop_slots.size(), _on_shop_clicked)
	refresh()


func refresh() -> void:
	_paint(_sell_cells, sell_slots)
	_paint(_buy_cells, buy_slots)
	_paint(_shop_cells, shop_slots)
	_update_settle()


func close() -> void:
	InventoryActions.return_held()
	_restore_table()
	SignalBus.pause_game(false)
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ingame_pause"):
		get_viewport().set_input_as_handled()
		close()


func on_confirm() -> void:
	var stats := GameState.player_stat
	if stats == null:
		return
	var net := _net_value()
	if net < 0 and stats.gold < -net:
		return

	for i in buy_slots.size():
		var stack: ItemStack = buy_slots[i]
		if stack == null:
			continue
		var left := InventoryManager.add_item_stack(stack)
		if left > 0:
			stack.amount = left
			continue
		buy_slots[i] = null

	for i in sell_slots.size():
		if sell_slots[i] != null:
			_move(sell_slots, i, shop_slots)

	stats.gold += net
	InventoryManager.updated_inventory.emit()
	refresh()


func on_cancel() -> void:
	_restore_table()
	refresh()


func _on_sell_clicked(button: MouseButton, shift: bool, index: int) -> void:
	match button:
		MOUSE_BUTTON_LEFT:
			InventoryActions.select_stack_in(sell_slots, index)
		MOUSE_BUTTON_RIGHT:
			InventoryActions.select_split_stack_in(sell_slots, index, shift)
	refresh()


func _on_buy_clicked(button: MouseButton, _shift: bool, index: int) -> void:
	if button == MOUSE_BUTTON_LEFT and InventoryManager.held_stack == null:
		_move(buy_slots, index, shop_slots)


func _on_shop_clicked(button: MouseButton, _shift: bool, index: int) -> void:
	if button == MOUSE_BUTTON_LEFT and InventoryManager.held_stack == null:
		_move(shop_slots, index, buy_slots)


func _move(from: Array, index: int, to: Array) -> void:
	var stack: ItemStack = from[index]
	if stack == null:
		return
	var free := to.find(null)
	if free == -1:
		if not is_same(to, shop_slots):
			return
		to.append(stack)
		_shop_cells = _build_cells(shop_grid, shop_slots.size(), _on_shop_clicked)
	else:
		to[free] = stack
	from[index] = null
	refresh()


func _restore_table() -> void:
	for i in sell_slots.size():
		var stack: ItemStack = sell_slots[i]
		if stack == null:
			continue
		var left := InventoryManager.add_item_stack(stack)
		if left > 0:
			stack.amount = left
			InventoryActions.drop(stack)
		sell_slots[i] = null
	for i in buy_slots.size():
		_move(buy_slots, i, shop_slots)
	InventoryManager.updated_inventory.emit()


func _net_value() -> int:
	var gain := 0
	var cost := 0
	for stack in sell_slots:
		if stack != null:
			gain += roundi(stack.item.value * Constants.default_sell_multiplier) * stack.amount
	for stack in buy_slots:
		if stack != null:
			cost += stack.item.value * stack.amount
	return gain - cost


func _update_settle() -> void:
	var net := _net_value()
	var stats := GameState.player_stat
	var broke := net < 0 and (stats == null or stats.gold < -net)
	var empty := sell_slots.count(null) == sell_slots.size() and buy_slots.count(null) == buy_slots.size()
	gold_label.text = "0" if net == 0 else "%+d" % net
	gold_label.modulate = COLOR_BAD if broke else COLOR_OK
	confirm_button.disabled = broke or empty


func _build_cells(grid: GridContainer, count: int, handler: Callable) -> Array[BaseInventorySlot]:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	var cells: Array[BaseInventorySlot] = []
	for i in count:
		var cell: BaseInventorySlot = SLOT.instantiate()
		cell.name = "Slot%d" % i
		grid.add_child(cell)
		cell.clicked.connect(handler.bind(i))
		cells.append(cell)
	return cells


func _paint(cells: Array[BaseInventorySlot], source: Array) -> void:
	for i in cells.size():
		cells[i].set_stack(source[i] if i < source.size() else null)
