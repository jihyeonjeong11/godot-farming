extends AnimatedSprite2D

@export var cycle: PackedStringArray = []
@export var hold := 2.0
@export var label: Label

var _index := 0
var _time := 0.0


func _ready() -> void:
	_show(0)


func _process(delta: float) -> void:
	if cycle.size() < 2:
		return
	_time += delta
	if _time < hold:
		return
	_time = 0.0
	_show((_index + 1) % cycle.size())


func _show(index: int) -> void:
	if cycle.is_empty():
		return
	_index = index
	play(cycle[index])
	if label != null:
		label.text = "%s
%s" % [name, cycle[index]]
