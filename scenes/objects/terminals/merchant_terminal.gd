extends Sprite2D

@export var initial_items: Array[Items] = []
@export var initial_amounts: Array[int] = []

@onready var inventory_component: ContainerInventoryComponent = $ContainerInventoryComponent


func _ready() -> void:
	pass


func interact() -> void:
	SignalBus.barter_opened.emit()


#func capture_state() -> Variant:
	#return inventory_component.capture()
#
#
#func apply_state(state: Variant) -> void:
	#if state is Array:
		#inventory_component.apply(state)
