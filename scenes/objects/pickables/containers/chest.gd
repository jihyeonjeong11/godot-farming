extends "res://scenes/objects/pickables/containers/container.gd"

const DROPPED_ITEM := preload("res://scenes/objects/pickables/dropped_item.tscn")

@export var dropped_item: Items

@onready var hurt_component: HurtComponent = $HurtComponent


func _ready() -> void:
	super()
	hurt_component.hurt.connect(on_hurt)


func on_hurt(_hit_damage: int) -> void:
	if not inventory_component.is_empty():
		return

	var drop := DROPPED_ITEM.instantiate() as Node2D
	drop.item = dropped_item
	drop.position = position
	get_parent().add_child.call_deferred(drop)
	queue_free()
	

func capture_state() -> Variant:
	return inventory_component.capture()

func apply_state(state: Variant) -> void:
	if state is Array:
		inventory_component.apply(state)
