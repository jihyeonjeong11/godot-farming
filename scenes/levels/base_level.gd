class_name Base_level extends Node2D

@export var dialogue_resource: DialogueResource
@export var level_key: DataTypes.Levels
const UI_MANAGER = preload("uid://bqrbyohvqh031")


var interface: CanvasLayer
func _ready() -> void :
	#SessionState.cinematic_stack_size = 0

	interface = UI_MANAGER.instantiate()
	add_child(interface)
#
	#if not has_interface:
		#interface.hud.hide()
	_enter()
	
func _enter() -> void:
	pass

func dialogue(key: String) -> void :
	SignalBus.request_dialogue(dialogue_resource, key)

func _notification(what: int) -> void:
	if what == NOTIFICATION_READY:
		move_child(get_node(^"Player"), -1)
