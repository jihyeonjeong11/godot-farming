class_name QuestObjective extends Resource

@export var target_id: String = ""
@export var target_amount: int = 1


func target_name() -> String:
	if not ItemDB.has_item(target_id):
		return "???"
	return tr(ItemDB.get_item(target_id).item_name)


func describe(current: int = 0) -> String:
	return tr(&"QUEST_PROGRESS").format({
		"target": target_name(),
		"cur": mini(current, target_amount),
		"req": target_amount,
	})
