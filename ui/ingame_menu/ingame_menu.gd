extends CanvasLayer

## TODO: 인벤토리 슬롯 크기 맞추기
## 장비 슬롯
## 크래프팅 슬롯 크기 맞추기
## 퀘스트 디자인
## Stats는 어떻게 하지?
## 버튼그룹 - 스타듀 느낌으로 큰 버튼을 늘어뜨릴 것.
## 세팅 - ui stack 생각해야 함.
## 세팅 - 그대로 사용 가능할지?
@onready var tab_buttons: Array[Button] = [
	%InventoryTab, %CraftingTab, %QuestTab, %StatsTab, %SystemTab
]
@onready var tab_panels: Array[Control] = [
	%InventoryPanel, %CraftingPanel, %QuestPanel, %StatsPanel, %SystemPanel
	]

@onready var settings_button: Button = %SettingsButton
@onready var title_button: Button = %TitleButton
@onready var exit_button: Button = %ExitButton

signal cancelled
signal settings_requested

func _ready() -> void:
	SignalBus.pause_game()
	cancelled.connect(on_menu_cancelled)
	tab_buttons[0].button_group.pressed.connect(on_tab_pressed)
	settings_button.pressed.connect(on_settings_pressed)
	title_button.pressed.connect(on_title_pressed)
	exit_button.pressed.connect(on_exit_pressed)
	show_tab(0)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ingame_pause"):
		get_viewport().set_input_as_handled()
		cancelled.emit()

func on_menu_cancelled() -> void:
	InventoryActions.return_held()
	SignalBus.pause_game(false)
	queue_free()

func on_tab_pressed(button: BaseButton) -> void:
	InventoryActions.return_held()
	show_tab(tab_buttons.find(button))
	
func on_settings_pressed() -> void:
	InventoryActions.return_held()
	settings_requested.emit()
	queue_free()

func on_title_pressed() -> void:
	on_menu_cancelled()
	SessionState.has_seen_logos = true
	SessionState.quit_to_title()

func on_exit_pressed() -> void:
	get_tree().quit()

func show_tab(index: int) -> void:
	for i in tab_panels.size():
		tab_panels[i].visible = i == index
