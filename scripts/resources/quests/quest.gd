class_name Quest extends Resource

@export var quest_id: String
@export var quest_title: String
@export var quest_description: String

@export var reward_gold: int

@export var goal: Array[QuestObjective]


func display_title() -> String:
	return tr(quest_title)


func display_description() -> String:
	return tr(quest_description)


func describe() -> String:
	var lines: PackedStringArray = [display_title(), display_description()]

	for objective in goal:
		if objective == null:
			continue
		lines.append(objective.describe())

	if reward_gold > 0:
		lines.append(tr(&"QUEST_REWARD_GOLD").format({"gold": reward_gold}))

	return "
".join(lines)
