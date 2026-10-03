extends Control

signal confirmed
signal cancelled

@onready var test_player: Player = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/PanelContainer/CenterContainer/PlayerAnchor/TestPlayer
@onready var part_rows: VBoxContainer = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/PartRows
@onready var start_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Buttons/Start
@onready var back_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/Buttons/Back


func _ready() -> void:
	test_player.is_freeze = true
	start_button.pressed.connect(confirmed.emit)
	back_button.pressed.connect(cancelled.emit)
	for part in test_player.OUTFIT_PARTS.size():
		var row := _row(part)
		row.get_node("Prev").pressed.connect(_step.bind(part, -1))
		row.get_node("Next").pressed.connect(_step.bind(part, 1))
		_refresh(part)


func _step(part: int, delta: int) -> void:
	var count := test_player.outfit_count(part) + 1
	test_player.equip(part, posmod(Inventory.get_vanity(part) + 1 + delta, count) - 1)
	_refresh(part)


func _refresh(part: int) -> void:
	var label := _row(part).get_node("Info/Index") as Label
	label.text = str(Inventory.get_vanity(part) + 1)


func _row(part: int) -> HBoxContainer:
	return part_rows.get_node(test_player.OUTFIT_PARTS[part]) as HBoxContainer
