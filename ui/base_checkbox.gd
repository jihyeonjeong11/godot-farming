class_name BaseCheckbox
extends HBoxContainer

signal toggled(toggled_on: bool)

@export var text: String = "":
	set(value):
		text = value
		if is_node_ready():
			label.text = value

@export var button_pressed: bool = false:
	set(value):
		button_pressed = value
		if is_node_ready():
			_sync_box()

@onready var label: Label = $Label
@onready var box: Button = $Box
@onready var cross: TextureRect = $Box/Cross


func _ready() -> void:
	label.text = text
	_sync_box()
	box.toggled.connect(_on_box_toggled)


func _on_box_toggled(toggled_on: bool) -> void:
	button_pressed = toggled_on
	toggled.emit(toggled_on)


func _sync_box() -> void:
	box.set_pressed_no_signal(button_pressed)
	cross.visible = button_pressed
