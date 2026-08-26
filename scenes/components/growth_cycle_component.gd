class_name GrowthCycleComponent
extends Node

const TILLED_SOIL_GROUP: StringName = &"tilled_dirt"

@export var current_growth_state: DataTypes.GrowthStates = DataTypes.GrowthStates.Seed
@export_range(1, 365) var days_until_harvest: int

signal crop_maturity
signal crop_harvesting

var watered_days: int = 0

@onready var crop: Node2D = get_parent() as Node2D

var _tilled_soil: TileMapLayer
var _watered_soil: WateredSoilLayer

func _ready() -> void:
	SignalBus.time_tick_day.connect(on_time_tick_day)

func get_planted_tile() -> TileData:
	var soil := get_tilled_soil()
	if soil == null or crop == null:
		return null

	var cell := soil.local_to_map(soil.to_local(crop.global_position))
	return soil.get_cell_tile_data(cell)

func is_tile_watered() -> bool:
	var watered := get_watered_soil()
	if watered == null or crop == null:
		return false

	return watered.is_watered(watered.local_to_map(watered.to_local(crop.global_position)))


func get_tilled_soil() -> TileMapLayer:
	if is_instance_valid(_tilled_soil):
		return _tilled_soil

	_tilled_soil = get_tree().get_first_node_in_group(TILLED_SOIL_GROUP) as TileMapLayer
	return _tilled_soil


func get_watered_soil() -> WateredSoilLayer:
	if is_instance_valid(_watered_soil):
		return _watered_soil

	_watered_soil = get_tree().get_first_node_in_group(WateredSoilLayer.layer_id) as WateredSoilLayer
	return _watered_soil

## 물 안 준 날은 아예 진행이 없다. 그래서 날짜를 받지 않는다.
func on_time_tick_day(_day: int) -> void:
	if not is_tile_watered():
		return

	watered_days += 1
	growth_states()

func growth_states() -> void:
	if current_growth_state == DataTypes.GrowthStates.Maturity:
		return

	var final_state: int = DataTypes.GrowthStates.Maturity

	var state_index: int = roundi(float(watered_days) * final_state / days_until_harvest)
	current_growth_state = clampi(state_index, DataTypes.GrowthStates.Germination, final_state)

	if current_growth_state == DataTypes.GrowthStates.Maturity:
		crop_maturity.emit()
		
func harvest_state(starting_day: int, current_day: int):
	if current_growth_state == DataTypes.GrowthStates.Harvesting:
		return
	
	var days_passed = (current_day - starting_day) % days_until_harvest
	
	if days_passed == days_until_harvest -1:
		current_growth_state = DataTypes.GrowthStates.Harvesting
		crop_harvesting.emit()
	
func get_current_growth_state() -> DataTypes.GrowthStates:
	return current_growth_state


## 씬 경로와 위치만으로는 복원되지 않는 것. 지금 단계와, 물을 며칠 줬는지다.
## days_until_harvest는 씬에 적어둔 설정값이라 저장하지 않는다. 저장하면 나중에
## 작물 밸런스를 고쳐도 옛 세이브가 옛 값을 붙든다.
func capture() -> Dictionary:
	return {
		"growth_state": int(current_growth_state),
		"watered_days": watered_days,
	}


func apply(state: Variant) -> void:
	if state is not Dictionary:
		return

	current_growth_state = int(state.get("growth_state", current_growth_state))
	watered_days = int(state.get("watered_days", watered_days))
