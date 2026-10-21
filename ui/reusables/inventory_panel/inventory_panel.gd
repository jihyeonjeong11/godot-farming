extends PanelContainer

@onready var inventory_grid: GridContainer = %InventoryGrid
@onready var equipment_slots: Array[EquipSlot] = [%HelmetSlot, %ArmorSlot, %BootSlot]

func _ready() -> void:
	for i in inventory_grid.get_child_count():
		var slot: BaseInventorySlot = inventory_grid.get_child(i)
		slot.clicked.connect(on_inventory_slot_clicked.bind(i))
	for slot in equipment_slots:
		slot.clicked.connect(on_equipment_slot_clicked.bind(slot))
	InventoryManager.updated_inventory.connect(refresh_inventory)
	InventoryManager.updated_equipment.connect(refresh_equipment)
	refresh_inventory()
	refresh_equipment()

func refresh_equipment() -> void:
	for slot in equipment_slots:
		slot.set_stack(InventoryManager.get_equipment(slot.index))

func on_equipment_slot_clicked(button: MouseButton, _shift: bool, slot: EquipSlot) -> void:
	if button == MOUSE_BUTTON_LEFT:
		InventoryActions.select_equipment(slot.index, slot.slot_type)

func refresh_inventory() -> void:
	for i in inventory_grid.get_child_count():
		var slot: BaseInventorySlot = inventory_grid.get_child(i)
		slot.set_stack(InventoryManager.get_item_stack_by_index(i))

func on_inventory_slot_clicked(button: MouseButton, shift: bool, index: int) -> void:
	match button:
		MOUSE_BUTTON_LEFT:
			InventoryActions.select_stack(index)
		MOUSE_BUTTON_RIGHT:
			InventoryActions.select_split_stack(index, shift)
