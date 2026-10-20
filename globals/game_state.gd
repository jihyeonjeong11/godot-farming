## TODO: Savemanager 추가한다음에 abstract_class 추가 상속할
extends AbstractGameState

enum BaseLighting{
	None, 
	Day, 
	Overcast, 
	Night, 
	House, 
	Cave, 
	Darkness
}

var current_scene: DataTypes.Levels = DataTypes.Levels.MainMenu
## TODO: 인벤토리와 버프는 딕셔너리 형태로 변환해야 세이브 가능하
var inventory: Array[ItemStack] = []
var armor: Array[ItemStack] = []
var boots: Array[ItemStack] = []
# 0 ~ 9
var selected_slot: int = 0
## TODO: 아직 계절이 없음
var current_weather: DataTypes.WeatherType = DataTypes.WeatherType.Sunny
var current_time : Dictionary = {
	"day": 0,
	"hour": 6,
	"minute": 0
}

var player_stat: BaseCharacterStats
var player_buffs: Array[StatBuff] = []
var player_vanity: Array[int] = [-1, -1, -1, -1]
var level_data: Dictionary = {}

var did_skip_tutorial: bool = false
var did_kill_first_zombie: bool = false


#func _after_deserialized() -> void:
	#_restore_slots(InventoryManager.inventory, inventory, InventoryManager.BASE_INVENTORY_LIMIT)
	#_restore_slots(InventoryManager.armor, armor, InventoryManager.EQUIPMENT_SLOT_LIMIT)
	#_restore_slots(InventoryManager.boots, boots, InventoryManager.EQUIPMENT_SLOT_LIMIT)
#
	#InventoryManager.selected_slot = -1
	#InventoryManager.select_slot(maxi(selected_slot, 0))
	#InventoryManager.inventory_updated.emit()
	#InventoryManager.equipment_updated.emit()


#func _restore_slots(target: Array[ItemStack], source: Array[ItemStack], size: int) -> void:
	#target.resize(size)
	#target.fill(null)
	#for i in mini(source.size(), size):
		#target[i] = source[i]


func _serialize_property(property: String, value: Variant) -> Variant:
	match property:
		"player_stat":
			return value.to_dict() if value else null
		"inventory", "armor", "boots":
			return value.map(func(stack: ItemStack) -> Variant: return stack.to_dict() if stack else null)
	return value


func _deserialize_property(property: String, value: Variant) -> Variant:
	match property:
		"player_stat":
			if value is not Dictionary:
				return null
			var stats: BaseCharacterStats = SessionState.PLAYER_STAT_BASE.duplicate()
			stats.from_dict(value)
			return stats
		"inventory", "armor", "boots":
			var stacks: Array[ItemStack] = []
			for data in value:
				stacks.append(ItemStack.from_dict(data))
			return stacks
		"player_vanity":
			var vanity: Array[int] = []
			vanity.assign(value)
			return vanity
		"current_time":
			var time: Dictionary = {}
			for key in value:
				time[key] = int(value[key])
			return time
	return value
