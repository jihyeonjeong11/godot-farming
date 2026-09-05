extends CanvasLayer

const INVENTORY_SLOT = preload("uid://byt1lfm4vsyc4")

@export var barter_slot_count: int = 12
@export var shop_slot_count: int = 30

@onready var my_inventory_grid: GridContainer = %MyInventoryGrid
@onready var barter_inventory_grid: GridContainer = %BarterInventoryGrid
@onready var shop_inventory_grid: GridContainer = %ShopInventoryGrid

var barter_slots: Array[ItemStack] = []
var shop_slots: Array[ItemStack] = []

var _my_cells: Array[InventorySlot] = []
var _barter_cells: Array[InventorySlot] = []
var _shop_cells: Array[InventorySlot] = []


func _ready() -> void:
	Inventory.inventory_updated.connect(refresh)

	barter_slots.resize(barter_slot_count)
	shop_slots.resize(shop_slot_count)

	_build(my_inventory_grid, _my_cells, Inventory.inventory, Inventory.BASE_INVENTORY_LIMIT)
	_build(barter_inventory_grid, _barter_cells, barter_slots, barter_slot_count)
	_build(shop_inventory_grid, _shop_cells, shop_slots, shop_slot_count)

	refresh()


func setup(stocks: Array[ItemStack]) -> void:
	shop_slots = stocks
	if _shop_cells.size() != shop_slots.size():
		_build(shop_inventory_grid, _shop_cells, shop_slots, shop_slots.size())
	refresh()


func refresh() -> void:
	_paint(_my_cells, Inventory.inventory)
	_paint(_barter_cells, barter_slots)
	_paint(_shop_cells, shop_slots)


func _build(grid: GridContainer, cells: Array[InventorySlot], source: Array, count: int) -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()

	cells.clear()

	for i in count:
		var cell: InventorySlot = INVENTORY_SLOT.instantiate()
		cell.name = "Slot%d" % i
		cell.slot_index = i
		cell.source = source
		cell.expand_icon = true
		grid.add_child(cell)
		cells.append(cell)


func _paint(cells: Array[InventorySlot], source: Array) -> void:
	for i in cells.size():
		var stack: ItemStack = source[i] if i < source.size() else null
		if stack == null:
			cells[i].clear()
		else:
			cells[i].set_slot(stack)
