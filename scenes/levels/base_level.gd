extends Node2D

@export var level_key: DataTypes.Levels


func _notification(what: int) -> void:
	if what == NOTIFICATION_READY:
		move_child(get_node(^"Player"), -1)
