class_name DetectionComponent
extends Area2D

@export var min_detection_range: int
@export var max_detection_range: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func get_player() -> ApoPlayer:
	return get_tree().get_first_node_in_group("player")

func is_player_in_range() -> bool:
	var result = false
	var player: = get_player()
	if player is ApoPlayer:
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player < max_detection_range and distance_to_player > min_detection_range:
			result = true
	return result
