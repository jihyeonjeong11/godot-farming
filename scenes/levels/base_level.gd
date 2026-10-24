class_name Base_level extends Node2D

@export var dialogue_resource: DialogueResource
@export var level_key: DataTypes.Levels
const UI_MANAGER = preload("uid://bqrbyohvqh031")


var interface: CanvasLayer

@onready var dev_info: CanvasLayer = $DevInfo
@onready var target_label: Label = $DevInfo/TargetLabel

func _ready() -> void :
	#SessionState.cinematic_stack_size = 0

	interface = UI_MANAGER.instantiate()
	add_child(interface)
	dev_info.visible = OS.is_debug_build()
	if dev_info.visible:
		get_tree().process_frame.connect(update_dev_info)
#
	#if not has_interface:
		#interface.hud.hide()
	_enter()
	
func _enter() -> void:
	pass

func update_dev_info() -> void:
	var tile = SessionState.target_dict["tile"]
	var target_object = SessionState.target_dict["object"]
	var object_name: String = target_object.object.object_name if is_instance_valid(target_object) else "-"
	target_label.text = "tile: %s\nobject: %s" % [tile if tile else "-", object_name]

func dialogue(key: String) -> void :
	SignalBus.request_dialogue(dialogue_resource, key)

func _notification(what: int) -> void:
	if what == NOTIFICATION_READY:
		move_child(get_node(^"Player"), -1)
