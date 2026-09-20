extends Node

# 타일의 방사능, 어떤 오브젝트의 방사능 수치를 조회하기 위해 저장하는 역할임.
# feature = 방사능이나 화염 피해 같은 그거 자체임.

# swap_scene불릴때 각종 타일, 오브젝트 루프 다 돌아서 radiation같은 프로퍼티 있는거
# 다 여기 리스트에서 가짐.
# 지금은 crop이랑 플레이어만 영향을 받음
# 오브젝트 레이어 변경, 타일 변경이 일어날 시 여기 업데이트

# 지금은 radiation_barrel 하나뿐임
var object_list: Array[ObjectInstance] = []: set = _on_object_list_set, get = _get_object_list

# 지금은 특수 타일 없음
var tile_feature_list = []

const GROUP := &"map_features"
const OBJECT_GROUP := &"object"
const PLAYER_GROUP := &"player"
const GEIGER_SEGMENTS: Array[Vector2] = [Vector2(0.0, 4.0), Vector2(4.0, 9.0), Vector2(9.0, 13.0)]

@export var geiger_thresholds: Array[float] = [3.0, 7.0]

var _geiger_segment: int = -1

@onready var geiger_audio: AudioStreamPlayer = $GeigerAudio


func _ready() -> void:
	add_to_group(GROUP)
	var found: Array[ObjectInstance] = []
	for node in get_tree().get_nodes_in_group(OBJECT_GROUP):
		if node is ObjectInstance and _emits(node):
			found.append(node)
	object_list = found


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group(PLAYER_GROUP) as Node2D
	var intensity := 0.0
	if player != null:
		intensity = get_effect_intensity(player.global_position, DataTypes.InfluenceType.Radiation)
	_update_geiger(intensity)


func _update_geiger(intensity: float) -> void:
	if intensity <= 0.0:
		if geiger_audio.playing:
			geiger_audio.stop()
		_geiger_segment = -1
		return

	var segment := 0
	for threshold in geiger_thresholds:
		if intensity >= threshold:
			segment += 1
	segment = mini(segment, GEIGER_SEGMENTS.size() - 1)

	if segment != _geiger_segment:
		_geiger_segment = segment
		geiger_audio.play(GEIGER_SEGMENTS[segment].x)
	elif not geiger_audio.playing or geiger_audio.get_playback_position() >= GEIGER_SEGMENTS[segment].y:
		geiger_audio.play(GEIGER_SEGMENTS[segment].x)


func register(instance: ObjectInstance) -> void:
	if not _emits(instance) or object_list.has(instance):
		return
	object_list.append(instance)


func unregister(instance: ObjectInstance) -> void:
	object_list.erase(instance)


# 현재로써는 거리에 따른 방사능만 추가함.
func get_effect_intensity(position: Vector2, type: DataTypes.InfluenceType) -> float:
	var best := 0.0
	for instance in get_feature_by_distance(position, type):
		best = maxf(best, _intensity_from(instance, position, type))
	return best


# crop이나 player 위치와의 거리 차이
func get_feature_by_distance(position: Vector2, type: DataTypes.InfluenceType) -> Array[ObjectInstance]:
	var found: Array[ObjectInstance] = []
	for instance in object_list:
		if _intensity_from(instance, position, type) > 0.0:
			found.append(instance)
	return found


func _emits(instance: ObjectInstance) -> bool:
	var object := instance.object
	return object != null and object.radiation > 0.0 and object.radiation_range > 0.0


func _intensity_from(instance: ObjectInstance, position: Vector2, type: DataTypes.InfluenceType) -> float:
	var object := instance.object
	if object == null:
		return 0.0
	match type:
		DataTypes.InfluenceType.Radiation:
			if object.radiation <= 0.0 or object.radiation_range <= 0.0:
				return 0.0
			var falloff := 1.0 - position.distance_to(instance.global_position) / object.radiation_range
			return object.radiation * clampf(falloff, 0.0, 1.0)
	return 0.0


func _on_object_list_set(value: Array[ObjectInstance]) -> void:
	var next: Array[ObjectInstance] = []
	for instance in value:
		if is_instance_valid(instance) and not next.has(instance):
			next.append(instance)
	object_list = next


func _get_object_list() -> Array[ObjectInstance]:
	for i in range(object_list.size() - 1, -1, -1):
		if not is_instance_valid(object_list[i]):
			object_list.remove_at(i)
	return object_list
