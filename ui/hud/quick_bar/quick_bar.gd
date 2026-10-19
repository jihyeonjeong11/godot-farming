extends Control

@onready var slot_container: HBoxContainer = $CenterContainer/MarginContainer/HBoxContainer

func _ready() -> void:
	var group := ButtonGroup.new()
	for i in slot_container.get_child_count():
		var slot: BaseInventorySlot = slot_container.get_child(i)
		slot.toggle_mode = true
		slot.button_group = group
		slot.pressed.connect(InventoryActions.select.bind(i))

	InventoryManager.updated_inventory.connect(refresh)
	InventoryManager.stack_selected.connect(show_selected)
	refresh()
	show_selected(GameState.selected_slot)

func show_selected(index: int) -> void:
	if index < 0 or index >= slot_container.get_child_count():
		return
	var slot: BaseInventorySlot = slot_container.get_child(index)
	slot.button_pressed = true


func refresh() -> void:
	for i in slot_container.get_child_count():
		var slot: BaseInventorySlot = slot_container.get_child(i)
		slot.set_stack(InventoryManager.get_item_stack_by_index(i))
