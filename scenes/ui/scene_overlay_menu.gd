extends CanvasLayer

@onready var menu_panel: PanelContainer = $PanelContainer
@onready var setting_button: Button = %Setting
@onready var resume_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Resume
@onready var save_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Save
@onready var exit_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Exit
@onready var settings_panel: Control = $Settings


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	settings_panel.visible = false

	SignalBus.game_paused.connect(on_game_paused)
	setting_button.pressed.connect(on_setting_pressed)
	resume_button.pressed.connect(on_resume_pressed)
	save_button.pressed.connect(on_save_pressed)
	exit_button.pressed.connect(on_exit_pressed)
	settings_panel.closed.connect(on_settings_closed)


func on_game_paused(is_paused: bool) -> void:
	visible = is_paused
	if is_paused:
		# 열 때는 항상 메뉴부터. 세팅은 접어둔다.
		menu_panel.visible = true
		settings_panel.visible = false
		resume_button.grab_focus()


func on_setting_pressed() -> void:
	# 버튼을 하나씩 숨기지 않고 공통 부모만 끈다.
	menu_panel.visible = false
	settings_panel.open()


func on_settings_closed() -> void:
	menu_panel.visible = true
	setting_button.grab_focus()


func on_save_pressed() -> void:
	# MenuOverlay는 레벨 루트의 직속 자식이라 부모가 곧 레벨이다.
	SaveAndLoad.save_level(get_parent())
	SaveAndLoad.save_inventory()
	SaveAndLoad.save_time()
	SaveAndLoad.save_stats(SignalBus.player_stats)


func on_resume_pressed() -> void:
	SignalBus.ui_close_requested.emit(PauseManager.Layer.PAUSE_MENU)


func on_exit_pressed() -> void:
	get_tree().quit()
