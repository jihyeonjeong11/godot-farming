extends Control

@onready var play: Button = $Container/MarginContainer/VBoxContainer/Play
@onready var load_game: Button = $Container/MarginContainer/VBoxContainer/Load
@onready var settings: Button = $Container/MarginContainer/VBoxContainer/Settings
@onready var quit: Button = $Container/MarginContainer/VBoxContainer/Quit
@onready var menu_panel: PanelContainer = $Container
@onready var settings_panel: Control = $SettingsPanel


func _ready() -> void:
	settings_panel.visible = false

	play.pressed.connect(_on_play_pressed)
	load_game.pressed.connect(_on_load_pressed)
	settings.pressed.connect(_on_settings_pressed)
	quit.pressed.connect(_on_quit_pressed)
	settings_panel.closed.connect(_on_settings_closed)


func _on_play_pressed() -> void:
	# 씬 교체는 CurrentScene을 쥔 game.gd만 할 수 있으므로 넘긴다.
	SignalBus.new_game_requested.emit()


func _on_load_pressed() -> void:
	# 세이브를 얹으려면 먼저 레벨이 떠 있어야 하므로 여기서도 game.gd에 넘긴다.
	SignalBus.load_game_requested.emit()


## 인게임 일시정지 메뉴와 같은 패널을 쓴다. 볼륨/창모드는 세이브가 아니라
## 기기 설정이라, 메인 메뉴에서 열든 게임 중에 열든 같은 것을 만져야 한다.
func _on_settings_pressed() -> void:
	# 버튼을 하나씩 숨기지 않고 공통 부모만 끈다.
	menu_panel.visible = false
	settings_panel.open()


func _on_settings_closed() -> void:
	menu_panel.visible = true
	settings.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()
