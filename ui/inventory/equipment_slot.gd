class_name EquipmentSlot
extends InventorySlot
## 착용 부위 하나를 받아주는 칸.
##
## 맞바꾸기와 그리기는 전부 InventorySlot 이 한다. 이쪽이 더하는 것은
## "이 부위에 맞는 물건인가" 하나뿐이다.

## 이 칸이 받아주는 부위. EquipmentPanel 이 source·slot_index 와 함께 꽂아준다.
@export var slot_type: DataTypes.WearSlot = DataTypes.WearSlot.None


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not super(at_position, data):
		return false

	var from_source: Array = data["from_source"]
	var from_index: int = data["from_index"]
	if from_index < 0 or from_index >= from_source.size():
		return false

	var item_stack: ItemStack = from_source[from_index]
	if item_stack == null or item_stack.item == null:
		return false

	# 부위가 맞아야만 들어온다. 신발을 갑옷 칸에 끼우지 못하게 막는 곳이 여기다.
	return item_stack.item.wear_slot == slot_type
