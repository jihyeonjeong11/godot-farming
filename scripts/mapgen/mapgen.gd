## CDDA mapgen 이식 — 팔레트 + ASCII rows + 회전 + 중첩 청크.
##
## 쓰는 쪽에서 보면 이게 전부다:
##     var mg := Mapgen.new()
##     mg.load_all()
##     var baked := mg.bake("house_small", rng)      # 문자 -> 지형/가구
##     mg.blit(baked, ter, furn, origin, turns, W)   # 회전해서 세계 격자에 굽기
##
## 굽기(bake)와 붙이기(blit)를 나눈 이유:
##   * 중첩 청크(place_nested)는 부모의 회전 전 좌표계에 얹힌다. 먼저 평평하게 합친 뒤
##     통째로 돌려야 자식이 부모와 같이 돈다. CDDA 도 rotate 를 마지막에 한 번만 한다.
##   * 굽기 결과를 들여다보면 회전/좌표 문제와 팔레트 문제를 따로 디버깅할 수 있다.
class_name Mapgen
extends RefCounted

const DATA_DIR := "res://data/mapgen"

## 팔레트 id -> { "ter": {문자: 값}, "furn": {문자: 값} }
## 값은 int 이거나 [[int, weight], ...] 다. 후자는 찍을 때마다 굴린다.
var palettes: Dictionary = {}
## 청크 id -> MapgenChunk
var chunks: Dictionary = {}
## om_terrain -> [[chunk_id, weight], ...]. 건물 카탈로그가 여기서 뽑는다.
var by_oter: Dictionary = {}


# ──────────────────────────────────────────────────────────────
# 로딩
# ──────────────────────────────────────────────────────────────
func load_all(dir: String = DATA_DIR) -> void:
	palettes.clear()
	chunks.clear()
	by_oter.clear()
	# 팔레트가 먼저다. 청크가 팔레트를 참조하므로 순서가 뒤집히면 못 찾는다.
	var files := _json_files(dir)
	for f: String in files:
		var d := _read_json(f)
		if d.get("type", "") == "palette":
			_add_palette(d)
	for f: String in files:
		var d := _read_json(f)
		if d.get("type", "") == "mapgen":
			_add_mapgen(d, f)


func _json_files(dir: String) -> PackedStringArray:
	var out := PackedStringArray()
	var da := DirAccess.open(dir)
	if da == null:
		push_error("mapgen: %s 를 열 수 없다" % dir)
		return out
	da.list_dir_begin()
	while true:
		var name := da.get_next()
		if name == "":
			break
		if name.begins_with("."):
			continue
		var path := dir.path_join(name)
		if da.current_is_dir():
			out.append_array(_json_files(path))
		elif name.ends_with(".json"):
			out.append(path)
	da.list_dir_end()
	return out


func _read_json(path: String) -> Dictionary:
	# 에디터에서는 원본 .json 이 그대로 있고, 익스포트하면 임포트된 JSON 리소스가 된다.
	# 둘 다 받아준다.
	var res := ResourceLoader.load(path)
	if res is JSON and (res as JSON).data is Dictionary:
		return (res as JSON).data
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("mapgen: %s 를 읽을 수 없다" % path)
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	push_error("mapgen: %s 파싱 실패" % path)
	return {}


func _add_palette(d: Dictionary) -> void:
	palettes[str(d.get("id", ""))] = {
		"ter": _compile(d.get("terrain", {}), MapgenDefs.TER_BY_ID, "지형"),
		"furn": _compile(d.get("furniture", {}), MapgenDefs.FURN_BY_ID, "가구"),
	}


## 문자열 id 를 enum 값으로 미리 바꿔둔다. 가중치 목록은 형태를 유지한 채 값만 바꾼다.
func _compile(src: Dictionary, table: Dictionary, what: String) -> Dictionary:
	var out := {}
	for ch: Variant in src:
		var v: Variant = src[ch]
		if v is Array:
			var opts: Array = []
			for e: Variant in v:
				# CDDA 형식: ["t_floor", 10]. 가중치를 빼먹으면 1로 친다.
				var eid: String = str(e[0]) if e is Array else str(e)
				var ew: int = int(e[1]) if e is Array and (e as Array).size() > 1 else 1
				if not table.has(eid):
					push_error("mapgen 팔레트: 모르는 %s id '%s'" % [what, eid])
					continue
				opts.append([table[eid], ew])
			if not opts.is_empty():
				out[str(ch)] = opts
		else:
			var sid := str(v)
			if table.has(sid):
				out[str(ch)] = table[sid]
			else:
				push_error("mapgen 팔레트: 모르는 %s id '%s'" % [what, sid])
	return out


func _add_mapgen(d: Dictionary, path: String) -> void:
	var cid := str(d.get("id", path.get_file().get_basename()))
	var c := MapgenChunk.from_json(cid, d)
	if c == null:
		return
	chunks[cid] = c
	if c.oter != "":
		if not by_oter.has(c.oter):
			by_oter[c.oter] = []
		(by_oter[c.oter] as Array).append([cid, c.weight])


# ──────────────────────────────────────────────────────────────
# 뽑기
# ──────────────────────────────────────────────────────────────
## om_terrain 에 걸린 청크들 중 가중치로 하나. CDDA 의 weighted_list<mapgen_function> 대응.
func pick_for_oter(oter: String, rng: RandomNumberGenerator) -> String:
	var list: Array = by_oter.get(oter, [])
	if list.is_empty():
		return ""
	return _weighted(list, rng)


func _weighted(list: Array, rng: RandomNumberGenerator) -> String:
	var total := 0
	for e: Variant in list:
		total += int(e[1])
	if total <= 0:
		return str(list[0][0])
	var roll := rng.randi_range(0, total - 1)
	for e: Variant in list:
		roll -= int(e[1])
		if roll < 0:
			return str(e[0])
	return str(list[list.size() - 1][0])


# ──────────────────────────────────────────────────────────────
# 굽기 — 문자 격자를 지형/가구 격자로
# ──────────────────────────────────────────────────────────────
## 반환: { "size": Vector2i, "ter": PackedByteArray, "furn": PackedByteArray }
## 회전 전 좌표계다. 중첩 청크는 이 안에서 이미 합쳐져 있다.
func bake(chunk_id: String, rng: RandomNumberGenerator) -> Dictionary:
	var c: MapgenChunk = chunks.get(chunk_id)
	if c == null:
		push_error("mapgen: 없는 청크 '%s'" % chunk_id)
		return {}

	var n := c.size.x * c.size.y
	var ter := PackedByteArray()
	var furn := PackedByteArray()
	ter.resize(n)
	furn.resize(n)
	ter.fill(c.fill_ter)
	furn.fill(MapgenDefs.Furn.NULL)

	var pal := _merged_palette(c)
	for y in c.size.y:
		var line := c.rows[y]
		for x in c.size.x:
			var ch := line[x]
			var i := y * c.size.x + x
			# 문자가 지형 표에 있으면 지형을 정하고, 없으면 fill_ter 를 그대로 둔다.
			# CDDA 와 같다 — 가구 문자(T, c ...)는 지형표에 없어서 바닥 위에 얹힌다.
			if pal["ter"].has(ch):
				ter[i] = _roll(pal["ter"][ch], rng)
			if pal["furn"].has(ch):
				furn[i] = _roll(pal["furn"][ch], rng)

	var out := {"size": c.size, "ter": ter, "furn": furn}
	for nest: Dictionary in c.nested:
		var pick := _weighted(nest["chunks"], rng)
		if pick == "":
			continue
		var sub := bake(pick, rng)
		if sub.is_empty():
			continue
		_merge(out, sub, nest["pos"])
	return out


func _merged_palette(c: MapgenChunk) -> Dictionary:
	var ter := {}
	var furn := {}
	for pid: String in c.palette_ids:
		var p: Dictionary = palettes.get(pid, {})
		if p.is_empty():
			push_error("mapgen '%s': 없는 팔레트 '%s'" % [c.id, pid])
			continue
		ter.merge(p["ter"], true)
		furn.merge(p["furn"], true)
	# 청크 자신의 override 가 팔레트를 이긴다.
	ter.merge(_compile(c.local_ter, MapgenDefs.TER_BY_ID, "지형"), true)
	furn.merge(_compile(c.local_furn, MapgenDefs.FURN_BY_ID, "가구"), true)
	return {"ter": ter, "furn": furn}


func _roll(v: Variant, rng: RandomNumberGenerator) -> int:
	if v is Array:
		var list: Array = v
		var total := 0
		for e: Variant in list:
			total += int(e[1])
		var r := rng.randi_range(0, maxi(total, 1) - 1)
		for e: Variant in list:
			r -= int(e[1])
			if r < 0:
				return int(e[0])
		return int(list[list.size() - 1][0])
	return int(v)


## 자식 청크를 부모 버퍼 위에 얹는다. 자식의 NULL 칸은 부모를 안 지운다 —
## 그래야 방 하나짜리 청크를 집 안에 떨궈도 주변 바닥이 살아남는다.
func _merge(dst: Dictionary, src: Dictionary, at: Vector2i) -> void:
	var ds: Vector2i = dst["size"]
	var ss: Vector2i = src["size"]
	var dter: PackedByteArray = dst["ter"]
	var dfurn: PackedByteArray = dst["furn"]
	var ster: PackedByteArray = src["ter"]
	var sfurn: PackedByteArray = src["furn"]
	for y in ss.y:
		var dy := at.y + y
		if dy < 0 or dy >= ds.y:
			continue
		for x in ss.x:
			var dx := at.x + x
			if dx < 0 or dx >= ds.x:
				continue
			var si := y * ss.x + x
			var di := dy * ds.x + dx
			if ster[si] != MapgenDefs.Ter.NULL:
				dter[di] = ster[si]
			if sfurn[si] != MapgenDefs.Furn.NULL:
				dfurn[di] = sfurn[si]


# ──────────────────────────────────────────────────────────────
# 붙이기 — 회전해서 세계 격자에 굽는다
# ──────────────────────────────────────────────────────────────
## 회전 뒤 크기. 청크를 어디에 놓을지 정하려면 찍기 전에 이걸 알아야 한다.
static func rotated_size(size: Vector2i, turns: int) -> Vector2i:
	return size if (turns & 1) == 0 else Vector2i(size.y, size.x)


## turns 는 시계방향 90도 횟수. 청크는 정면이 북쪽(rows 의 첫 줄)을 보게 그려져 있고,
## turns 만큼 돌리면 정면이 그 방향을 본다 — CDDA 의 house_north/_east/... 와 같은 규칙이다.
## world_w 는 목적지 격자의 한 변(정사각).
func blit(baked: Dictionary, world_ter: PackedByteArray, world_furn: PackedByteArray,
		origin: Vector2i, turns: int, world_w: int) -> void:
	if baked.is_empty():
		return
	var s: Vector2i = baked["size"]
	var ter: PackedByteArray = baked["ter"]
	var furn: PackedByteArray = baked["furn"]
	var out := rotated_size(s, turns)
	var t := turns & 3

	for y in out.y:
		var wy := origin.y + y
		if wy < 0 or wy >= world_w:
			continue
		for x in out.x:
			var wx := origin.x + x
			if wx < 0 or wx >= world_w:
				continue
			# 목적지 칸이 원본의 어느 칸에서 왔는지 역으로 찾는다.
			var sx := x
			var sy := y
			match t:
				1: sx = y; sy = s.y - 1 - x
				2: sx = s.x - 1 - x; sy = s.y - 1 - y
				3: sx = s.x - 1 - y; sy = x
			var si := sy * s.x + sx
			if ter[si] == MapgenDefs.Ter.NULL:
				continue  # 청크의 빈 칸은 세계를 안 건드린다
			var wi := wy * world_w + wx
			world_ter[wi] = ter[si]
			world_furn[wi] = furn[si]
