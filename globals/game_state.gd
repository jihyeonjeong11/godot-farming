## TODO: Savemanager 추가한다음에 abstract_class 추가 상속할
extends AbstractGameState

signal lighting_changed()

enum BaseLighting{
	None, 
	Day, 
	Dusk, 
	Overcast, 
	Night, 
	House, 
	Cave, 
	Darkness
}

var base_lighting: BaseLighting = BaseLighting.Day:
	set(value):
		if base_lighting != value:
			base_lighting = value
			lighting_changed.emit()
	get:
		return base_lighting

var current_scene: DataTypes.Levels = DataTypes.Levels.MainMenu
## TODO: 인벤토리와 버프는 딕셔너리 형태로 변환해야 세이브 가능하
var inventory: Array[ItemStack] = []
var equipments: Array[ItemStack] = []

var selected_slot: int = 0
## TODO: 아직 계절이 없음
var current_weather: DataTypes.WeatherType = DataTypes.WeatherType.Sunny
var current_time : Dictionary = {
	"day": 0,
	"hour": 6,
	"minute": 0
}

var player_name: String = ""

var player_stat: BaseCharacterStats
var player_buffs: Array[StatBuff] = []
var player_vanity: Array[int] = [-1, -1, -1, -1]
var level_data: Dictionary = {}

var did_skip_tutorial: bool = false
var did_kill_first_zombie: bool = false

var farm_map: Dictionary = {}

# 현재 농장 맵만 적용함
var farm_snapshot: Dictionary = {}:
	get: 
		return farm_snapshot 
	set(value):
		farm_snapshot = value

var tutorial_flags: Dictionary = {
	"startup": false,
	"sighted_corpse": false,
	"obtained_sword": false,
	"sighted_horde": false,
	"sighted_anomaly": false,
	"passed_anomaly": false,
	"sighted_house": false,
	"obtained_medicine": false,
	"ambushed": false,
	"arrived_farm_entrance": false
}

func _ready() -> void:
	_ensure_player_stat()
	_ensure_equipment_slots()
	
func has_tutorial_flag(key: String) -> bool:
	return tutorial_flags.get(key, false)


func set_tutorial_flag(key: String) -> void:
	if not tutorial_flags.has(key):
		push_warning("모르는 튜토리얼 플래그: %s" % key)
	tutorial_flags[key] = true


func _get_unique_properties(node: Node) -> Array:
	var properties := super(node)
	properties.erase("farm_map")
	return properties


func _after_deserialized() -> void:
	inventory.resize(InventoryManager.BASE_INVENTORY_LIMIT)
	_ensure_equipment_slots()
	StatActions.apply_equipment()


func _ensure_equipment_slots() -> void:
	equipments.resize(3)


func _ensure_player_stat() -> void:
	if player_stat != null:
		return
	player_stat = SessionState.PLAYER_STAT_BASE.duplicate()
	player_stat.setup_stats()


func _serialize_property(property: String, value: Variant) -> Variant:
	match property:
		"player_stat":
			return value.to_dict() if value else null
		"inventory", "armor", "boots", "equipments":
			return value.map(func(stack: ItemStack) -> Variant: return stack.to_dict() if stack else null)
	return value


func _deserialize_property(property: String, value: Variant) -> Variant:
	_ensure_player_stat()
	match property:
		"player_stat":
			if value is not Dictionary:
				return null
			var stats: BaseCharacterStats = SessionState.PLAYER_STAT_BASE.duplicate()
			stats.from_dict(value)
			return stats
		"inventory", "armor", "boots", "equipments":
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
		"farm_snapshot":
			var snapshot: Dictionary = {}
			for key: String in value:
				var parts := key.trim_prefix("(").trim_suffix(")").split(",")
				snapshot[Vector2i(parts[0].to_int(), parts[1].strip_edges().to_int())] = value[key]
			return snapshot
	return value
