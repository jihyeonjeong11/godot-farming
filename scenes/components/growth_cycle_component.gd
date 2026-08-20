class_name GrowthCycleComponent
extends Node

const TILLED_SOIL_GROUP: StringName = &"tilled_dirt"

@export var current_growth_state: DataTypes.GrowthStates = DataTypes.GrowthStates.Seed
@export_range(5, 365) var days_until_harvest: int = 5

signal crop_maturity
signal crop_harvesting

var starting_day: int

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

	_watered_soil = get_tree().get_first_node_in_group(WateredSoilLayer.GROUP) as WateredSoilLayer
	return _watered_soil

func on_time_tick_day(day: int) -> void:
	if is_tile_watered():
		if starting_day == 0:
			starting_day = day
			
		growth_states(starting_day, day)

func growth_states(starting_day: int, current_day: int) -> void:
	if current_growth_state == DataTypes.GrowthStates.Maturity:
		return

	var days_passed: int = current_day - starting_day
	var final_state: int = DataTypes.GrowthStates.Maturity

	var state_index: int = roundi(float(days_passed) * final_state / days_until_harvest)
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
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
