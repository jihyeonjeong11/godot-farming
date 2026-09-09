class_name Quest extends Resource

@export var quest_id: String
@export var quest_title: String
@export var quest_description: String
@export var goal_type: DataTypes.QuestGoal = DataTypes.QuestGoal.Gather
@export var is_radiant: bool = false

@export var reward_gold: int
@export var reward_per_unit: int

@export var goal: Array[QuestObjective]


func display_title() -> String:
	return _fill(quest_title)


func display_description() -> String:
	return _fill(quest_description)


func _fill(key: String) -> String:
	var text := tr(key)
	if goal.is_empty() or goal[0] == null:
		return text

	return text.format({
		"target": goal[0].target_name(),
		"amount": goal[0].target_amount,
	})


func describe() -> String:
	var lines: PackedStringArray = [display_title(), display_description()]

	for objective in goal:
		if objective == null:
			continue
		lines.append(objective.describe())

	if reward_gold > 0:
		lines.append(tr(&"QUEST_REWARD_GOLD").format({"gold": reward_gold}))

	return "\n".join(lines)
