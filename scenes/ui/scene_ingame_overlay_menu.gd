extends CanvasLayer

@onready var menu_panel: MarginContainer = $MarginContainer
@onready var settings_panel: Control = $Settings

@onready var inventory_grid: GridContainer = %InventoryGrid
@onready var inventory_description := %InventoryDescription as InventoryDescription
@onready var craft_grid: GridContainer = %CraftGrid
@onready var craft_info: Label = %CraftInfo
@onready var stats_info: Label = %StatsInfo

## 탭 버튼과 패널은 순서로 짝을 맞춘다. 둘 다 같은 순서로 채운다.
@onready var tab_buttons: Array[Button] = [
	%InventoryTab, %CraftingTab, %StatsTab, %SettingsTab
]
@onready var tab_panels: Array[Control] = [
	%InventoryPanel, %CraftingPanel, %StatsPanel, %SettingsPanel
]

@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton

const INVENTORY_SLOT = preload("uid://byt1lfm4vsyc4")


@export var recipes: Array[CraftRecipe] = []

var slots: Array[InventorySlot] = []
var craft_slots: Array[InventorySlot] = []
var focused_slot_index: int = -1
var focused_recipe_index: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	settings_panel.visible = false

	SignalBus.ingame_paused.connect(on_game_paused)
	settings_panel.closed.connect(on_settings_closed)

	for i in tab_buttons.size():
		tab_buttons[i].pressed.connect(show_tab.bind(i))

	options_button.pressed.connect(on_settings_pressed)
	quit_button.pressed.connect(on_quit_pressed)

	build_inventory_grid()
	build_craft_grid()

	Inventory.inventory_updated.connect(refresh)
	show_tab(0)
	refresh()


## 누른 탭만 남기고 나머지는 접는다. 버튼은 ButtonGroup이 알아서 하나만 눌린 상태로 만든다.
func show_tab(index: int) -> void:
	for i in tab_panels.size():
		tab_panels[i].visible = i == index

	tab_buttons[index].button_pressed = true

	if index == 2:
		refresh_stats()


func build_inventory_grid() -> void:
	for child in inventory_grid.get_children():
		inventory_grid.remove_child(child)
		child.queue_free()
	slots.clear()

	for i in Inventory.BASE_INVENTORY_LIMIT:
		var slot: InventorySlot = INVENTORY_SLOT.instantiate()
		slot.name = "Slot%d" % i
		slot.slot_index = i
		slot.source = Inventory.inventory
		# 아이템 그림은 26px 칸보다 큰 것이 많다. 눌러 담지 않으면 옆 칸까지 넘어간다.
		slot.expand_icon = true
		slot.pressed.connect(on_slot_pressed.bind(i))
		slot.right_pressed.connect(on_slot_right_pressed.bind(i))
		inventory_grid.add_child(slot)
		slots.append(slot)


## 조합 칸도 같은 슬롯 씬을 쓴다. 다만 인벤토리 칸이 아니라서 끌어봐야 옮길 곳이 없다.
## draggable 을 끄면 InventorySlot 이 드래그도 드롭도 거부한다.
func build_craft_grid() -> void:
	for child in craft_grid.get_children():
		craft_grid.remove_child(child)
		child.queue_free()
	craft_slots.clear()

	for i in recipes.size():
		var recipe := recipes[i]
		if recipe == null or recipe.result == null:
			continue

		var slot: InventorySlot = INVENTORY_SLOT.instantiate()
		slot.name = "Craft%d" % i
		slot.slot_index = i
		slot.draggable = false
		# 결과물 텍스처는 크기가 제각각이다. 눌러 담지 않으면 큰 그림 하나가 줄 높이를 다 먹는다.
		slot.expand_icon = true
		slot.pressed.connect(on_craft_pressed.bind(i))
		slot.mouse_entered.connect(on_craft_hovered.bind(i))
		craft_grid.add_child(slot)
		craft_slots.append(slot)

		slot.set_slot(ItemStack.new(recipe.result, recipe.result_amount))


func on_slot_pressed(index: int) -> void:
	if Inventory.get_item(index) == null or focused_slot_index == index:
		focused_slot_index = -1
	else:
		focused_slot_index = index
	refresh()

func on_slot_right_pressed(index: int) -> void:
	Inventory.drop_item(index)


func on_craft_pressed(index: int) -> void:
	focused_recipe_index = index
	Inventory.craft(recipes[index])
	refresh()


func on_craft_hovered(index: int) -> void:
	focused_recipe_index = index
	refresh_craft_info()


func refresh() -> void:
	for i in slots.size():
		var stack := Inventory.inventory[i]
		if stack == null:
			slots[i].clear()
		else:
			slots[i].set_slot(stack)

	var selected := Inventory.get_item(focused_slot_index)
	if selected == null:
		focused_slot_index = -1
		inventory_description.clear()
	else:
		inventory_description.show_item(selected.item, selected.amount)

	refresh_craft()


## 못 만드는 조합법도 흐리게 남겨둔다. 목록에서 빼버리면 뭘 모아야 하는지 알 수 없다.
func refresh_craft() -> void:
	for slot in craft_slots:
		var recipe := recipes[slot.slot_index]
		slot.modulate.a = 1.0 if Inventory.can_craft(recipe) else 0.4
		slot.tooltip_text = recipe.describe()

	refresh_craft_info()


func refresh_craft_info() -> void:
	if focused_recipe_index < 0 or focused_recipe_index >= recipes.size():
		craft_info.text = ""
		return

	craft_info.text = recipes[focused_recipe_index].describe()


## 플레이어를 그룹에서 찾아 그때그때 읽는다. 창을 열 때만 보므로 신호를 걸어둘 필요가 없다.
func refresh_stats() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not ("stats" in player):
		stats_info.text = "플레이어 없음"
		return

	var s: BaseCharacterStats = player.stats
	if s == null:
		stats_info.text = "스탯 없음"
		return

	stats_info.text = "\n".join([
		"Lv. %d  (EXP %d)" % [s.level, s.experience],
		"HP      %d / %d" % [s.health, s.current_max_health],
		"STAMINA %d / %d" % [s.stamina, s.current_max_stamina],
		"HUNGER  %d / %d" % [s.hunger, s.current_max_hunger],
		"THIRST  %d / %d" % [s.thirst, s.current_max_thirst],
		"",
		"ATK %d   DEF %d   SPD %d" % [s.current_attack, s.current_defense, s.current_speed],
		"GOLD %d" % s.gold,
	])


func on_game_paused(is_paused: bool) -> void:
	visible = is_paused
	if is_paused:
		menu_panel.visible = true
		settings_panel.visible = false
		show_tab(0)
		refresh()
	else:
		menu_panel.visible = false


func on_settings_pressed() -> void:
	menu_panel.visible = false
	settings_panel.open()


func on_settings_closed() -> void:
	menu_panel.visible = true


func on_quit_pressed() -> void:
	get_tree().quit()
