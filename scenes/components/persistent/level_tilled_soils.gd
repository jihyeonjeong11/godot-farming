extends TileMapLayer
## 호미로 갈아둔 땅. 여기만 노드가 아니라 타일이라 저장 방식이 다르다.
## TilledSoil TileMapLayer 에 직접 붙인다.
##
## 다른 레이어와 달리 LevelLayer 를 상속하지 않는다. GDScript 는 다중 상속이 없어서
## "타일맵이면서 동시에 LevelLayer" 가 될 수 없기 때문이다. 대신 같은 그룹에 들어가
## layer_id / capture / apply 세 가지만 똑같이 갖춘다. SaveAndLoad 는 그것만 본다.
##
## 셀을 하나씩 적을 이유가 없다. tile_map_data 하나에 셀 좌표·소스·대체타일이
## 전부 들어 있다. 파일에 넣을 땐 base64로 접는다 — 그대로 넣으면 바이트 하나가
## 숫자 하나가 돼서 밭 몇 칸에 세이브가 몇 KB씩 불어난다.

var layer_id: StringName = &"tilled_soil"


func _ready() -> void:
	add_to_group(LevelLayer.GROUP)
	apply(SaveAndLoad.load_layer(self, layer_id))


func capture() -> Variant:
	return Marshalls.raw_to_base64(tile_map_data)


func apply(state: Variant) -> void:
	# 세이브가 없으면 아무것도 안 한다. 씬에 그려둔 밭이 곧 초기 상태다.
	if state is not String:
		return

	var encoded := state as String
	var data := Marshalls.base64_to_raw(encoded)
	if data.is_empty() and not encoded.is_empty():
		push_error("갈린 땅 데이터를 풀지 못했다")
		return

	tile_map_data = data
