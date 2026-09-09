extends Node

const QUEST_ROOT := "res://scripts/resources/quests"

const QUEST_SUFFIX := "_quest.tres"
const OBJECTIVE_SUFFIX := "_objective.tres"

var quests: Dictionary[StringName, Quest] = {}
var objectives: Dictionary[StringName, QuestObjective] = {}


func _ready() -> void:
	_scan(QUEST_ROOT)


func get_quest(id: StringName) -> Quest:
	if id.is_empty():
		return null

	var quest: Quest = quests.get(id)
	if quest == null:
		push_warning("[QuestDB] 모르는 quest_id: %s" % id)
	return quest


func get_objective(id: StringName) -> QuestObjective:
	if id.is_empty():
		return null

	var objective: QuestObjective = objectives.get(id)
	if objective == null:
		push_warning("[QuestDB] 모르는 objective_id: %s" % id)
	return objective


func has_quest(id: StringName) -> bool:
	return not id.is_empty() and quests.has(id)


func has_objective(id: StringName) -> bool:
	return not id.is_empty() and objectives.has(id)


func all_quest_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(quests.keys())
	ids.sort()
	return ids


func all_objective_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(objectives.keys())
	ids.sort()
	return ids


func quest_ids_of_goal(goal_type: DataTypes.QuestGoal, radiant: bool) -> Array[StringName]:
	var ids: Array[StringName] = []
	for id in quests:
		var quest: Quest = quests[id]
		if quest.goal_type == goal_type and quest.is_radiant == radiant:
			ids.append(id)
	ids.sort()
	return ids


func objective_ids_of_goal(goal_type: DataTypes.QuestGoal) -> Array[StringName]:
	var ids: Array[StringName] = []
	for id in objectives:
		if objectives[id].goal_type == goal_type:
			ids.append(id)
	ids.sort()
	return ids


func make_quest(id: StringName, new_id: String = "") -> Quest:
	var template := get_quest(id)
	if template == null:
		return null

	var quest: Quest = template.duplicate()
	if not new_id.is_empty():
		quest.quest_id = new_id

	var empty: Array[QuestObjective] = []
	quest.goal = empty
	return quest


func roll_objective(id: StringName) -> QuestObjective:
	var template := get_objective(id)
	return null if template == null else template.roll()


func _scan(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("[QuestDB] 폴더를 열지 못했다: %s" % path)
		return

	for sub_dir in dir.get_directories():
		_scan("%s/%s" % [path, sub_dir])

	for file_name in dir.get_files():
		var res_name := file_name.trim_suffix(".remap")
		var res_path := "%s/%s" % [path, res_name]

		if res_name.ends_with(OBJECTIVE_SUFFIX):
			var objective := load(res_path) as QuestObjective
			if objective != null:
				_register(objectives, StringName(objective.objective_id), objective, res_path)
		elif res_name.ends_with(QUEST_SUFFIX):
			var quest := load(res_path) as Quest
			if quest != null:
				_register(quests, StringName(quest.quest_id), quest, res_path)


func _register(table: Dictionary, id: StringName, res: Resource, res_path: String) -> void:
	if id.is_empty():
		push_error("[QuestDB] id 가 비어 있다: %s" % res_path)
		return

	if table.has(id):
		push_error("[QuestDB] id 가 겹친다: %s (%s / %s)"
				% [id, res_path, (table[id] as Resource).resource_path])
		return

	table[id] = res
