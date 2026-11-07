class_name WateredSoilLayer
extends TileMapLayer

const GROUP := &"watered_soil"

@export var source_id: int = 6
@export var atlas_offset: Vector2i = Vector2i.ZERO


func _ready() -> void:
	clear()


func water_cell(cell: Vector2i, tilled_soil: TileMapLayer) -> void:
	if tilled_soil.get_cell_source_id(cell) == -1:
		return
	set_cell(cell, source_id, tilled_soil.get_cell_atlas_coords(cell) + atlas_offset)


func dry_cell(cell: Vector2i) -> void:
	erase_cell(cell)


func is_watered(cell: Vector2i) -> bool:
	return get_cell_source_id(cell) != -1


func on_time_tick_day(_day: int) -> void:
	dry_all.call_deferred()


func dry_all() -> void:
	clear()
