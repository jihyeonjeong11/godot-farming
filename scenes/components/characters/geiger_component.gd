class_name GeigerComponent
extends Node

const SEGMENTS: Array[Vector2] = [Vector2(0.0, 4.0), Vector2(4.0, 9.0), Vector2(9.0, 13.0)]

@export var band_thresholds: Array[float] = [3.0, 7.0]

var sources: Array[ObjectInstance] = []
var _segment: int = -1

@onready var audio: AudioStreamPlayer = $AudioStreamPlayer


func add_source(source: ObjectInstance) -> void:
	if not sources.has(source):
		sources.append(source)


func remove_source(source: ObjectInstance) -> void:
	sources.erase(source)


func _process(_delta: float) -> void:
	for i in range(sources.size() - 1, -1, -1):
		if not is_instance_valid(sources[i]):
			sources.remove_at(i)

	var intensity := get_intensity()
	if intensity <= 0.0:
		if audio.playing:
			audio.stop()
		_segment = -1
		return

	var segment := 0
	for threshold in band_thresholds:
		if intensity >= threshold:
			segment += 1
	segment = mini(segment, SEGMENTS.size() - 1)

	if segment != _segment:
		_segment = segment
		audio.play(SEGMENTS[segment].x)
	elif not audio.playing or audio.get_playback_position() >= SEGMENTS[segment].y:
		audio.play(SEGMENTS[segment].x)


func get_intensity() -> float:
	var listener := get_parent() as Node2D
	if listener == null:
		return 0.0

	var best := 0.0
	for source in sources:
		var object := source.object
		if object == null or object.radiation_range <= 0.0:
			continue
		var falloff := 1.0 - listener.global_position.distance_to(source.global_position) / object.radiation_range
		best = maxf(best, object.radiation * clampf(falloff, 0.0, 1.0))
	return best
