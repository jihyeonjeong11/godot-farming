class_name WateredSoilLayer
extends TileMapLayer
## 물 준 칸만 그리는 레이어. TilledSoil 위에, LevelCrops 아래에 얹는다.
##
## 여기서는 오토타일(set_cells_terrain_connect)을 쓰지 않는다. 젖은 칸끼리만 서로
## 이어지면 밭 한가운데 젖은 한 칸이 또 동그란 섬이 돼서, 레이어를 나눈 이유가
## 그대로 사라진다. 대신 아래 TilledSoil 이 이미 고른 atlas 좌표를 그대로 베낀다.
## 두 아틀라스는 타일 65개의 좌표가 같고 모양도 같아서, 그러면 실루엣이 픽셀
## 단위로 겹치고 젖은 칸은 색만 바뀐 것처럼 보인다.
##
## 세이브에 넣지 않는다. 어차피 하루 지나면 다 마르니 불러왔을 때 마른 상태인
## 것이 자연스럽고, 그만큼 저장할 것도 없다.

## 씬에서 이 그룹에 넣어둔다. 작물은 런타임에 심겨서 NodePath 를 미리 못 꽂는다.
const GROUP: StringName = &"watered_soil"

## 젖은 흙 아틀라스의 소스 번호. 타일셋의 sources/N 과 같아야 한다.
@export var source_id: int = 6


func _ready() -> void:
	# 이 레이어는 순수 런타임 상태다. 세이브도 안 하고 씬에 그려둘 것도 없으니,
	# 에디터에서 실수로 남은 타일은 시작할 때 털고 간다.
	clear()
	SignalBus.time_tick_day.connect(on_time_tick_day)


## 갈린 땅이 고른 모양을 그대로 가져와 젖은 색으로만 바꾼다.
func water_cell(cell: Vector2i, tilled_soil: TileMapLayer) -> void:
	# 갈아둔 땅이 아니면 적실 것도 없다.
	if tilled_soil.get_cell_source_id(cell) == -1:
		return

	set_cell(cell, source_id, tilled_soil.get_cell_atlas_coords(cell))


func dry_cell(cell: Vector2i) -> void:
	erase_cell(cell)


func is_watered(cell: Vector2i) -> bool:
	return get_cell_source_id(cell) != -1


func on_time_tick_day(_day: int) -> void:
	# 작물도 같은 신호를 받아 젖은 칸인지 보고 자란다. 여기서 곧바로 지우면
	# 신호 연결 순서에 따라 작물이 마른 땅을 보게 돼서 영영 안 자란다.
	# 한 프레임 미뤄서 그날 자랄 것들이 다 자란 뒤에 말린다.
	dry_all.call_deferred()


## 하루가 지나면 물기가 다 마른다.
func dry_all() -> void:
	clear()
