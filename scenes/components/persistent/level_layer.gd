class_name LevelLayer
extends Node2D
## 레벨에서 변하는 것들을 담는 레이어. 레벨 씬의 레이어 노드에 스크립트로 직접 붙인다.
##
## base가 Node2D지만 TileMapLayer 노드에 붙여도 된다.
## 스크립트의 base가 노드 클래스의 조상이기만 하면 Godot이 허용한다.
##
## 기본 동작은 "자식 노드를 뿌리고, 자식 노드를 떠내기"다.
## objects·nature·crops는 전부 씬 인스턴스라 이걸 그대로 쓰고,
## 타일로 저장해야 하는 갈아둔 땅만 capture/apply를 갈아끼운다.

const GROUP := &"level_layer"

## 세이브 파일에서 이 레이어를 가리키는 이름. 상속받는 쪽이 _init에서 정한다.
var layer_id: StringName

## 세이브가 없을 때(=새 게임) 깔아둘 초기 배치.
## {이름: {"scene": 경로, "position": Vector2}}
## 지금은 테스트용 딕셔너리지만, 나중에 여기만 동적으로 바꾸면 된다.
var initial_objects: Dictionary = {}


func _ready() -> void:
	add_to_group(GROUP)

	# 세이브가 없으면 null이 온다. 그때 무엇으로 시작할지는 레이어가 각자 정한다.
	apply(SaveAndLoad.load_layer(self, layer_id))


## 지금 이 레이어에 남아 있는 것을 그대로 떠낸다.
## 주웠거나 부순 것은 이미 자식에서 빠져 있으므로 "지워진 것 목록"이 필요 없다.
func capture() -> Variant:
	var entries := {}

	for child in get_children():
		# queue_free는 프레임 끝에 처리된다. 방금 주운 것이 아직 자식으로 남아 있다.
		if child.is_queued_for_deletion():
			continue

		var object := child as Node2D
		if object == null:
			continue

		# 코드로 만든 노드는 이 값이 비어 있어 다시 만들 방법이 없다.
		if object.scene_file_path.is_empty():
			push_warning("scene_file_path가 없어 저장할 수 없다: %s" % object.name)
			continue

		entries[String(object.name)] = {
			"scene": object.scene_file_path,
			"position": object.position,
		}

	return entries


## 세이브가 있으면 그걸로, 없으면(null) 초기 배치로 레이어를 채운다.
func apply(state: Variant) -> void:
	var entries: Dictionary = state if state is Dictionary else initial_objects

	# 다시 깔기 전에 비운다. queue_free만 하면 프레임 끝까지 남아 새것과 겹친다.
	for child in get_children():
		remove_child(child)
		child.queue_free()

	for object_name in entries:
		var entry: Dictionary = entries[object_name]

		var packed := load(entry["scene"]) as PackedScene
		if packed == null:
			push_error("씬을 불러오지 못했다: %s" % entry["scene"])
			continue

		var object := packed.instantiate() as Node2D
		object.name = String(object_name)
		object.position = entry["position"]
		add_child(object)
