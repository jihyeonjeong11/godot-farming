class_name SpawnPoint
extends Node2D
## 다른 씬에서 문으로 넘어온 플레이어가 설 자리.
##
## 씬마다 플레이어가 통째로 박혀 있으므로, 넘어온 뒤 그 자리에서 이쪽으로 옮겨진다.
## 옮기는 일은 game.gd가 한다.

const GROUP: StringName = &"spawn_points"

## 문 쪽 target_spawn 이 부르는 이름. 한 씬에 여럿이면 서로 달라야 한다.
@export var spawn_id: StringName = &"entrance"


func _ready() -> void:
	add_to_group(GROUP)
