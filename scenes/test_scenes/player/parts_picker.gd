extends CanvasLayer

@export var player: TestPlayer

var _labels: Array[Label] = []


func _ready() -> void:
	var box := VBoxContainer.new()
	add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 8)
	box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	for part in player.OUTFIT_PARTS.size():
		var row := HBoxContainer.new()
		box.add_child(row)
		var prev := Button.new()
		prev.text = "<"
		prev.pressed.connect(_step.bind(part, -1))
		row.add_child(prev)
		var label := Label.new()
		label.custom_minimum_size.x = 120
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(label)
		_labels.append(label)
		var next := Button.new()
		next.text = ">"
		next.pressed.connect(_step.bind(part, 1))
		row.add_child(next)
		_refresh(part)


func _step(part: int, delta: int) -> void:
	var count := player.outfit_count(part) + 1
	player.equip(part, posmod(Inventory.get_vanity(part) + 1 + delta, count) - 1)
	_refresh(part)


func _refresh(part: int) -> void:
	_labels[part].text = "%s %d/%d" % [player.OUTFIT_PARTS[part], Inventory.get_vanity(part), player.outfit_count(part) - 1]
