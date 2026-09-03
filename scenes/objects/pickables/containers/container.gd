extends Sprite2D

@export var initial_items: Array[Item] = []
@export var initial_amounts: Array[int] = []

@onready var inventory_component: ContainerInventoryComponent = $ContainerInventoryComponent


func _ready() -> void:
	if not initial_items.is_empty():
		inventory_component.fill(initial_items, initial_amounts)

func interact() -> void:
	SignalBus.container_opened.emit(inventory_component.slots)


func capture_state() -> Variant:
	return inventory_component.capture()


func apply_state(state: Variant) -> void:
	if state is Array:
		inventory_component.apply(state)
