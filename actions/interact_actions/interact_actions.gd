class_name InteractActions extends RefCounted

# 오브젝트 (티비 켜기, 화로 불 붙이기) 등 여기
static func interact() -> void:
	var instance = SessionState.target_dict["object"]
	if is_instance_valid(instance):
		instance.interact()
		return
	InventoryActions.consume(GameState.selected_slot)
