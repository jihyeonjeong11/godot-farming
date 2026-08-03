extends CanvasLayer

@onready var menu_panel: MarginContainer = $MarginContainer
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var settings_panel: Control = $Settings


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	settings_panel.visible = false

	SignalBus.ingame_paused.connect(on_game_paused)
	settings_button.pressed.connect(on_settings_pressed)
	quit_button.pressed.connect(on_quit_pressed)
	settings_panel.closed.connect(on_settings_closed)


func on_game_paused(is_paused: bool) -> void:
	visible = is_paused
	if is_paused:
		# 열 때는 항상 메뉴부터. 세팅은 접어둔다.
		menu_panel.visible = true
		settings_panel.visible = false
		settings_button.grab_focus()


func on_settings_pressed() -> void:
	# 버튼을 하나씩 숨기지 않고 공통 부모만 끈다.
	menu_panel.visible = false
	settings_panel.open()


func on_settings_closed() -> void:
	menu_panel.visible = true
	settings_button.grab_focus()


func on_quit_pressed() -> void:
	get_tree().quit()
