extends PanelContainer

const TITLE_SIZE := 40
const HEADING_SIZE := 28
const TEXT_SIZE := 24
const MUTED := Color(0.72, 0.72, 0.72)
const BAR_BG := Color(0.12, 0.12, 0.12, 0.85)

const NEEDS := [
	{ "name": "체력", "value": &"health", "max": &"current_max_health", "color": Color(0.85, 0.27, 0.27) },
	{ "name": "기력", "value": &"stamina", "max": &"current_max_stamina", "color": Color(0.9, 0.78, 0.3) },
	{ "name": "허기", "value": &"hunger", "max": &"current_max_hunger", "color": Color(0.88, 0.55, 0.25) },
	{ "name": "갈증", "value": &"thirst", "max": &"current_max_thirst", "color": Color(0.33, 0.6, 0.9) },
]

const ATTR_NAMES := {
	&"attack": "공격",
	&"defense": "방어",
	&"speed": "속도",
	&"gold": "골드",
}

const BUFF_NAMES := {
	BaseCharacterStats.Buffables.MAX_HEALTH: "최대 체력",
	BaseCharacterStats.Buffables.MAX_STAMINA: "최대 기력",
	BaseCharacterStats.Buffables.MAX_HUNGER: "최대 허기",
	BaseCharacterStats.Buffables.MAX_THIRST: "최대 갈증",
	BaseCharacterStats.Buffables.ATTACK: "공격",
	BaseCharacterStats.Buffables.DEFENSE: "방어",
	BaseCharacterStats.Buffables.SPEED: "속도",
}

var _level_label: Label
var _xp_bar: ProgressBar
var _xp_label: Label
var _need_bars: Array[ProgressBar] = []
var _need_labels: Array[Label] = []
var _attr_labels: Dictionary[StringName, Label] = {}
var _buff_list: VBoxContainer


func _ready() -> void:
	_build()
	visibility_changed.connect(_on_visibility_changed)
	refresh()


func _on_visibility_changed() -> void:
	if visible:
		refresh()


func _build() -> void:
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 20)
	margin.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 24)
	root.add_child(header)
	header.add_child(_label("STATS", TITLE_SIZE))
	_level_label = _label("", TITLE_SIZE)
	_level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_level_label)

	var xp_row := VBoxContainer.new()
	xp_row.add_theme_constant_override("separation", 4)
	root.add_child(xp_row)
	_xp_bar = _bar(Color(0.55, 0.8, 0.45), 14)
	xp_row.add_child(_xp_bar)
	_xp_label = _label("", TEXT_SIZE, MUTED)
	_xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	xp_row.add_child(_xp_label)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 48)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(columns)

	var needs_col := _column(columns, "상태", 3)
	for need in NEEDS:
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		needs_col.add_child(row)

		var line := HBoxContainer.new()
		row.add_child(line)
		var name_label := _label(need.name, TEXT_SIZE)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(name_label)
		var value_label := _label("", TEXT_SIZE, MUTED)
		line.add_child(value_label)
		_need_labels.append(value_label)

		var bar := _bar(need.color, 22)
		row.add_child(bar)
		_need_bars.append(bar)

	var attr_col := _column(columns, "능력치", 2)
	for key in ATTR_NAMES:
		var line := HBoxContainer.new()
		attr_col.add_child(line)
		var name_label := _label(ATTR_NAMES[key], TEXT_SIZE)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(name_label)
		var value_label := _label("", TEXT_SIZE)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		line.add_child(value_label)
		_attr_labels[key] = value_label

	attr_col.add_child(HSeparator.new())
	attr_col.add_child(_label("버프", HEADING_SIZE))
	_buff_list = VBoxContainer.new()
	_buff_list.add_theme_constant_override("separation", 6)
	attr_col.add_child(_buff_list)


func _column(parent: Container, heading: String, ratio: float) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_stretch_ratio = ratio
	col.add_theme_constant_override("separation", 14)
	parent.add_child(col)
	col.add_child(_label(heading, HEADING_SIZE))
	col.add_child(HSeparator.new())
	return col


func _label(text: String, font_size: int, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _bar(color: Color, height: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = height
	var bg := StyleBoxFlat.new()
	bg.bg_color = BAR_BG
	bg.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


func refresh() -> void:
	var stats := GameState.player_stat
	if stats == null or _level_label == null:
		return

	var level := stats.level
	var floor_xp := 0.0 if level <= 1 else BaseCharacterStats.BASE_LEVEL_XP * pow(level - 0.5, 2)
	var next_xp := BaseCharacterStats.BASE_LEVEL_XP * pow(level + 0.5, 2)
	_level_label.text = "Lv. %d" % level
	_xp_bar.max_value = next_xp - floor_xp
	_xp_bar.value = stats.experience - floor_xp
	_xp_label.text = "EXP %d / %d" % [stats.experience, ceili(next_xp)]

	for i in NEEDS.size():
		var value: int = stats.get(NEEDS[i].value)
		var max_value: int = stats.get(NEEDS[i].max)
		_need_bars[i].max_value = max_value
		_need_bars[i].value = value
		_need_labels[i].text = "%d / %d" % [value, max_value]

	_attr_labels[&"attack"].text = str(stats.current_attack)
	_attr_labels[&"defense"].text = _with_equip(stats.current_defense, stats.equip_defense)
	_attr_labels[&"speed"].text = _with_equip(stats.current_speed, stats.equip_speed)
	_attr_labels[&"gold"].text = "%d G" % stats.gold

	for child in _buff_list.get_children():
		child.queue_free()
	if stats.stat_buffs.is_empty():
		_buff_list.add_child(_label("없음", TEXT_SIZE, MUTED))
	for buff in stats.stat_buffs:
		_buff_list.add_child(_label(_buff_text(buff), TEXT_SIZE, Color(0.6, 0.85, 0.6)))


func _with_equip(total: int, from_equip: int) -> String:
	if from_equip == 0:
		return str(total)
	return "%d  (장비 %+d)" % [total, from_equip]


func _buff_text(buff: StatBuff) -> String:
	var stat_name: String = BUFF_NAMES.get(buff.stat, "?")
	match buff.buff_type:
		StatBuff.BuffType.MULTIPLY:
			return "%s  %+d%%" % [stat_name, roundi(buff.buff_amount * 100.0)]
		StatBuff.BuffType.MINUS:
			return "%s  -%s" % [stat_name, _num(buff.buff_amount)]
	return "%s  +%s" % [stat_name, _num(buff.buff_amount)]


func _num(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(roundi(value))
	return "%.1f" % value
