class_name ContainerInventoryUI
extends CanvasLayer

const SLOT := preload("res://ui/reusables/bases/base_inventory_slot.tscn")

@onready var grid: GridContainer = %ContainerGrid
@onready var title_label: Label = %TitleLabel

var slots: Array = []
var _cells: Array[BaseInventorySlot] = []


func _ready() -> void:
	SignalBus.pause_game()
	InventoryManager.held_changed.connect(refresh)


func setup(target: Array, title: String = "상자") -> void:
	slots = target
	title_label.text = title
	_build_cells()
	refresh()


func refresh() -> void:
	for i in _cells.size():
		_cells[i].set_stack(slots[i] if i < slots.size() else null)


func close() -> void:
	InventoryActions.return_held()
	SignalBus.pause_game(false)
	SignalBus.container_closed.emit(slots)
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ingame_pause"):
		get_viewport().set_input_as_handled()
		close()


func _build_cells() -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	_cells.clear()

	for i in slots.size():
		var cell: BaseInventorySlot = SLOT.instantiate()
		cell.name = "Slot%d" % i
		grid.add_child(cell)
		cell.clicked.connect(_on_slot_clicked.bind(i))
		_cells.append(cell)


func _on_slot_clicked(button: MouseButton, shift: bool, index: int) -> void:
	match button:
		MOUSE_BUTTON_LEFT:
			InventoryActions.select_stack_in(slots, index)
		MOUSE_BUTTON_RIGHT:
			InventoryActions.select_split_stack_in(slots, index, shift)
	refresh()
