class_name ObjectCursorComponent
extends Node

var interactable_group: StringName = &"interactables"

# TODO: 플레이어 스탯으로 올라감. 지금은 player.gd BARE_REACH(18)와 따로 논다.
var player_interaction_range = 44.0

@export var debug_log: bool = true


func _ready() -> void:
	SignalBus.interact_used.connect(on_interact)

	if debug_log:
		print("[ObjectCursor] 0) 연결됨 ", get_path())

func on_interact(user_position: Vector2, cursor_position: Vector2) -> void:
	var candidates := get_tree().get_nodes_in_group(interactable_group)

	var closest_handler: Object = null
	var closest_distance := INF

	for candidate in candidates:
		var object := candidate as Node2D
		if object == null:
			continue
			
		if object.global_position.distance_to(user_position) > player_interaction_range:
			continue

		var candidate_distance := object.global_position.distance_to(cursor_position)
		if candidate_distance >= closest_distance:
			continue

		var handler := resolve_handler(object)
		if handler == null:
			continue

		closest_handler = handler
		closest_distance = candidate_distance

	if closest_handler == null:
		return

	closest_handler.call(&"interact")

	SignalBus.interact_handled = true


func resolve_handler(object: Node2D) -> Object:
	for child in object.get_children():
		var component := child as InteractableComponent
		if component == null:
			continue

		return component if component.enabled else null

	return object if object.has_method(&"interact") else null
