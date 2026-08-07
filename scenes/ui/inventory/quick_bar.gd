extends Control

const INVENTORY_SLOT = preload("uid://byt1lfm4vsyc4")

@onready var h_box_container: HBoxContainer = $QuickbarContainer/MarginContainer/HBoxContainer

var slots: Array[ApoInventorySlot] = []

func _ready() -> void:
	for child in h_box_container.get_children():
		h_box_container.remove_child(child)
		child.queue_free()

	for i in Inventory.QUICKBAR_LIMIT:
		var slot: ApoInventorySlot = INVENTORY_SLOT.instantiate()
		slot.name = "Quickbar%d" % i
		slot.slot_index = i
		h_box_container.add_child(slot)
		slots.append(slot)

	Inventory.inventory_updated.connect(refresh)
	Inventory.selected_slot_changed.connect(focus_slot)

	refresh()
	focus_slot(Inventory.selected_slot)


func focus_slot(index: int) -> void:
	if index < 0 or index >= slots.size():
		return
	slots[index].grab_focus()


func refresh() -> void:
	for i in slots.size():
		var stack := Inventory.get_item(i)
		if stack == null:
			slots[i].clear()
		else:
			slots[i].set_slot(stack)
