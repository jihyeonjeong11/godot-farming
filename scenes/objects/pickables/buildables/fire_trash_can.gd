extends AnimatedSprite2D


const DROPPED_ITEM := preload("res://scenes/objects/pickables/dropped_item.tscn")

@export var dropped_item: Item

var lit := false

@onready var hurt_component: HurtComponent = $HurtComponent


func _ready() -> void:
	hurt_component.hurt.connect(on_hurt)


func interact() -> void:
	_set_lit(not lit)
	SignalBus.sound_requested.emit(
		AudioManager.SFX_FIRE_ON if lit else AudioManager.SFX_FIRE_OFF)

func on_hurt(_hit_damage: int) -> void:
	var drop := DROPPED_ITEM.instantiate() as Node2D
	drop.item = dropped_item
	drop.position = position
	get_parent().add_child.call_deferred(drop)
	queue_free()


func _set_lit(value: bool) -> void:
	lit = value
	play(&"on" if lit else &"off")


func capture_state() -> Dictionary:
	return {"lit": lit}


func apply_state(state: Dictionary) -> void:
	_set_lit(state.get("lit", false))
