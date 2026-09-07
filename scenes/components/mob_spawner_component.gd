class_name MobSpawnerComponent
extends Node2D

@export var mob_scene: PackedScene
@export var spawn_radius: float = 200.0
@export var spawn_count: int = 1

var heat_score: int = 0
var prev_hour: int = -1


func _ready() -> void:
	SignalBus.time_tick.connect(on_time_tick)


func on_time_tick(_day: int, hour: int, _minute: int) -> void:
	if hour == prev_hour:
		return

	var is_first_tick := prev_hour < 0
	prev_hour = hour

	if is_first_tick:
		return

	generate_horde()


func generate_horde() -> void:
	if mob_scene == null:
		return

	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		return

	var host := get_parent()
	if host == null:
		return

	for i in spawn_count:
		var mob := mob_scene.instantiate() as Node2D
		if mob == null:
			continue

		host.add_child(mob)
		mob.global_position = player.global_position + spawn_offset()


func spawn_offset() -> Vector2:
	return Vector2.RIGHT.rotated(randf() * TAU) * spawn_radius


func reset_score() -> void:
	pass
