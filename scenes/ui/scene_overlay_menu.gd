extends CanvasLayer

@onready var menu_panel: PanelContainer = $PanelContainer
@onready var setting_button: Button = %Setting
@onready var resume_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Resume
@onready var save_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Save
@onready var main_menu_button: Button = $PanelContainer/MarginContainer/VBoxContainer/MainMenu
@onready var exit_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Exit
@onready var settings_panel: Control = $Settings
@onready var save_slots: SaveSlots = $SaveSlots


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	settings_panel.visible = false
	save_slots.visible = false

	SignalBus.game_paused.connect(on_game_paused)
	setting_button.pressed.connect(on_setting_pressed)
	resume_button.pressed.connect(on_resume_pressed)
	save_button.pressed.connect(on_save_pressed)
	main_menu_button.pressed.connect(on_main_menu_pressed)
	exit_button.pressed.connect(on_exit_pressed)
	settings_panel.closed.connect(on_settings_closed)
	save_slots.slot_selected.connect(on_save_slot_selected)
	save_slots.closed.connect(on_save_slots_closed)


func on_game_paused(is_paused: bool) -> void:
	visible = is_paused
	if is_paused:
		# 열 때는 항상 메뉴부터. 세팅과 슬롯 목록은 접어둔다.
		menu_panel.visible = true
		settings_panel.visible = false
		save_slots.visible = false
		resume_button.grab_focus()


func on_setting_pressed() -> void:
	# 버튼을 하나씩 숨기지 않고 공통 부모만 끈다.
	menu_panel.visible = false
	settings_panel.open()


func on_settings_closed() -> void:
	menu_panel.visible = true
	setting_button.grab_focus()


## 어느 슬롯에 넣을지 먼저 고르게 한다. 고르고 나면 저장은 SaveAndLoad가 통째로 한다.
func on_save_pressed() -> void:
	menu_panel.visible = false
	save_slots.open(SaveSlots.Mode.SAVE)


func on_save_slot_selected(slot: int) -> void:
	SaveAndLoad.select_slot(slot)
	SaveAndLoad.save_game()
	on_save_slots_closed()


func on_save_slots_closed() -> void:
	menu_panel.visible = true
	save_button.grab_focus()


func on_resume_pressed() -> void:
	SignalBus.ui_close_requested.emit(UIManager.Layer.PAUSE_MENU)


func on_main_menu_pressed() -> void:
	SignalBus.main_menu_requested.emit()


func on_exit_pressed() -> void:
	get_tree().quit()
