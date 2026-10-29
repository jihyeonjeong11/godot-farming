extends Node

signal changing_scene(next_scene_path: String)

var is_transitioning: bool = false

var scene_path: String = ""
## 다음 씬에서 플레이어가 설 SpawnPoint 의 spawn_id. 도착한 SpawnPoint 가 읽고 비운다.
var next_spawn_id: StringName = &""

func _ready() -> void:
	pass

func go_to_scene(next_scene: Variant, spawn_id: StringName = &"") -> void :
	scene_path = next_scene if next_scene is String else next_scene.resource_path
	next_spawn_id = spawn_id
	# change_scene_to_file 은 현재 씬을 즉시 트리에서 뗀다. 입력 처리 도중(문 우클릭 등)에
	# 불리면 호출한 쪽이 트리 밖에서 get_viewport() 를 부르게 되므로 프레임 끝으로 미룬다.
	_swap_scene.call_deferred()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _swap_scene() -> void :
	if not scene_path.is_empty():
		changing_scene.emit(scene_path)
		var err = get_tree().change_scene_to_file(scene_path)
		assert (err == OK, "Cannot find scene \"%s\"" % scene_path)
