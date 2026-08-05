extends CanvasLayer

@onready var menu_panel: MarginContainer = $MarginContainer
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var settings_panel: Control = $Settings

@onready var inventory_grid: GridContainer = $MarginContainer/PanelContainer/InventoryGridContainer/InventoryGrid
const INVENTORY_SLOT = preload("uid://byt1lfm4vsyc4")
## 인스턴스된 서브씬이라 $경로는 Panel로만 추론된다. 스크립트 타입으로 캐스트해야
## show_item / clear가 정적으로 잡힌다.
@onready var inventory_description := $MarginContainer/PanelContainer/DescContainer/InventoryDescription as ApoInventoryDescription

var slots: Array[ApoInventorySlot] = []
## 선택된 칸. -1이면 선택 없음.
var focused_slot_index: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	settings_panel.visible = false

	SignalBus.ingame_paused.connect(on_game_paused)
	settings_button.pressed.connect(on_settings_pressed)
	quit_button.pressed.connect(on_quit_pressed)
	settings_panel.closed.connect(on_settings_closed)
	
	for child in inventory_grid.get_children():
		inventory_grid.remove_child(child)
		child.queue_free()

	for i in Inventory.BASE_INVENTORY_LIMIT:
		var slot: ApoInventorySlot = INVENTORY_SLOT.instantiate()
		slot.name = "Slot%d" % i
		slot.pressed.connect(on_slot_pressed.bind(i))
		inventory_grid.add_child(slot)
		slots.append(slot)

	Inventory.inventory_updated.connect(refresh)
	refresh()
	
func on_slot_pressed(index: int) -> void:
	# 빈 칸을 누르거나 같은 칸을 다시 누르면 선택 해제.
	if Inventory.get_item(index) == null or focused_slot_index == index:
		focused_slot_index = -1
	else:
		focused_slot_index = index
	refresh()

	
func refresh() -> void:
	for i in slots.size():
		var slot = Inventory.inventory[i]
		if slot == null:
			slots[i].clear()
		else:
			slots[i].set_slot(slot)

	# 선택한 칸이 비었으면 해제. 다 쓴 아이템 설명이 남는 걸 막는다.
	var selected = Inventory.get_item(focused_slot_index)
	if selected == null:
		focused_slot_index = -1
		inventory_description.clear()
	else:
		inventory_description.show_item(selected["item"], selected["amount"])


func on_game_paused(is_paused: bool) -> void:
	visible = is_paused
	if is_paused:
		# 열 때는 항상 메뉴부터. 세팅은 접어둔다.
		menu_panel.visible = true
		settings_panel.visible = false
	else:
		menu_panel.visible = false


func on_settings_pressed() -> void:
	# 버튼을 하나씩 숨기지 않고 공통 부모만 끈다.
	menu_panel.visible = false
	settings_panel.open()


func on_settings_closed() -> void:
	menu_panel.visible = true
	settings_button.grab_focus()


func on_quit_pressed() -> void:
	get_tree().quit()
