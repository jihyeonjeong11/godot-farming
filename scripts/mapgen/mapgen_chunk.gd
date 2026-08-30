## mapgen JSON 한 덩어리. CDDA 의 mapgen_function_json 대응.
##
## rows 를 로드 시점에 지형으로 확정하지 않고 문자 그대로 들고 있는 게 핵심이다.
## 팔레트가 한 문자에 가중치 목록을 물릴 수 있기 때문에("t_floor 10, t_dirtfloor 1"),
## 같은 청크라도 찍을 때마다 결과가 달라야 한다. CDDA 도 같은 이유로 매 인스턴스마다 굴린다.
class_name MapgenChunk
extends RefCounted

var id: String
var oter: String = ""              ## om_terrain. 이게 붙은 청크만 건물 카탈로그가 뽑는다.
var weight: int = 100
var size: Vector2i
var rows: PackedStringArray        ## 문자 그대로. 폭은 전부 size.x 로 맞춰져 있다.
var fill_ter: int = MapgenDefs.Ter.NULL
var palette_ids: PackedStringArray ## 참조하는 팔레트 id 들. 뒤에 오는 게 앞을 덮는다.
var local_ter: Dictionary = {}     ## 이 청크에만 있는 문자 override
var local_furn: Dictionary = {}
var nested: Array[Dictionary] = [] ## [{ "chunks": [[id, w], ...], "pos": Vector2i }]


static func from_json(chunk_id: String, src: Dictionary) -> MapgenChunk:
	var c := MapgenChunk.new()
	c.id = chunk_id
	c.oter = str(src.get("om_terrain", ""))
	c.weight = int(src.get("weight", 100))

	var obj: Dictionary = src.get("object", {})
	var raw: Array = obj.get("rows", [])
	if raw.is_empty():
		push_error("mapgen '%s': rows 가 비었다" % chunk_id)
		return null

	var w := 0
	for r: Variant in raw:
		w = maxi(w, str(r).length())
	for r: Variant in raw:
		# 짧은 줄은 공백으로 채운다. 손으로 쓴 ASCII 는 끝 공백이 잘리기 쉽다.
		c.rows.append(str(r).rpad(w))
	c.size = Vector2i(w, c.rows.size())

	c.fill_ter = MapgenDefs.TER_BY_ID.get(str(obj.get("fill_ter", "t_null")), MapgenDefs.Ter.NULL)
	for p: Variant in obj.get("palette", []):
		c.palette_ids.append(str(p))
	c.local_ter = obj.get("terrain", {})
	c.local_furn = obj.get("furniture", {})

	for n: Variant in obj.get("place_nested", []):
		var d: Dictionary = n
		c.nested.append({
			"chunks": d.get("chunks", []),
			"pos": Vector2i(int(d.get("x", 0)), int(d.get("y", 0))),
		})
	return c
