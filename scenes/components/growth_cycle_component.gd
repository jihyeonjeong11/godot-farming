class_name GrowthCycleComponent
extends Node

@export var current_growth_state: ApoDataTypes.GrowthStates = ApoDataTypes.GrowthStates.Seed
@export_range(5, 365) var days_until_harvest: int = 5

signal crop_maturity
signal crop_harvesting

var is_watered: bool
var starting_day: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.time_tick_day.connect(on_time_tick_day)

func on_time_tick_day(day: int) -> void:
	if is_watered:
		if starting_day == 0:
			starting_day = day
			
		growth_states(starting_day, day)
			
## Germination ~ Maturity를 days_until_harvest일에 걸쳐 고르게 배분한다.
## 작물마다 자라는 속도가 다르므로 "하루에 한 단계" 고정이 아니라 기간 기준이다.
func growth_states(starting_day: int, current_day: int) -> void:
	if current_growth_state == ApoDataTypes.GrowthStates.Maturity:
		return

	var days_passed: int = current_day - starting_day
	var final_state: int = ApoDataTypes.GrowthStates.Maturity

	var state_index: int = roundi(float(days_passed) * final_state / days_until_harvest)
	current_growth_state = clampi(state_index, ApoDataTypes.GrowthStates.Germination, final_state)

	if current_growth_state == ApoDataTypes.GrowthStates.Maturity:
		crop_maturity.emit()
		
func harvest_state(starting_day: int, current_day: int):
	if current_growth_state == ApoDataTypes.GrowthStates.Harvesting:
		return
	
	var days_passed = (current_day - starting_day) % days_until_harvest
	
	if days_passed == days_until_harvest -1:
		current_growth_state = ApoDataTypes.GrowthStates.Harvesting
		crop_harvesting.emit()
	
func get_current_growth_state() -> ApoDataTypes.GrowthStates:
	return current_growth_state
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
