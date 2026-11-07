class_name QuestManager
extends Node

const GROUP: StringName = &"quest_manager"

var quests: Array[Quest] = []

var progress: Dictionary = {}

var completed: Array[String] = []

var cleared: Array[String] = []

var radiant_ids: Array[String] = []

var radiant_serial: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(GROUP)
	reload()
	Inventory.item_gained.connect(on_item_gained)
	SignalBus.time_tick_day.connect(on_tick_day)
	SignalBus.enemy_killed.connect(on_enemy_killed)
	


static func find(tree: SceneTree) -> QuestManager:
	return tree.get_first_node_in_group(GROUP) as QuestManager


func on_tick_day(_day: int) -> void:
	clear_radiant_quests()
	generate_radiant_quests(1, DataTypes.QuestGoal.Gather)
	generate_radiant_quests(1, DataTypes.QuestGoal.Slay)


func clear_radiant_quests() -> void:
	for quest_id in radiant_ids:
		var quest := get_quest(quest_id)
		if quest != null:
			quests.erase(quest)
		progress.erase(quest_id)
		completed.erase(quest_id)

	radiant_ids.clear()
	SignalBus.quest_list_changed.emit()


func generate_radiant_quests(count: int = 1,
		goal_type: DataTypes.QuestGoal = DataTypes.QuestGoal.Gather) -> void:
	var template_ids := QuestDB.quest_ids_of_goal(goal_type, true)
	var objective_ids := QuestDB.objective_ids_of_goal(goal_type)

	if template_ids.is_empty() or objective_ids.is_empty():
		push_warning("[QuestManager] %s 라디언트 템플릿이나 목표가 DB 에 없다"
				% DataTypes.quest_goal_label(goal_type))
		return

	for i in count:
		var template_id: StringName = template_ids.pick_random()
		radiant_serial += 1

		var quest := QuestDB.make_quest(template_id, "%s_r%d" % [template_id, radiant_serial])
		if quest == null:
			continue

		var objective := QuestDB.roll_objective(objective_ids.pick_random())
		if objective == null or objective.target_id.is_empty():
			continue

		var goal: Array[QuestObjective] = [objective]
		quest.goal = goal
		quest.reward_gold += quest.reward_per_unit * objective.target_amount

		quests.append(quest)
		radiant_ids.append(quest.quest_id)

	quests.sort_custom(func(a: Quest, b: Quest) -> bool: return a.quest_id < b.quest_id)
	_sync_progress()
	SignalBus.quest_list_changed.emit()


func all() -> Array[Quest]:
	return quests.duplicate()


func get_quest(quest_id: String) -> Quest:
	for quest in quests:
		if quest.quest_id == quest_id:
			return quest
	return null


func has_quest(quest_id: String) -> bool:
	return get_quest(quest_id) != null


func is_completed(quest_id: String) -> bool:
	return completed.has(quest_id)


func objective_progress(quest_id: String, index: int) -> int:
	var counts: Array = progress.get(quest_id, [])
	return 0 if index < 0 or index >= counts.size() else counts[index]


func on_item_gained(item: Item, amount: int) -> void:
	if item == null or amount <= 0:
		return
	add_progress(item.item_id, amount,
			[DataTypes.QuestGoal.Gather, DataTypes.QuestGoal.Harvest])


func on_enemy_killed(enemy_id: StringName) -> void:
	add_progress(String(enemy_id), 1, [DataTypes.QuestGoal.Slay])


func add_progress(target_id: String, amount: int, goals: Array[int]) -> void:
	if target_id.is_empty() or amount <= 0:
		return

	for quest in quests:
		if is_completed(quest.quest_id):
			continue

		var counts: Array = progress.get(quest.quest_id, [])
		var moved := false

		for i in quest.goal.size():
			var objective := quest.goal[i]
			if objective == null or objective.target_id != target_id:
				continue
			if not goals.has(objective.goal_type):
				continue
			if counts[i] >= objective.target_amount:
				continue

			counts[i] = mini(counts[i] + amount, objective.target_amount)
			moved = true

		if not moved:
			continue

		SignalBus.quest_progressed.emit(quest.quest_id)

		if _is_met(quest):
			completed.append(quest.quest_id)
			SignalBus.quest_completed.emit(quest.quest_id)


func can_complete(quest_id: String) -> bool:
	var quest := get_quest(quest_id)
	return quest != null and not quest.goal.is_empty() and _is_met(quest)


func complete_quest(quest_id: String) -> bool:
	if not can_complete(quest_id):
		return false

	var quest := get_quest(quest_id)
	_grant_reward(quest)

	quests.erase(quest)
	progress.erase(quest_id)
	completed.erase(quest_id)
	cleared.append(quest_id)

	SignalBus.quest_cleared.emit(quest_id)
	SignalBus.quest_list_changed.emit()
	return true


func _grant_reward(quest: Quest) -> void:
	if quest.reward_gold <= 0:
		return

	var player := get_tree().get_first_node_in_group(&"player")
	if player == null:
		push_warning("[QuestManager] 보상을 줄 플레이어가 씬에 없다: %s" % quest.quest_id)
		return

	var stats := player.get(&"stats") as BaseCharacterStats
	if stats == null:
		push_warning("[QuestManager] 플레이어 스탯을 찾지 못했다: %s" % quest.quest_id)
		return

	stats.gold += quest.reward_gold


func reset_progress() -> void:
	progress.clear()
	completed.clear()
	cleared.clear()
	reload()


func capture() -> Dictionary:
	return {
		"progress": progress.duplicate(true),
		"cleared": cleared.duplicate(),
	}


func restore(data: Variant) -> void:
	if data is not Dictionary:
		return

	progress.clear()
	completed.clear()
	cleared.clear()

	var was_cleared: Variant = data.get("cleared", [])
	if was_cleared is Array:
		for quest_id in was_cleared:
			cleared.append(String(quest_id))

	reload()

	var saved: Variant = data.get("progress", {})
	if saved is Dictionary:
		for quest_id in saved:
			var counts: Variant = saved[quest_id]
			if counts is not Array:
				continue

			var restored: Array = []
			for value in counts:
				restored.append(int(value))
			progress[String(quest_id)] = restored

	_sync_progress()


func _is_met(quest: Quest) -> bool:
	for i in quest.goal.size():
		var objective := quest.goal[i]
		if objective != null and objective_progress(quest.quest_id, i) < objective.target_amount:
			return false
	return true


func _sync_progress() -> void:
	var kept: Dictionary = {}

	for quest in quests:
		var counts: Array = progress.get(quest.quest_id, [])
		var sized: Array = []
		sized.resize(quest.goal.size())

		for i in sized.size():
			sized[i] = counts[i] if i < counts.size() else 0

		kept[quest.quest_id] = sized

	progress = kept

	completed.clear()
	for quest in quests:
		if not quest.goal.is_empty() and _is_met(quest):
			completed.append(quest.quest_id)


func reload() -> void:
	quests.clear()
	radiant_ids.clear()
	quests.sort_custom(func(a: Quest, b: Quest) -> bool: return a.quest_id < b.quest_id)
	_sync_progress()
	SignalBus.quest_list_changed.emit()
