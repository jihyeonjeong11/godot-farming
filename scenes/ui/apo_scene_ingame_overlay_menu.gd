extends CanvasLayer

@onready var menu_panel: MarginContainer = $MarginContainer
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var settings_panel: Control = $Settings

@onready var inventory_grid: GridContainer = $MarginContainer/PanelContainer/InventoryGridContainer/InventoryGrid
@onready var inventory_description := $MarginContainer/PanelContainer/DescContainer/InventoryDescription as ApoInventoryDescription

const INVENTORY_SLOT = preload("uid://byt1lfm4vsyc4")

var slots: Array[ApoInventorySlot] = []
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
		slot.slot_index = i
		slot.source = Inventory.inventory
		slot.pressed.connect(on_slot_pressed.bind(i))
		slot.right_pressed.connect(on_slot_right_pressed.bind(i))
		inventory_grid.add_child(slot)
		slots.append(slot)

	Inventory.inventory_updated.connect(refresh)
	refresh()
	
func on_slot_pressed(index: int) -> void:
	if Inventory.get_item(index) == null or focused_slot_index == index:
		focused_slot_index = -1
	else:
		focused_slot_index = index
	refresh()

func on_slot_right_pressed(index: int) -> void:
	Inventory.drop_item(index)

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


func on_game_paused(is_paused: bool) -> void:
	visible = is_paused
	if is_paused:
		menu_panel.visible = true
		settings_panel.visible = false
	else:
		menu_panel.visible = false


func on_settings_pressed() -> void:
	menu_panel.visible = false
	settings_panel.open()


func on_settings_closed() -> void:
	menu_panel.visible = true
	settings_button.grab_focus()


func on_quit_pressed() -> void:
	get_tree().quit()
