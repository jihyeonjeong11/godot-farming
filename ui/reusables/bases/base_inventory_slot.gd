class_name BaseInventorySlot
extends ButtonBase

const BASE_TOOLTIP = preload("res://ui/reusables/bases/base_tooltip.tscn")

var stack: ItemStack

@onready var amount_label: Label = $AmountLabel


func set_stack(value: ItemStack) -> void:
	stack = value if value != null and value.is_valid() else null
	icon = stack.item.item_texture if stack != null else null
	tooltip_text = stack.item.item_name if stack != null else ""
	amount_label.text = str(stack.amount) if stack != null else ""
	amount_label.visible = stack != null and stack.amount > 1


func _make_custom_tooltip(_for_text: String) -> Object:
	if stack == null:
		return null
	var tip: BaseTooltip = BASE_TOOLTIP.instantiate()
	tip.show_item(stack.item)
	return tip
