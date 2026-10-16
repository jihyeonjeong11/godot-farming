extends Node


const VERSION = 2
const SLOT_COUNT = 10


var current_slot: int = -1
var states: Dictionary = {}
var seconds_elapsed: float = 0

var _pristine_states: Dictionary = {}


func _physics_process(delta: float) -> void :
	seconds_elapsed += delta



func register_state(state: AbstractGameState) -> void :
	states[state.name.to_snake_case()] = state
	_pristine_states[state.name.to_snake_case()] = state.to_serialized()
	print(states)




func new_game(slot: int) -> void :
	current_slot = slot
	seconds_elapsed = 0
	for state_name in _pristine_states.keys():
		states.get(state_name).from_serialized(_pristine_states.get(state_name, {}))
	save_current_game()





func save_current_game() -> void :
	if current_slot == -1: return

	save_game(current_slot)



func save_game(slot: int = -1) -> void :
	var file: FileAccess = FileAccess.open("user://slot_%d.save" % slot, FileAccess.WRITE)


	var data: Dictionary = {
		version = VERSION, 
		seconds_elapsed = seconds_elapsed, 
		saved_at = Time.get_unix_time_from_system(), 
		states = {}
	}

	if OS.has_feature("demo"):
		data.is_demo = true

	for state_name in states.keys():
		data.states[state_name] = states[state_name].to_serialized()

	file.store_string(JSON.stringify(data))
	file.close()


func delete_game(slot: int) -> void:
	var file_name: String = "user://slot_%d.save" % slot
	if FileAccess.file_exists(file_name):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file_name))
	if current_slot == slot:
		current_slot = -1


func has_loadable_games() -> bool:
	for i in range(0, SLOT_COUNT):
		var data = get_load_data(i)
		if not data.is_empty():
			return true
	return false



func load_game(target_slot: int) -> void :
	current_slot = target_slot

	var data: Dictionary = get_load_data(target_slot)

	if data.is_empty(): return

	seconds_elapsed = data.get("seconds_elapsed", 0)

	for state_name in data.states.keys():
		states.get(state_name).from_serialized(data.states.get(state_name, {}))



func get_load_data(target_slot: int) -> Dictionary:
	var file_name: String = "user://slot_%d.save" % target_slot

	if FileAccess.file_exists(file_name):
		var file: FileAccess = FileAccess.open(file_name, FileAccess.READ)
		var data: Dictionary = JSON.parse_string(file.get_as_text())
		file.close()

		if data.has("is_demo") and not OS.has_feature("demo"):
			return {}

		for state_name in data.states.keys():
			data.states[state_name] = JSON.parse_string(data.states[state_name])

		return data

	return {}
