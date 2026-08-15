extends CanvasLayer
## 상자를 열었을 때 뜨는 격자.
##
## 칸은 플레이어 인벤토리(ApoSceneIngameOverlayMenu)와 같은 ApoInventorySlot을
## 그대로 쓴다. 어느 상자인지는 SignalBus로 받으므로 상자가 어디 있는지 몰라도 된다.

const INVENTORY_SLOT = preload("uid://byt1lfm4vsyc4")

@onready var grid: GridContainer = %ContainerGrid

## 상자의 배열을 그대로 붙든다. 복사하면 넣고 뺀 것이 상자에 안 남는다.
var slots: Array = []

var _cells: Array[ApoInventorySlot] = []


func _ready() -> void:
	visible = false
	SignalBus.container_opened.connect(open)
	# 칸을 끌어 옮기면 이 신호가 온다. 가방 쪽 변화도 상자 격자에 바로 비친다.
	Inventory.inventory_updated.connect(refresh)


func open(target_slots: Array) -> void:
	# 열어둔 상자를 또 우클릭하면 닫는다.
	if visible and is_same(slots, target_slots):
		close()
		return

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


func _rebuild() -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()

	_cells.clear()

	for i in slots.size():
		var cell: ApoInventorySlot = INVENTORY_SLOT.instantiate()
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
