class_name LevelLayer
extends Node2D


const GROUP := &"level_layer"
const OBJECT_GROUP := &"object"

@export var layer_id: StringName = &"objects"


func _ready() -> void:
	add_to_group(GROUP)

	apply(SaveAndLoad.load_layer(self, layer_id))


func capture() -> Variant:
	var entries := {}

	for child in get_children():
		if child.is_queued_for_deletion() or not child.is_in_group(OBJECT_GROUP):
			continue

		var object := child as Node2D
		if object == null:
			continue

		if object.scene_file_path.is_empty():
			push_warning("scene_file_path가 없어 저장할 수 없다: %s" % object.name)
			continue

		var entry := {
			"scene": object.scene_file_path,
			"position": object.position,
		}

		var instance := object as ObjectInstance
		if instance != null and instance.object != null and not instance.object.resource_path.is_empty():
			entry["object"] = instance.object.resource_path

		if object.has_method(&"capture_state"):
			entry["state"] = object.call(&"capture_state")

		entries[String(object.name)] = entry

	return entries


## 세이브가 없으면(null) 씬에 놓인 그대로 둔다.
func apply(state: Variant) -> void:
	if state is not Dictionary:
		return

	# 다시 깔기 전에 비운다. queue_free만 하면 프레임 끝까지 남아 새것과 겹친다.
	for child in get_children():
		remove_child(child)
		child.queue_free()

	for object_name in state:
		var entry: Dictionary = state[object_name]

		var packed := load(entry["scene"]) as PackedScene
		if packed == null:
			push_error("씬을 불러오지 못했다: %s" % entry["scene"])
			continue

		var object := packed.instantiate() as Node2D
		object.name = String(object_name)
		object.position = entry["position"]

		if entry.has("object") and object is ObjectInstance:
			(object as ObjectInstance).object = load(entry["object"]) as PlaceableObject

		add_child(object)

		# add_child 다음이라야 한다. 그 전에는 자식 컴포넌트의 _ready가 아직 안 돌아
		# 받아둘 그릇이 없다.
		if entry.has("state") and object.has_method(&"apply_state"):
			object.call(&"apply_state", entry["state"])
