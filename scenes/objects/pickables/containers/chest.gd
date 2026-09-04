extends "res://scenes/objects/pickables/containers/container.gd"

const ITEM_STACK_INSTANCE := preload("res://scenes/objects/pickables/item_stack_instance.tscn")

@export var dropped_item: Item

@onready var hurt_component: HurtComponent = $HurtComponent


func _ready() -> void:
	super()
	hurt_component.hurt.connect(on_hurt)


func on_hurt(_hit_damage: int) -> void:
	if not inventory_component.is_empty():
		return

	var drop := ITEM_STACK_INSTANCE.instantiate() as ItemStackInstance
	drop.stack = ItemStack.new(dropped_item, 1)
	drop.position = position
	get_parent().add_child.call_deferred(drop)
	queue_free()
	

func capture_state() -> Variant:
	return inventory_component.capture()

func apply_state(state: Variant) -> void:
	if state is Array:
		inventory_component.apply(state)
