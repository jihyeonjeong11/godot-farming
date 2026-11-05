class_name WateredSoilLayer
extends LevelTileMapLayer
const GROUP := &"watered_soil"

@export var source_id: int = 6

@export var atlas_offset: Vector2i = Vector2i.ZERO

var last_day: int = -1


func _init() -> void:
	layer_id = GROUP


func _ready() -> void:
	clear()
	super()


func water_cell(cell: Vector2i, tilled_soil: TileMapLayer) -> void:
	if tilled_soil.get_cell_source_id(cell) == -1:
		return
	set_cell(cell, source_id, tilled_soil.get_cell_atlas_coords(cell) + atlas_offset)
	
	


func dry_cell(cell: Vector2i) -> void:
	erase_cell(cell)


func is_watered(cell: Vector2i) -> bool:
	return get_cell_source_id(cell) != -1


func on_time_tick_day(day: int) -> void:
	last_day = day
	dry_all.call_deferred()


func _today() -> int:
	return 1
	#var tm := TimeManager.find(get_tree())
	#return tm.today() if tm != null else last_day


func capture() -> Variant:
	return {"tiles": super(), "last_day": last_day}


## 비운 사이 날이 넘어갔으면 말린다. 작물이 젖은 밭을 보고 따라잡은 뒤에
## 말려야 해서 deferred 로 미룬다.
func apply(state: Variant) -> void:
	var today := _today()
	if state is Dictionary:
		super(state.get("tiles", ""))
		last_day = int(state.get("last_day", today))
	else:
		super(state)
		last_day = today

	if last_day >= 0 and last_day < today:
		dry_all.call_deferred()
	last_day = today


## 하루가 지나면 물기가 다 마른다.
func dry_all() -> void:
	clear()
