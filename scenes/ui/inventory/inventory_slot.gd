class_name ApoInventorySlot
extends Button

@export var selected_item: Items

@onready var amount_label: Label = $AmountLabel


func _ready() -> void:
	clear()


func set_slot(slot: Dictionary) -> void:
	var item: Items = slot["item"]
	if item == null:
		clear()
		return

	icon = item.item_texture
	tooltip_text = "%s\n%s" % [item.item_name, item.description]
	
	amount_label.text = str(slot["amount"])
	amount_label.visible = slot["amount"] > 1


func clear() -> void:
	icon = null
	tooltip_text = ""
	amount_label.hide()
