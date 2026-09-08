extends CanvasLayer

@onready var _label: RichTextLabel = $MarginContainer/BaseUi/NinePatchRect/MarginContainer/HBoxContainer/RichTextLabel

var _keys: Array[StringName] = []
var _index := 0


func setup(text_keys: Array[StringName]) -> void:
	_keys = text_keys
	_index = 0
	_render()


func advance() -> bool:
	if _index + 1 >= _keys.size():
		return false

	_index += 1
	_render()
	return true


func _render() -> void:
	_label.text = _keys[_index] if _index < _keys.size() else ""
