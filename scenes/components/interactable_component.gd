class_name InteractableComponent
extends Node

const INTERACTABLE_GROUP: StringName = &"interactables"

signal interacted

@export var enabled: bool = true

var _target: Node2D


func _ready() -> void:
	_target = get_parent() as Node2D

	if _target == null:
		push_warning("InteractableComponent의 부모가 Node2D가 아니다: %s" % get_path())
		return

	_target.add_to_group(INTERACTABLE_GROUP)


func interact() -> void:
	interacted.emit()
