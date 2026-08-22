class_name WateredSoilLayer
extends TileMapLayer
const layer_id: StringName = &"watered_soil"

@export var source_id: int = 6


func _ready() -> void:
	SignalBus.time_tick_day.connect(on_time_tick_day)
	clear()
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



func water_cell(cell: Vector2i, tilled_soil: TileMapLayer) -> void:
	if tilled_soil.get_cell_source_id(cell) == -1:
		return

	set_cell(cell, source_id, tilled_soil.get_cell_atlas_coords(cell))
	
	


func dry_cell(cell: Vector2i) -> void:
	erase_cell(cell)


func is_watered(cell: Vector2i) -> bool:
	return get_cell_source_id(cell) != -1


func on_time_tick_day(_day: int) -> void:
	dry_all.call_deferred()


## 하루가 지나면 물기가 다 마른다.
func dry_all() -> void:
	clear()
