class_name AbstractGameState extends Node

var toggles: Dictionary = {}
var counters: Dictionary = {}

var _node_properties: PackedStringArray = []

func _enter_tree() -> void :
	SaveManager.register_state(self)






func _after_deserialized() -> void :
	pass









func once(key: String) -> bool:
	return times(key) == 0



func times(key: String, max: int = 100000) -> int:
	var value: int = counters.get(key, 0)
	counters[key] = clamp(value + 1, 0, max)
	return value



func check_count(key: String) -> int:
	return counters.get(key, 0)



func times_wrap(key: String, wrap_at: int = 100000) -> int:
	var value: int = counters.get(key, 0)
	counters[key] = wrapi(value + 1, 0, wrap_at)
	return value








func from_serialized(string_or_data) -> void :
	var data: Dictionary = string_or_data if string_or_data is Dictionary else JSON.parse_string(string_or_data)
	for property in _get_unique_properties(self):
		if data.has(property):
			set(property, data.get(property))

	_after_deserialized()



func to_serialized() -> String:
	var data = {}
	for property in _get_unique_properties(self):
		data[property] = get(property)

	return JSON.stringify(data)


func _get_unique_properties(node: Node) -> Array:
	var unique_properties = []
	var known_node_properties = _get_node_properties()
	for property in node.get_property_list():
		if not known_node_properties.has(property.name) and not property.name.ends_with(".gd"):
			unique_properties.append(property.name)
	return unique_properties


func _get_node_properties() -> Array:
	if _node_properties.size() == 0:
		_node_properties = ["Script Variables", "_node_properties"]
		var temp_node = Node.new()
		for property in temp_node.get_property_list():
			_node_properties.append(property.name)
		temp_node.free()
	return _node_properties
