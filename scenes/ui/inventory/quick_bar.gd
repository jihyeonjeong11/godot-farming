extends Control
## 퀵바. 인벤토리 앞 QUICKBAR_LIMIT칸을 그대로 비춘다.
##
## 별도 데이터를 들고 있지 않다. 퀵바 i번 칸은 Inventory.inventory[i]와 같은 칸이라
## 인덱스 변환이 필요 없고, 인벤토리 그리드와 자동으로 같은 내용을 보여준다.

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
