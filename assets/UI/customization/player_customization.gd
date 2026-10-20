extends Control

signal confirmed
signal cancelled

@onready var panel_anchor: PanelAnchor = %PanelAnchor
@onready var part_rows: VBoxContainer = %PartRows
@onready var start_button: Button = %Start
@onready var back_button: Button = %Back
@onready var skip_tutorial: BaseCheckbox = %SkipTutorial


func _ready() -> void:
	start_button.pressed.connect(confirmed.emit)
	back_button.pressed.connect(_on_back_pressed)
	skip_tutorial.set_pressed_no_signal(GameState.did_skip_tutorial)
	skip_tutorial.toggled.connect(_on_skip_tutorial_toggled)

	panel_anchor.appear()


func _on_back_pressed() -> void:
	await panel_anchor.disappear()
	cancelled.emit()


func _on_skip_tutorial_toggled(toggled_on: bool) -> void:
	GameState.did_skip_tutorial = toggled_on
