class_name Actionable extends DialogueActionable2D

func _ready() -> void :
	if not Engine.is_editor_hint():
		add_to_group("dialogue_actionables")
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _exit_tree() -> void :
	if not Engine.is_editor_hint():
		set_deferred("monitorable", false)


func action() -> void :
	if is_instance_valid(dialogue_resource) and not dialogue_cue.is_empty():
		dialogue_balloon = start_dialogue.call(dialogue_resource, dialogue_cue, [{actionable = self}, owner])
	actioned.emit()


static func get_nearest_actionable_to(target_position: Vector2) -> DialogueActionable2D:
	var nearest_distance: float = INF
	var nearest_actionable: DialogueActionable2D = null
	var actionables: Array[Node] = (Engine.get_main_loop() as SceneTree).get_nodes_in_group("dialogue_actionables")
	for actionable: DialogueActionable2D in actionables:
		var distance: float = actionable.global_position.distance_squared_to(target_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_actionable = actionable

	return nearest_actionable







func _on_dialogue_ended(ending_dialogue_resource: DialogueResource) -> void :
	if ending_dialogue_resource == dialogue_resource:
		dialogue_ended.emit()
