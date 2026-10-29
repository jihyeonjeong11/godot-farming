class_name SpawnPoint
extends Node2D
## 다른 씬에서 문으로 넘어온 플레이어가 설 자리.
##
## 씬마다 플레이어가 통째로 박혀 있으므로, 넘어온 뒤 그 자리에서 이쪽으로 옮겨진다.
## TransitionManager 로 넘어왔으면 이 노드가 직접 옮기고, game.gd 의 swap_scene 으로
## 넘어왔으면 game.gd 가 옮긴다.

const GROUP: StringName = &"spawn_points"

## 문 쪽 target_spawn 이 부르는 이름. 한 씬에 여럿이면 서로 달라야 한다.
@export var spawn_id: StringName = &"entrance"


func _ready() -> void:
	add_to_group(GROUP)
	if not spawn_id.is_empty() and TransitionManager.next_spawn_id == spawn_id:
		TransitionManager.next_spawn_id = &""
		# 씬 전체가 ready 된 뒤에 옮겨야 카메라가 먼저 맞춘 자리를 덮어쓸 수 있다.
		_move_player_here.call_deferred()


func _move_player_here() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		push_warning("스폰 지점으로 옮길 플레이어가 씬에 없다: %s" % spawn_id)
		return

	player.global_position = global_position
	var camera := get_viewport().get_camera_2d() as Camera
	if camera != null:
		camera.global_position = player.global_position + camera.follow_offset
		camera.reset_smoothing()
