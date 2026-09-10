class_name ObjectInstance
extends Sprite2D

@export var object: PlaceableObject: set = set_object

var current_health: int

func _ready() -> void:
	_refresh()


func set_object(value: PlaceableObject) -> void:
	current_health = value.object_max_health
	object = value
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	if object == null:
		return

	texture = object.object_texture
