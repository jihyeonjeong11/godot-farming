class_name QuestObjective extends Resource

@export var objective_id: String = ""
@export var goal_type: DataTypes.QuestGoal = DataTypes.QuestGoal.Gather

@export_group("고정값")
@export var target_id: String = ""
@export var target_amount: int = 1

@export_group("굴림 규칙")
@export var target_pool: Array[String] = []
@export var target_type: DataTypes.ItemType = DataTypes.ItemType.Misc
@export var amount_min: int = 0
@export var amount_max: int = 0
@export var amount_step: int = 1


func roll() -> QuestObjective:
	var rolled: QuestObjective = duplicate()
	rolled.target_id = roll_target()
	rolled.target_amount = roll_amount()
	return rolled


func roll_target() -> String:
	if not target_id.is_empty():
		return target_id

	if not target_pool.is_empty():
		return target_pool.pick_random()

	if goal_type == DataTypes.QuestGoal.Slay:
		push_warning("[QuestObjective] 처치 목표에 target_pool 이 비어 있다: %s" % objective_id)
		return ""

	var candidates := ItemDB.of_type(target_type)
	if candidates.is_empty():
		push_warning("[QuestObjective] 뽑을 아이템이 없다: %s" % objective_id)
		return ""

	return (candidates.pick_random() as Item).item_id


func roll_amount() -> int:
	if amount_max <= 0:
		return target_amount

	var step := maxi(amount_step, 1)
	var lo := maxi(amount_min, 1)
	var hi := maxi(amount_max, lo)

	return lo + randi_range(0, (hi - lo) / step) * step


func target_name() -> String:
	if goal_type == DataTypes.QuestGoal.Slay:
		return tr("ENEMY_%s" % target_id.to_upper())

	if not ItemDB.has_item(target_id):
		return "???"
	return tr(ItemDB.get_item(target_id).item_name)


func describe(current: int = 0) -> String:
	return tr(&"QUEST_PROGRESS").format({
		"target": target_name(),
		"cur": mini(current, target_amount),
		"req": target_amount,
	})
