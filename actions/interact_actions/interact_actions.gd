class_name InteractActions extends RefCounted

static func interact() -> void:
	if CursorActions.is_at_door():
		var building = SessionState.target_dict["building"]
		print(building)
		if building.inside_scene:
			TransitionManager.go_to_scene(building.inside_scene)
		return
	var instance = SessionState.target_dict["object"]
	if is_instance_valid(instance):
		instance.on_interact()
		return
	InventoryActions.consume(GameState.selected_slot)
