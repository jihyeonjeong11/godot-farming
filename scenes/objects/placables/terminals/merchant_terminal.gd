extends Sprite2D

@export var initial_items: Array[Items] = []
@export var initial_amounts: Array[int] = []

@onready var inventory_component: ContainerInventoryComponent = $ContainerInventoryComponent


func _ready() -> void:
	if not initial_items.is_empty():
		inventory_component.fill(initial_items, initial_amounts)


func interact() -> void:
	SignalBus.barter_opened.emit(inventory_component.slots)
