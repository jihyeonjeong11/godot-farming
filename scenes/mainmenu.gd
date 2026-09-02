extends Control

@onready var play: Button = $Container/MarginContainer/VBoxContainer/Play
@onready var load_game: Button = $Container/MarginContainer/VBoxContainer/Load
@onready var settings: Button = $Container/MarginContainer/VBoxContainer/Settings
@onready var quit: Button = $Container/MarginContainer/VBoxContainer/Quit
@onready var menu_panel: PanelContainer = $Container
@onready var settings_panel: Control = $SettingsPanel
@onready var save_slots: SaveSlots = $SaveSlots

## 슬롯 화면은 새 게임과 불러오기가 함께 쓴다. 고른 뒤에 무엇을 할지는
## 여기서 기억한 모드로 가른다.
var _slot_mode: SaveSlots.Mode = SaveSlots.Mode.NEW


func _ready() -> void:
	settings_panel.visible = false
	save_slots.visible = false

	play.pressed.connect(_on_play_pressed)
	load_game.pressed.connect(_on_load_pressed)
	settings.pressed.connect(_on_settings_pressed)
	quit.pressed.connect(_on_quit_pressed)
	settings_panel.closed.connect(_on_settings_closed)
	save_slots.slot_selected.connect(_on_slot_selected)
	save_slots.closed.connect(_on_slots_closed)


func _on_play_pressed() -> void:
	_open_slots(SaveSlots.Mode.NEW)


func _on_load_pressed() -> void:
	_open_slots(SaveSlots.Mode.LOAD)


func _open_slots(mode: SaveSlots.Mode) -> void:
	_slot_mode = mode
	menu_panel.visible = false
	save_slots.open(mode)


## 슬롯이 정해져야 어느 폴더를 읽고 쓸지가 정해진다. 그래서 게임을 여는 신호에
## 슬롯 번호를 실어 보낸다.
func _on_slot_selected(slot: int) -> void:
	if _slot_mode == SaveSlots.Mode.LOAD:
		SignalBus.load_game_requested.emit(slot)
	else:
		SignalBus.new_game_requested.emit(slot)


func _on_slots_closed() -> void:
	menu_panel.visible = true
	play.grab_focus()


func _on_settings_pressed() -> void:
	menu_panel.visible = false
	settings_panel.open()


func _on_settings_closed() -> void:
	menu_panel.visible = true
	settings.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()
