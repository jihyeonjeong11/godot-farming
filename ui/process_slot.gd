class_name ProcessSlot
extends Control

@onready var slot: InventorySlot = %Slot
@onready var bar: ProgressBar = %Bar


func _ready() -> void:
	slot.draggable = false
	clear()


func show_result(item: Item, amount: int) -> void:
	slot.set_slot(ItemStack.new(item, amount))
	set_progress(0.0)
	show()


func set_progress(ratio: float) -> void:
	bar.value = clampf(ratio, 0.0, 1.0)


func clear() -> void:
	slot.clear()
	bar.value = 0.0
	hide()
