class_name DropPopComponent
extends Node

@export var hop_height := 10.0
@export var rise_time := 0.16
@export var fall_time := 0.12
@export var bounce_ratio := 0.35


func _ready() -> void:
	var sprite := get_parent() as Sprite2D
	if sprite == null:
		push_warning("부모가 Sprite2D가 아님: %s" % get_parent().name)
		return

	sprite.offset.y = 0.0

	var tween := create_tween()
	_add_hop(tween, sprite, hop_height, rise_time, fall_time)
	if bounce_ratio > 0.0:
		_add_hop(tween, sprite, hop_height * bounce_ratio, rise_time * 0.5, fall_time * 0.5)


func _add_hop(tween: Tween, sprite: Sprite2D, height: float, up: float, down: float) -> void:
	tween.tween_property(sprite, "offset:y", -height, up) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "offset:y", 0.0, down) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
