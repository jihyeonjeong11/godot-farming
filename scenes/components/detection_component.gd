class_name DetectionComponent
extends Area2D

@export var min_detection_range: int
@export var max_detection_range: int
@export var sight_ray: RayCast2D



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func get_player() -> Player:
	return get_tree().get_first_node_in_group("player")

func can_see_player() -> bool:
	var player := get_player()
	if player == null:
		return false
	if sight_ray == null:
		return true
	sight_ray.target_position = sight_ray.to_local(player.global_position)
	sight_ray.force_raycast_update()
	return sight_ray.get_collider() == player


func is_player_in_range() -> bool:
	var player := get_player()
	if player == null:
		return false
	var distance_to_player := global_position.distance_to(player.global_position)
	if distance_to_player >= max_detection_range or distance_to_player <= min_detection_range:
		return false
	return can_see_player()
