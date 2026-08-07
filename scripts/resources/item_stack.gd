class_name ItemStack extends Resource

@export var item: Items
@export var amount: int = 1


func _init(p_item: Items = null, p_amount: int = 1) -> void:
	item = p_item
	amount = p_amount


func can_stack(other: Items) -> bool:
	if item == null or item != other:
		return false
	if item.max_stack <= 0:
		return false
	return amount < item.max_stack
