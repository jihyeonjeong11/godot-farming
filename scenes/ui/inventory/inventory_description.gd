class_name InventoryDescription
extends Panel
## 선택한 슬롯의 아이템 정보를 보여주는 패널.
##
## 라벨 구성은 이 스크립트만 안다. 바깥에서는 show_item / clear만 부른다.

@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var desc_label: Label = $MarginContainer/VBoxContainer/DescLabel


func _ready() -> void:
	clear()


func show_item(item: Items, amount: int) -> void:
	if item == null:
		clear()
		return

	name_label.text = item.item_name if amount <= 1 else "%s x%d" % [item.item_name, amount]
	desc_label.text = item.description


func clear() -> void:
	name_label.text = ""
	desc_label.text = ""
