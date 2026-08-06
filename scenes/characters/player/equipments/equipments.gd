class_name Equipments
extends Node2D

@export var selected_item: Items
## 0~9
@export var selected_item_index: int

func select_item(index:int) -> void:
	var item = Inventory.get_item(index)
	if item == null:
		return
	selected_item = item
	selected_item_index = index
	# quick bar update

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
