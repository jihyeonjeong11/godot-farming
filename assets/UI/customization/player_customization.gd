extends Control

signal confirmed
signal cancelled

@onready var panel_anchor: PanelAnchor = %PanelAnchor
@onready var player: Player = %Player
@onready var part_rows: VBoxContainer = %PartRows
@onready var start_button: Button = %Start
@onready var back_button: Button = %Back
@onready var skip_tutorial: BaseCheckbox = %SkipTutorial


func _ready() -> void:
	player.is_freeze = true
	start_button.pressed.connect(confirmed.emit)
	back_button.pressed.connect(_on_back_pressed)
	skip_tutorial.set_pressed_no_signal(GameState.did_skip_tutorial)
	skip_tutorial.toggled.connect(_on_skip_tutorial_toggled)
	for part in player.OUTFIT_PARTS.size():
		var row := _row(part)
		row.get_node("Prev").pressed.connect(_step.bind(part, -1))
		row.get_node("Next").pressed.connect(_step.bind(part, 1))
		_refresh(part)
	panel_anchor.appear()


func _on_back_pressed() -> void:
	await panel_anchor.disappear()
	cancelled.emit()


func _on_skip_tutorial_toggled(toggled_on: bool) -> void:
	GameState.did_skip_tutorial = toggled_on


func _step(part: int, delta: int) -> void:
	var count := player.outfit_count(part) + 1
	GameState.player_vanity[part] = posmod(GameState.player_vanity[part] + 1 + delta, count) - 1
	player.equip(part, GameState.player_vanity[part])
	_refresh(part)


func _refresh(part: int) -> void:
	var label := _row(part).get_node("Info/Index") as Label
	label.text = str(GameState.player_vanity[part] + 1)


func _row(part: int) -> HBoxContainer:
	return part_rows.get_node(player.OUTFIT_PARTS[part]) as HBoxContainer
