extends CanvasLayer

@onready var menu_panel: PanelContainer = $PanelContainer
@onready var setting_button: Button = %Setting
@onready var resume_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Resume
@onready var exit_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Exit
@onready var settings_panel: Control = $Settings


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	settings_panel.visible = false

	SignalBus.game_paused.connect(on_game_paused)
	setting_button.pressed.connect(on_setting_pressed)
	resume_button.pressed.connect(on_resume_pressed)
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


func on_resume_pressed() -> void:
	visible = false
	GameManager.set_paused(false)


func on_exit_pressed() -> void:
	get_tree().quit()
