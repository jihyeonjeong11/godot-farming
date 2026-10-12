extends Node2D

@export var level_key: DataTypes.Levels

func dialogue(key: String) -> void:
	SignalBus.dialogue_requested(key)

func _notification(what: int) -> void:
	if what == NOTIFICATION_READY:
		move_child(get_node(^"Player"), -1)
