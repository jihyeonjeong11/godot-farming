class_name QuestPanel extends Control

const BASE_UI = preload("uid://deugupwqjk44e")
const LIST_TITLE := "QUESTS"

@onready var title_label: Label = %PanelTitle
@onready var list_view: ScrollContainer = %ListView
@onready var quest_list: VBoxContainer = %QuestList
@onready var detail_view: Control = %DetailView
@onready var detail_description: Label = %DetailDescription
@onready var detail_objectives: VBoxContainer = %DetailObjectives
@onready var detail_reward: Label = %DetailReward
@onready var back_button: Button = %BackButton

var quests: Array[Quest] = []
var rows: Array[Button] = []
var focused_quest: Quest = null


func _ready() -> void:
	back_button.pressed.connect(show_list)
	show_list()


func setup(new_quests: Array[Quest]) -> void:
	quests = new_quests
	build_rows()
	show_list()


func show_list() -> void:
	title_label.text = LIST_TITLE
	list_view.visible = true
	detail_view.visible = false
	focus_row()


func show_detail(quest: Quest) -> void:
	if quest == null:
		return

	focused_quest = quest
	title_label.text = quest.display_title()
	list_view.visible = false
	detail_view.visible = true

	detail_description.text = quest.display_description()
	detail_reward.text = "" if quest.reward_gold <= 0 \
			else tr(&"QUEST_REWARD_GOLD").format({"gold": quest.reward_gold})

	for child in detail_objectives.get_children():
		detail_objectives.remove_child(child)
		child.queue_free()

	for objective in quest.goal:
		if objective == null:
			continue

		var line := Label.new()
		line.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		line.add_theme_font_size_override("font_size", 8)
		line.text = objective.describe()
		detail_objectives.add_child(line)

	if is_visible_in_tree():
		back_button.grab_focus()


func build_rows() -> void:
	for child in quest_list.get_children():
		quest_list.remove_child(child)
		child.queue_free()
	rows.clear()

	for quest in quests:
		quest_list.add_child(make_quest_row(quest))


func make_quest_row(quest: Quest) -> PanelContainer:
	var row := PanelContainer.new()
	row.name = quest.quest_id
	row.custom_minimum_size = Vector2(260, 34)
	row.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	row.add_child(BASE_UI.instantiate())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 6)
	row.add_child(margin)

	var button := Button.new()
	button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	button.flat = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text = row_text(quest)
	button.icon = row_icon(quest)
	button.expand_icon = true
	button.add_theme_font_size_override("font_size", 10)
	button.add_theme_constant_override("h_separation", 8)
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.pressed.connect(show_detail.bind(quest))
	margin.add_child(button)

	rows.append(button)
	return row


func row_text(quest: Quest) -> String:
	if quest.goal.is_empty() or quest.goal[0] == null:
		return quest.display_title()

	return "%s   0/%d" % [quest.display_title(), quest.goal[0].target_amount]


func row_icon(quest: Quest) -> Texture2D:
	if quest.goal.is_empty() or quest.goal[0] == null:
		return null

	var item := ItemDB.get_item(quest.goal[0].target_id)
	return null if item == null else item.item_texture


func focus_row() -> void:
	if not is_visible_in_tree() or rows.is_empty():
		return

	var index := quests.find(focused_quest)
	rows[index if index >= 0 and index < rows.size() else 0].grab_focus()


func _shortcut_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not detail_view.visible:
		return

	if event.is_action_pressed("ingame_pause") or event.is_action_pressed("pause"):
		show_list()
		get_viewport().set_input_as_handled()
