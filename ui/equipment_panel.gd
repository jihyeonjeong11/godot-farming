extends VBoxContainer
## 갑옷·신발 칸을 Inventory 의 착용 배열에 이어준다.
##
## 이 스크립트는 EquipmentPanel 노드 자신에 붙는다. 노드 경로는 여기서부터 센다.

@onready var armor_slot: EquipmentSlot = $HBoxContainer/EquipmentSlot
@onready var boots_slot: EquipmentSlot = $HBoxContainer2/EquipmentSlot


func _ready() -> void:
	_bind(armor_slot, DataTypes.WearSlot.Armor)
	_bind(boots_slot, DataTypes.WearSlot.Boots)

	Inventory.equipment_updated.connect(refresh)
	Inventory.inventory_updated.connect(refresh)

	refresh()


## 칸이 가리킬 배열과 받아줄 부위를 한자리에서 꽂는다.
## 셋 중 하나만 빠져도 조용히 안 되는 칸이 되므로 따로 두지 않는다.
func _bind(slot: EquipmentSlot, wear_slot: DataTypes.WearSlot) -> void:
	slot.slot_index = 0
	slot.slot_type = wear_slot
	slot.source = Inventory.equipment_source(wear_slot)


func refresh() -> void:
	armor_slot.set_slot(Inventory.armor[0])
	boots_slot.set_slot(Inventory.boots[0])
