class_name CharacterDirectionComponent
extends Node

const DIR_SUFFIX := {
	Vector2.UP: "back",
	Vector2.LEFT: "left",
	Vector2.DOWN: "front",
	Vector2.RIGHT: "right",
}

var _facing: Vector2 = Vector2.DOWN


func get_facing() -> Vector2:
	return _facing


func get_suffix() -> String:
	return DIR_SUFFIX[_facing]


func set_facing(direction: Vector2) -> void:
	if DIR_SUFFIX.has(direction):
		_facing = direction
