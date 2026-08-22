extends TileMapLayer
var layer_id: StringName = &"tilled_soil"


func _ready() -> void:
	add_to_group(LevelLayer.GROUP)
	apply(SaveAndLoad.load_layer(self, layer_id))


func capture() -> Variant:
	return Marshalls.raw_to_base64(tile_map_data)


func apply(state: Variant) -> void:
	if state is not String:
		return

	var encoded := state as String
	var data := Marshalls.base64_to_raw(encoded)
	if data.is_empty() and not encoded.is_empty():
		push_error("갈린 땅 데이터를 풀지 못했다")
		return

	tile_map_data = data
