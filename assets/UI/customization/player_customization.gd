extends Control

signal confirmed
signal cancelled

@onready var panel_anchor: PanelAnchor = %PanelAnchor
@onready var part_rows: VBoxContainer = %PartRows
@onready var start_button: Button = %Start
@onready var back_button: Button = %Back
@onready var skip_tutorial: BaseCheckbox = %SkipTutorial
@onready var name_edit: LineEdit = %Name_edit
@onready var player_visual: Control = %PlayerVisual


func _ready() -> void:
	start_button.pressed.connect(confirmed.emit)
	back_button.pressed.connect(_on_back_pressed)
	skip_tutorial.set_pressed_no_signal(GameState.did_skip_tutorial)
	skip_tutorial.toggled.connect(_on_skip_tutorial_toggled)
	name_edit.text = GameState.player_name
	name_edit.text_changed.connect(_on_name_changed)
	for row in part_rows.get_children():
		var part := Player.OUTFIT_PARTS.find(row.name)
		row.get_node("Prev").pressed.connect(_cycle.bind(part, -1))
		row.get_node("Next").pressed.connect(_cycle.bind(part, 1))
		_refresh_row(part)
	panel_anchor.appear()

func _on_name_changed(new_text: String) -> void:
	GameState.player_name = new_text.strip_edges()

func _cycle(part: int, step: int) -> void:
	var sprite: VanitySprite = player_visual.vanity_sprite(part)
	GameState.player_vanity[part] = wrapi(GameState.player_vanity[part] + step, -1, sprite.variant_count())
	sprite.part_index = GameState.player_vanity[part]
	_refresh_row(part)


func _refresh_row(part: int) -> void:
	var index: int = GameState.player_vanity[part]
	var label: Label = part_rows.get_node("%s/Info/Index" % Player.OUTFIT_PARTS[part])
	label.text = "-" if index < 0 else str(index + 1)


func _on_back_pressed() -> void:
	await panel_anchor.disappear()
	cancelled.emit()


func _on_skip_tutorial_toggled(toggled_on: bool) -> void:
	GameState.did_skip_tutorial = toggled_on
