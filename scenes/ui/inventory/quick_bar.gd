extends Control
## 퀵바. 인벤토리 앞 QUICKBAR_LIMIT칸을 그대로 비춘다.

const INVENTORY_SLOT = preload("uid://byt1lfm4vsyc4")

@onready var h_box_container: HBoxContainer = $QuickbarContainer/MarginContainer/HBoxContainer

var slots: Array[ApoInventorySlot] = []

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.is_echo()):
		return

	var index := -1
	if event.keycode >= KEY_1 and event.keycode <= KEY_9:
		index = event.keycode - KEY_1
	elif event.keycode == KEY_0:
		index = slots.size() - 1

	if index < 0 or index >= slots.size():
		return

	print("Equipped Weapon %d" % (index + 1))
	slots[index].grab_focus()
	get_viewport().set_input_as_handled()

func _ready() -> void:
	for child in h_box_container.get_children():
		h_box_container.remove_child(child)
		child.queue_free()

	for i in Inventory.QUICKBAR_LIMIT:
		var slot: ApoInventorySlot = INVENTORY_SLOT.instantiate()
		slot.name = "Quickbar%d" % i
		# 퀵바 i번은 Inventory.inventory[i]와 같은 칸이라 인덱스를 그대로 쓴다.
		slot.slot_index = i
		h_box_container.add_child(slot)
		slots.append(slot)

	Inventory.inventory_updated.connect(refresh)
	refresh()


func refresh() -> void:
	for i in slots.size():
		var slot = Inventory.get_item(i)
		if slot == null:
			slots[i].clear()
		else:
			slots[i].set_slot(slot)
