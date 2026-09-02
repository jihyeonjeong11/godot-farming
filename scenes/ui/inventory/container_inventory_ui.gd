extends CanvasLayer

const INVENTORY_SLOT = preload("uid://byt1lfm4vsyc4")

@onready var grid: GridContainer = %ContainerGrid
## 상자 아래에 같이 띄우는 가방. 칸 씬은 상자와 같은 것을 쓴다.
@onready var inventory_grid: GridContainer = %InventoryGrid

var slots: Array = []

var _cells: Array[InventorySlot] = []
var _inventory_cells: Array[InventorySlot] = []


func _ready() -> void:
	Inventory.inventory_updated.connect(refresh)

	# 가방 칸수는 변하지 않으므로 한 번만 만든다. 상자 격자는 상자마다 칸수가
	# 달라서 열 때마다 다시 짓지만(_rebuild), 이쪽은 그럴 일이 없다.
	_build_inventory_cells()


## UIManager가 만든 직후에 부른다. 여닫기와 정지는 스택이 정하므로
## 여기서는 무엇을 그릴지만 받는다.
func setup(target_slots: Array) -> void:
	slots = target_slots

	if _cells.size() != slots.size():
		_rebuild()

	refresh()


func refresh() -> void:
	for i in _cells.size():
		var stack: ItemStack = slots[i] if i < slots.size() else null
		if stack == null:
			_cells[i].clear()
		else:
			_cells[i].set_slot(stack)

	for i in _inventory_cells.size():
		var bag: ItemStack = Inventory.inventory[i] if i < Inventory.inventory.size() else null
		if bag == null:
			_inventory_cells[i].clear()
		else:
			_inventory_cells[i].set_slot(bag)



func _build_inventory_cells() -> void:
	for child in inventory_grid.get_children():
		inventory_grid.remove_child(child)
		child.queue_free()

	_inventory_cells.clear()

	for i in Inventory.BASE_INVENTORY_LIMIT:
		var cell: InventorySlot = INVENTORY_SLOT.instantiate()
		cell.name = "InventorySlot%d" % i
		cell.slot_index = i
		cell.source = Inventory.inventory
		# 아이템 그림은 26px 칸보다 큰 것이 많다. 눌러 담지 않으면 옆 칸까지 넘어간다.
		cell.expand_icon = true
		inventory_grid.add_child(cell)
		_inventory_cells.append(cell)


func _rebuild() -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()

	_cells.clear()

	# 칸이 적은 상자까지 6열로 깔면 오른쪽이 텅 빈 채로 넓어진다.
	grid.columns = clampi(slots.size(), 1, 6)

	for i in slots.size():
		var cell: InventorySlot = INVENTORY_SLOT.instantiate()
		cell.name = "Slot%d" % i
		cell.slot_index = i
		# 이 칸이 가방이 아니라 상자를 보게 한다. 끌어 옮길 때 출처가 된다.
		cell.source = slots
		cell.expand_icon = true
		grid.add_child(cell)
		_cells.append(cell)
