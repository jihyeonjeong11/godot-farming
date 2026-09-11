class_name WateredSoilLayer
extends LevelTileMapLayer
const GROUP := &"watered_soil"

@export var source_id: int = 6
## 젖은 땅 그림이 갈린 땅 그림과 같은 아틀라스에서 몇 칸 떨어져 있는지.
## 두 세트의 타일 배치가 똑같아야 이 방식이 성립한다. 같은 좌표를 쓰는
## 타일셋이면 0 으로 두면 된다.
@export var atlas_offset: Vector2i = Vector2i.ZERO


func _init() -> void:
	layer_id = GROUP


func _ready() -> void:
	SignalBus.time_tick_day.connect(on_time_tick_day)
	clear()
	super()


func water_cell(cell: Vector2i, tilled_soil: TileMapLayer) -> void:
	if tilled_soil.get_cell_source_id(cell) == -1:
		return

	# 갈린 땅이 이미 오토타일로 고른 모양을 그대로 베낀다. 젖은 세트를 따로
	# 오토타일로 칠하면 밭 전체가 아니라 물 준 칸끼리만 이어져 모양이 어긋난다.
	set_cell(cell, source_id, tilled_soil.get_cell_atlas_coords(cell) + atlas_offset)
	
	


func dry_cell(cell: Vector2i) -> void:
	erase_cell(cell)


func is_watered(cell: Vector2i) -> bool:
	return get_cell_source_id(cell) != -1


func on_time_tick_day(_day: int) -> void:
	dry_all.call_deferred()


## 하루가 지나면 물기가 다 마른다.
func dry_all() -> void:
	clear()
