## mapgen 검증기. 타일맵 없이 ter/furn 격자만 찍어서 눈으로 본다.
##   Godot_v4.7.1... --headless --path . --script tools/test_mapgen.gd
##
## 프리팹이 화면에서 이상하면 원인이 (a) 팔레트/문자 (b) 회전 (c) 타일 고르기
## 셋 중 어딘지 알아야 하는데, 이게 (a)와 (b)만 떼어놓고 보여준다.
extends SceneTree

const GLYPH := {
	MapgenDefs.Ter.NULL: " ",
	MapgenDefs.Ter.FLOOR: ".",
	MapgenDefs.Ter.WALL: "#",
	MapgenDefs.Ter.WINDOW: "'",
	MapgenDefs.Ter.DOOR_C: "+",
	MapgenDefs.Ter.DOOR_O: "/",
	MapgenDefs.Ter.WALL_BROKEN: "x",
	MapgenDefs.Ter.RUBBLE: "%",
}
const FURN_GLYPH := {
	MapgenDefs.Furn.TABLE: "T",
	MapgenDefs.Furn.COUNTER: "K",
	MapgenDefs.Furn.SHELF: "S",
	MapgenDefs.Furn.SINK: "W",
	MapgenDefs.Furn.FRIDGE: "F",
	MapgenDefs.Furn.LOCKER: "L",
}


func _initialize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345

	var mg := Mapgen.new()
	mg.load_all()
	print("팔레트 %d개, 청크 %d개, oter %s" % [
		mg.palettes.size(), mg.chunks.size(), str(mg.by_oter.keys())])
	print("")

	var ok := true
	for cid: String in mg.chunks:
		var baked := mg.bake(cid, rng)
		if baked.is_empty():
			ok = false
			continue
		var c: MapgenChunk = mg.chunks[cid]
		print("── %s  (oter=%s, w=%d)  %dx%d" % [cid, c.oter, c.weight, c.size.x, c.size.y])
		_dump(baked)
		# 지형이 하나도 안 붙었으면 팔레트 문자가 안 맞은 것이다.
		var walls := 0
		for t: int in baked["ter"]:
			if t == MapgenDefs.Ter.WALL:
				walls += 1
		if walls == 0:
			print("  !! 벽이 하나도 없다 — 팔레트 문자 확인")
			ok = false
		print("")

	# ── 회전 ────────────────────────────────────────────────
	# 정면(문)이 어느 변으로 가는지가 전부다. turns=0 이면 첫 줄에 있어야 한다.
	print("── 회전 검증: house_small 의 문(+) 위치")
	var base := mg.bake("house_small", rng)
	for turns in 4:
		var size := Mapgen.rotated_size(base["size"], turns)
		var world := PackedByteArray()
		var wfurn := PackedByteArray()
		var w := 64
		world.resize(w * w)
		wfurn.resize(w * w)
		world.fill(MapgenDefs.Ter.NULL)
		wfurn.fill(MapgenDefs.Furn.NULL)
		mg.blit(base, world, wfurn, Vector2i.ZERO, turns, w)
		var side := _door_side(world, w, size)
		var names := ["북(첫 줄)", "동(오른 변)", "남(끝 줄)", "서(왼 변)", "??"]
		var want: String = names[turns]
		var got: String = names[side]
		var mark := "OK" if side == turns else "FAIL"
		print("  turns=%d  크기 %dx%d  문=%s  기대=%s  [%s]" % [turns, size.x, size.y, got, want, mark])
		if side != turns:
			ok = false

	print("")
	print("=== %s ===" % ("전부 통과" if ok else "실패 있음"))
	quit(0 if ok else 1)


func _dump(baked: Dictionary) -> void:
	var s: Vector2i = baked["size"]
	var ter: PackedByteArray = baked["ter"]
	var furn: PackedByteArray = baked["furn"]
	for y in s.y:
		var line := "  "
		for x in s.x:
			var i := y * s.x + x
			# 가구가 있으면 가구를 보여준다. 밑에 바닥이 깔려 있다는 건 별도로 검증한다.
			line += FURN_GLYPH.get(furn[i], GLYPH.get(ter[i], "?")) as String
		print(line)


## 문이 사각형의 어느 변에 있는지. 0=북 1=동 2=남 3=서, 4=못 찾음.
func _door_side(world: PackedByteArray, w: int, size: Vector2i) -> int:
	for x in size.x:
		if world[0 * w + x] == MapgenDefs.Ter.DOOR_C:
			return 0
	for y in size.y:
		if world[y * w + (size.x - 1)] == MapgenDefs.Ter.DOOR_C:
			return 1
	for x in size.x:
		if world[(size.y - 1) * w + x] == MapgenDefs.Ter.DOOR_C:
			return 2
	for y in size.y:
		if world[y * w + 0] == MapgenDefs.Ter.DOOR_C:
			return 3
	return 4
