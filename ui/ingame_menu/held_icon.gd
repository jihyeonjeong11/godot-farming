extends TextureRect

@onready var amount_label: Label = $AmountLabel


func _ready() -> void:
	top_level = true
	InventoryManager.held_changed.connect(_refresh)
	_refresh()


func _process(_delta: float) -> void:
	_follow_mouse()


func _follow_mouse() -> void:
	global_position = get_global_mouse_position() - size / 2.0


func _refresh() -> void:
	var held := InventoryManager.held_stack
	var holding := held != null and held.is_valid()
	visible = holding
	set_process(holding)
	if not holding:
		return
	texture = held.item.item_texture
	amount_label.text = str(held.amount)
	amount_label.visible = held.amount > 1
	_follow_mouse()
