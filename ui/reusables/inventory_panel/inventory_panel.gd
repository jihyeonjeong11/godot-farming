extends PanelContainer

@onready var inventory_grid: GridContainer = %InventoryGrid

func _ready() -> void:
	for i in inventory_grid.get_child_count():
		var slot: BaseInventorySlot = inventory_grid.get_child(i)
		slot.clicked.connect(on_inventory_slot_clicked.bind(i))
	InventoryManager.updated_inventory.connect(refresh_inventory)
	refresh_inventory()

func refresh_inventory() -> void:
	for i in inventory_grid.get_child_count():
		var slot: BaseInventorySlot = inventory_grid.get_child(i)
		slot.set_stack(InventoryManager.get_item_stack_by_index(i))

func on_inventory_slot_clicked(button: MouseButton, shift: bool, index: int) -> void:
	match button:
		MOUSE_BUTTON_LEFT:
			InventoryActions.click_slot(index)
		MOUSE_BUTTON_RIGHT:
			InventoryActions.split_slot(index, shift)
