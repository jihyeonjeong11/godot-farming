extends CanvasLayer

const PARTS := ["Hair", "Shirt", "Pants", "Shoes"]

@export var player: AnimatedSprite2D

var _labels := {}


func _ready() -> void:
	var box := VBoxContainer.new()
	add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 8)
	box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	for part in PARTS:
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
		_labels[part] = label
		var next := Button.new()
		next.text = ">"
		next.pressed.connect(_step.bind(part, 1))
		row.add_child(next)
		_refresh(part)


func _step(part: String, delta: int) -> void:
	var layer := player.get_node_or_null(part) as Sprite2D
	if layer == null:
		return
	layer.variant = posmod(layer.variant + delta, layer.vframes)
	_refresh(part)


func _refresh(part: String) -> void:
	var layer := player.get_node_or_null(part) as Sprite2D
	if layer == null:
		_labels[part].text = part + ": -"
		return
	_labels[part].text = "%s %d/%d" % [part, layer.variant, layer.vframes - 1]
