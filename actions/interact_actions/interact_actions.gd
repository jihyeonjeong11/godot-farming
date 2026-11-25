class_name InteractActions extends RefCounted

static func interact() -> void:
	if CursorActions.is_at_door():
		var building = SessionState.target_dict["building"]
		if building.on_interact:
			building.on_interact()
		return
	var instance = SessionState.target_dict["object"]
	if is_instance_valid(instance):
		instance.on_interact()
		return
	InventoryActions.consume(GameState.selected_slot)
