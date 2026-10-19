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
	%InventoryTab, %CraftingTab, %QuestTab, %StatsTab, %SettingsTab
]
@onready var tab_panels: Array[Control] = [
	%InventoryPanel, %CraftingPanel, %QuestPanel, %StatsPanel, %SettingsPanel
]
@onready var inventory_grid: GridContainer = %InventoryGrid

signal cancelled

func _ready() -> void:
	SignalBus.pause_game()
	cancelled.connect(on_menu_cancelled)
	tab_buttons[0].button_group.pressed.connect(on_tab_pressed)
	show_tab(0)
	InventoryManager.updated_inventory.connect(refresh_inventory)
	refresh_inventory()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ingame_pause"):
		get_viewport().set_input_as_handled()
		cancelled.emit()

func on_menu_cancelled() -> void:
	SignalBus.pause_game(false)
	queue_free()

func refresh_inventory() -> void:
	for i in inventory_grid.get_child_count():
		var slot: BaseInventorySlot = inventory_grid.get_child(i)
		slot.set_stack(InventoryManager.get_item_stack_by_index(i))

func on_tab_pressed(button: BaseButton) -> void:
	show_tab(tab_buttons.find(button))

func show_tab(index: int) -> void:
	for i in tab_panels.size():
		tab_panels[i].visible = i == index
