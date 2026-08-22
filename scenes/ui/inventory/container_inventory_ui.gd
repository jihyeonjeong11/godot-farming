extends CanvasLayer

const INVENTORY_SLOT = preload("uid://byt1lfm4vsyc4")

@onready var grid: GridContainer = %ContainerGrid
## 상자 아래에 같이 띄우는 가방. 칸 씬은 상자와 같은 것을 쓴다.
@onready var inventory_grid: GridContainer = %InventoryGrid

var slots: Array = []

var _cells: Array[InventorySlot] = []
var _inventory_cells: Array[InventorySlot] = []


func _ready() -> void:
	visible = false
	SignalBus.container_opened.connect(open)
	Inventory.inventory_updated.connect(refresh)

	# 가방 칸수는 변하지 않으므로 한 번만 만든다. 상자 격자는 상자마다 칸수가
	# 달라서 열 때마다 다시 짓지만(_rebuild), 이쪽은 그럴 일이 없다.
	_build_inventory_cells()


func open(target_slots: Array) -> void:
	if visible and is_same(slots, target_slots):
		close()
		get_tree().paused = false
		return
	get_tree().paused = true


	slots = target_slots

	if _cells.size() != slots.size():
		_rebuild()

	visible = true
	refresh()


func close() -> void:
	visible = false


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
		inventory_grid.add_child(cell)
		_inventory_cells.append(cell)


func _rebuild() -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()

	_cells.clear()

	for i in slots.size():
		var cell: InventorySlot = INVENTORY_SLOT.instantiate()
		cell.name = "Slot%d" % i
		cell.slot_index = i
		# 이 칸이 가방이 아니라 상자를 보게 한다. 끌어 옮길 때 출처가 된다.
		cell.source = slots
		grid.add_child(cell)
		_cells.append(cell)


func _unhandled_input(event: InputEvent) -> void:
	# 키보드만 여기로 온다. Quickbar가 화면 전체를 덮는 Control이라
	# 마우스 이벤트는 GUI 단계에서 먼저 소비된다.
	if visible and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
