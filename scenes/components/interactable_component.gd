class_name InteractableComponent
extends Node

## 오른쪽 클릭 대상이 되려면 이 그룹에 있어야 한다.
## ObjectCursorComponent가 그룹을 훑어서 가장 가까운 대상을 고른다.
const INTERACTABLE_GROUP: StringName = &"interactables"

## 상호작용이 들어왔을 때 부모가 받아 쓰는 신호.
signal interacted

## 잠깐 상호작용을 막고 싶을 때 끈다. 꺼두면 커서가 아예 후보에서 뺀다.
## (그냥 interact를 무시해버리면 커서가 "내가 처리했다"고 남겨서
##  손에 든 아이템 사용까지 같이 죽는다.)
@export var enabled: bool = true

var _target: Node2D


func _ready() -> void:
	_target = get_parent() as Node2D

	# 커서는 Node2D만 후보로 본다. 부모가 Node2D가 아니면 등록해봐야 무시당한다.
	if _target == null:
		push_warning("InteractableComponent의 부모가 Node2D가 아니다: %s" % get_path())
		return

	_target.add_to_group(INTERACTABLE_GROUP)


func interact() -> void:
	interacted.emit()
