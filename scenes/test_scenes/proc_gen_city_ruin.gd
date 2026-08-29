
  #1  그리드        (참조 거의 없음)
  #2  도로          cdda_overmap_city.cpp:384, 214, 306   ★
  #3  건물 자리      cdda_overmap_city.cpp:281, 235       ★
  #4  검증          mkmap.c:153, 258 / mklev.c:522
  #5  페인팅        house01.json / farm.tscn:738
  #6  프리팹        house01.json / house_nested.json
  #7  폐허화        cdda_post.cpp:440, 654, 623          ★ 새로 찾음
  #8  농사          farm_nested.json

extends Node2D

const OMAP_SIZE := 40       # Possible Proc Gen tile size.
const CELL := 16            # One street size: 16 * 16
const TILE_PX := 32         # Actual Tile size.
const ROAD_W := 6           # Road size = 32 * 6
const WALK_W := 2           # Sidewalk size = 32 * 2
const PAINT_MARGIN := 2     # 32 * 2
const BUILDING_CHANCE := 4  # 1/4 25%
const TILES := OMAP_SIZE * CELL   # 640 — 타일 해상도 점유 맵의 한 변

const AXE: Items = preload("res://scripts/resources/tools/axe.tres")
## 기존 나무 씬을 그대로 심는다. 도끼 판정(HurtComponent) / 내구도(DamageComponent) /
## 흔들림 셰이더 / 통나무 드롭이 전부 이 씬 안에 이미 들어있다.
const TREE_SCENE: PackedScene = preload("res://scenes/objects/trees/SmallTree.tscn")
## 나무 한 그루가 차지하는 칸수. 스프라이트가 21x30px 라 32px 한 칸이면 충분하다.
const TREE_FOOT := Vector2i(1, 1)
## 좀비도 기존 씬을 그대로 심는다. 나무와 달리 매 프레임 도는 스테이트머신과
## NavigationAgent2D 를 들고 있어서, 마릿수가 곧 프레임 비용이다.
const ZOMBIE_SCENE: PackedScene = preload("res://scenes/characters/enemy/zombie/zombie.tscn")

const SRC := 0 # Tile id
const T_MANHOLE := [Vector2i(56, 26), Vector2i(57, 26),
					Vector2i(56, 27), Vector2i(57, 27)]                  # 2x2 맨홀
const TERRAIN_SET := 0
const TERRAIN_ASPHALT := 0 
const TERRAIN_CONCRETE := 1
const TERRAIN_DIRT := 2 

enum Cell { EMPTY, ROAD }
# 타일 해상도 점유. Dictionary는 40만 셀에서 메모리도 조회도 부담이라 바이트 배열을 쓴다.
enum Occ { FREE, ROAD, WALK, PROP }
enum Dir { NORTH, EAST, SOUTH, WEST }
const DIR_VEC: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

@export var world_seed: int = 0         
@export var city_size: int = 8
## OMT 한 칸당 나무 심기 시도 횟수. 노드 수가 여기 그대로 비례한다.
@export var trees_per_omt: int = 6
## OMT 칸당 1/N 확률로 좀비 한 마리. 낮출수록 많아진다.
@export var zombie_chance: int = 4

@onready var ground: TileMapLayer = $Ground  
@onready var walk: TileMapLayer = $Walk     
@onready var road: TileMapLayer = $Road     
@onready var props: TileMapLayer = $Props   
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D

var rng := RandomNumberGenerator.new()
var grid: Dictionary = {}       # Cell Grid
var manholes: Dictionary = {}
var city_pos: Vector2i
var active_seed: int
var road_cells: Array[Vector2i] = [] 
var walk_cells: Array[Vector2i] = []
var dirt_cells: Array[Vector2i] = []
var occ := PackedByteArray()             # TILES x TILES, 값은 Occ
var prop_nodes: Dictionary = {}          # 앵커 셀 -> 나무 노드. 개수 세기와 점유 해제에 쓴다.
var zombie_nodes: Dictionary = {}        # 스폰 셀 -> 좀비 노드


func _ready() -> void:
	_generate()
	place_player()
	_setup_debug_ui()
	give_axe()


func _generate() -> void:
	var t0 := Time.get_ticks_msec()
	active_seed = world_seed if world_seed != 0 else randi()
	rng.seed = active_seed
	grid.clear()
	manholes.clear()
	ground.clear()
	walk.clear()
	road.clear()
	props.clear()
	occ_reset()

	build_city()
	var t1 := Time.get_ticks_msec()
	place_manholes()
	paint_all()
	var t2 := Time.get_ticks_msec()
	scatter_props()
	scatter_zombies()
	var t3 := Time.get_ticks_msec()
	print("[city] seed=%d  도로 %d칸 (%dms)  페인팅 흙%d+인도%d+도로%d셀 (%dms)  나무 %d그루 좀비 %d마리 / 씬 노드 %d개 (%dms)"
		% [active_seed, grid.size(), t1 - t0, dirt_cells.size(), walk_cells.size(), road_cells.size(), t2 - t1,
		   prop_nodes.size(), zombie_nodes.size(), get_tree().get_node_count(), t3 - t2])
	queue_redraw()

# TODO: 방향은 dir 이넘 타입으로 바꿀 것
func turn_right(d: int) -> int:
	return (d + 1) % 4


func turn_left(d: int) -> int:
	return (d + 3) % 4


func opposite(d: int) -> int:
	return (d + 2) % 4


func turn_random(d: int) -> int:
	return turn_left(d) if rng.randi() % 2 == 0 else turn_right(d)


func one_in(n: int) -> bool:
	return rng.randi() % n == 0


func is_road(p: Vector2i) -> bool:
	return grid.get(p, Cell.EMPTY) == Cell.ROAD


func inbounds(p: Vector2i, margin: int = 0) -> bool:
	return p.x >= margin and p.y >= margin and p.x < OMAP_SIZE - margin and p.y < OMAP_SIZE - margin

func build_city() -> void:
	city_pos = Vector2i(OMAP_SIZE / 2, OMAP_SIZE / 2)
	grid[city_pos] = Cell.ROAD  # every city starts with an intersection

	var start_dir := rng.randi_range(0, 3)
	var cur_dir := start_dir
	while true:
		build_city_street(city_pos, city_size, cur_dir)
		cur_dir = turn_right(cur_dir)
		if cur_dir == start_dir:
			break


# ──────────────────────────────────────────────────────────────
# lay_out_street()  — overmap_city.cpp:306
# 도로 한 줄기를 어디까지 깔 수 있는지 판정해 경로를 반환.
# 강/고속도로 분기는 이식 대상이 아니다 (우린 그런 지형이 없다).
# 핵심은 collisions >= 2 규칙 — 도로가 나란히 붙는 걸 막고, 이게 블록 모양을 결정한다.
# ──────────────────────────────────────────────────────────────
func valid_placement(pos: Vector2i, dir: int) -> bool:
	if not inbounds(pos, 1):
		return false  # Don't approach overmap bounds.

	# 진행 방향 앞/뒤 한 칸은 검사에서 제외한다. 그건 이 도로 자신이니까.
	var fwd := pos + DIR_VEC[dir]
	var back := pos + DIR_VEC[opposite(dir)]
	var collisions := 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var checkp := pos + Vector2i(dx, dy)
			if checkp == pos or checkp == fwd or checkp == back:
				continue
			if is_road(checkp):
				# Stop roads from running right next to each other
				if collisions >= 2:
					return false
				collisions += 1
	return true


func lay_out_street(source: Vector2i, dir: int, length: int) -> Array[Vector2i]:
	# See if we need to take another one-tile "step" further.
	# 한 칸 더 가면 기존 도로에 닿는 경우 — 끊기지 않게 붙여준다.
	var en_pos := source + DIR_VEC[dir] * (length + 1)
	if inbounds(en_pos, 1) and is_road(en_pos):
		length += 1

	var actual_len := 0
	while actual_len < length:
		var pos := source + DIR_VEC[dir] * actual_len
		if not valid_placement(pos, dir):
			break
		actual_len += 1
		if actual_len > 1 and is_road(pos):
			break  # Stop here. 이미 있는 도로에 닿았다.

	var path: Array[Vector2i] = []
	for i in actual_len:
		path.append(source + DIR_VEC[dir] * i)
	return path


func build_city_street(p: Vector2i, cs: int, dir: int, block_width: int = 2) -> void:
	var c := cs
	var croad := cs

	var street_path := lay_out_street(p, dir, cs + 1)
	if street_path.size() <= 1:
		return  # Don't bother.

	# Build the actual street.
	# (CDDA의 build_connection에 해당. 우린 마킹만 하고 실제 도로 모양은
	#  나중에 connection_mask()로 그린다 — 도로 프리팹 16종이 필요 없어진다)
	for node in street_path:
		grid[node] = Cell.ROAD

	var new_width := 4 if block_width == 2 else 2

	# 첫 노드(= 출발점)는 건너뛴다. 거긴 부모 도로가 이미 처리했다.
	for i in range(1, street_path.size()):
		var rp: Vector2i = street_path[i]
		c -= 1

		if c >= 2 and c < croad - block_width:
			croad = c
			var left := cs - rng.randi_range(1, 3)   # 가지는 항상 본줄기보다 짧게
			var right := cs - rng.randi_range(1, 3)

			# Remove 1 length road nubs — 1칸짜리 도로 토막 제거
			if left == 1:
				left += 1
			if right == 1:
				right += 1

			build_city_street(rp, left, turn_left(dir), new_width)
			build_city_street(rp, right, turn_right(dir), new_width)

	# If we're big, make a right turn at the edge of town.
	# Seems to make little neighborhoods.
	cs -= rng.randi_range(1, 3)
	if cs >= 2 and c == 0:
		var last_node: Vector2i = street_path[street_path.size() - 1]
		var rnd_dir := turn_random(dir)
		build_city_street(last_node, cs, rnd_dir)
		if one_in(5):
			build_city_street(last_node, cs, opposite(rnd_dir), new_width)


# 사거리(4방 전부 도로)에만 맨홀. CDDA는 :434에서 line == 15를 보는데,
# 우린 도로망이 전부 깔린 뒤에 한 번에 판정하는 쪽이 정확하다.
func place_manholes() -> void:
	for pos in grid:
		if connection_mask(pos) == 15 and one_in(2):
			manholes[pos] = true


# ──────────────────────────────────────────────────────────────
# 페인팅 — OMT 1칸을 CELL x CELL 타일로 펼친다
# ──────────────────────────────────────────────────────────────
# 4방향 이웃 연결 비트마스크. N=1 E=2 S=4 W=8.
# CDDA는 road_ns / road_nesw / ... 16종 프리팹을 미리 만들어 두지만,
# 우린 "중앙 코어 + 연결된 방향으로 팔 뻗기"로 16종을 전부 커버한다.
func connection_mask(omt: Vector2i) -> int:
	var m := 0
	for d in 4:
		if is_road(omt + DIR_VEC[d]):
			m |= 1 << d
	return m


# 타일을 직접 찍지 않고 좌표만 모은다. 어떤 타일을 쓸지는 터레인 솔버가 정한다.
func collect_rect(base: Vector2i, x0: int, y0: int, x1: int, y1: int, out: Array[Vector2i]) -> void:
	for y in range(y0, y1):
		for x in range(x0, x1):
			out.append(base + Vector2i(x, y))


# 연결된 방향으로 셀 경계까지 밴드를 뻗는다. lo/hi는 밴드의 양 끝 좌표.
func collect_arm(base: Vector2i, dir: int, lo: int, hi: int, out: Array[Vector2i]) -> void:
	match dir:
		Dir.NORTH:
			collect_rect(base, lo, 0, hi, hi, out)
		Dir.EAST:
			collect_rect(base, lo, lo, CELL, hi, out)
		Dir.SOUTH:
			collect_rect(base, lo, lo, hi, CELL, out)
		Dir.WEST:
			collect_rect(base, 0, lo, hi, hi, out)


func paint_cell(omt: Vector2i) -> void:
	var base := omt * CELL

	# 1) 배경 — 전면 흙. 도로가 아닌 칸은 여기서 끝난다.
	collect_rect(base, 0, 0, CELL, CELL, dirt_cells)

	if not is_road(omt):
		return

	var mask := connection_mask(omt)
	var r0 := (CELL - ROAD_W) / 2   # 도로 밴드 시작 = 5
	var r1 := r0 + ROAD_W           # 도로 밴드 끝   = 11
	var w0 := r0 - WALK_W           # 인도 포함 시작 = 3
	var w1 := r1 + WALK_W           # 인도 포함 끝   = 13

	# 2) 인도 — 넓은 박스 + 연결된 방향 팔.
	#    도로 밑까지 통째로 채운다. 가운데를 비우면 오목한 모서리가 생기는데
	#    9-slice엔 그 타일이 없다. 어차피 도로 레이어가 위에서 가린다.
	collect_rect(base, w0, w0, w1, w1, walk_cells)
	for d in 4:
		if (mask & (1 << d)) != 0:
			collect_arm(base, d, w0, w1, walk_cells)

	# 3) 도로 — 좁은 박스 + 팔. 위 레이어라 양옆에 인도가 드러난다.
	collect_rect(base, r0, r0, r1, r1, road_cells)
	for d in 4:
		if (mask & (1 << d)) != 0:
			collect_arm(base, d, r0, r1, road_cells)


# 도시 bbox + 여유분만 칠한다. OMT 그리드 전체(40x40 = 40만 타일)를 칠할 이유가 없다.
func city_bounds() -> Rect2i:
	if grid.is_empty():
		return Rect2i(city_pos, Vector2i.ONE)
	var mn := Vector2i(OMAP_SIZE, OMAP_SIZE)
	var mx := Vector2i.ZERO
	for pos in grid:
		mn = mn.min(pos)
		mx = mx.max(pos)
	return Rect2i(mn, mx - mn + Vector2i.ONE).grow(PAINT_MARGIN)


func paint_all() -> void:
	road_cells.clear()
	walk_cells.clear()
	dirt_cells.clear()

	var b := city_bounds()
	for oy in range(b.position.y, b.end.y):
		for ox in range(b.position.x, b.end.x):
			paint_cell(Vector2i(ox, oy))

	# 모아둔 좌표를 터레인 솔버에 한 번에 넘긴다.
	# 셀마다 이웃 제약을 풀기 때문에 set_cell()보다 훨씬 비싸다 — 반드시 일괄 호출.
	ground.set_cells_terrain_connect(dirt_cells, TERRAIN_SET, TERRAIN_DIRT, false)
	walk.set_cells_terrain_connect(walk_cells, TERRAIN_SET, TERRAIN_CONCRETE, false)
	road.set_cells_terrain_connect(road_cells, TERRAIN_SET, TERRAIN_ASPHALT, false)

	# 페인팅 결과를 그대로 점유 맵에 굽는다. 따로 순회할 이유가 없다.
	occ_mark(walk_cells, Occ.WALK)
	occ_mark(road_cells, Occ.ROAD)

	# 맨홀은 터레인이 아니라 낱개 타일. 도로 위에 덮어쓴다.
	for omt: Vector2i in manholes:
		var base := omt * CELL
		var h := CELL / 2
		road.set_cell(base + Vector2i(h - 1, h - 1), SRC, T_MANHOLE[0])
		road.set_cell(base + Vector2i(h, h - 1), SRC, T_MANHOLE[1])
		road.set_cell(base + Vector2i(h - 1, h), SRC, T_MANHOLE[2])
		road.set_cell(base + Vector2i(h, h), SRC, T_MANHOLE[3])


# ──────────────────────────────────────────────────────────────
# 점유 맵 — 타일 해상도. 640x640 = 40만 칸이라 Dictionary는 못 쓴다.
# ──────────────────────────────────────────────────────────────
func occ_reset() -> void:
	occ.resize(TILES * TILES)
	occ.fill(Occ.FREE)


func occ_mark(cells: Array[Vector2i], kind: int) -> void:
	for t in cells:
		if t.x >= 0 and t.y >= 0 and t.x < TILES and t.y < TILES:
			occ[t.y * TILES + t.x] = kind


func occ_free(r: Rect2i) -> bool:
	if r.position.x < 0 or r.position.y < 0 or r.end.x > TILES or r.end.y > TILES:
		return false
	for y in range(r.position.y, r.end.y):
		var row := y * TILES
		for x in range(r.position.x, r.end.x):
			if occ[row + x] != Occ.FREE:
				return false
	return true


func occ_at(cell: Vector2i) -> int:
	if cell.x < 0 or cell.y < 0 or cell.x >= TILES or cell.y >= TILES:
		return Occ.PROP    # 맵 밖은 막힌 것으로 친다
	return occ[cell.y * TILES + cell.x]


func occ_fill(r: Rect2i, kind: int) -> void:
	for y in range(r.position.y, r.end.y):
		var row := y * TILES
		for x in range(r.position.x, r.end.x):
			occ[row + x] = kind


# ──────────────────────────────────────────────────────────────
# 나무 심기
# ──────────────────────────────────────────────────────────────
# 도로가 아닌 OMT 칸마다 몇 번씩 자리를 시도한다. 이미 찬 자리면 실패하고 넘어간다.
# SmallTree.tscn 은 그루당 노드 9개다 — Sprite2D + StaticBody2D + 콜리전 +
# HurtComponent(+이펙트 스프라이트 +오디오 +콜리전) + DamageComponent + 먼지 스프라이트.
# trees_per_omt 를 올리면 그 9배로 노드가 늘어난다.
func scatter_props() -> void:
	var b := city_bounds()
	for oy in range(b.position.y, b.end.y):
		for ox in range(b.position.x, b.end.x):
			var omt := Vector2i(ox, oy)
			if is_road(omt):
				continue
			for _i in trees_per_omt:
				place_tree(omt)


# 앵커 셀 기준으로 발밑 사각형을 잡는다. 가로는 중앙 정렬, 세로는 앵커가 맨 아랫줄이다.
func foot_rect(anchor: Vector2i, foot: Vector2i) -> Rect2i:
	return Rect2i(anchor.x - foot.x / 2, anchor.y - foot.y + 1, foot.x, foot.y)


func place_tree(omt: Vector2i) -> bool:
	var anchor := omt * CELL + Vector2i(rng.randi_range(0, CELL - 1), rng.randi_range(0, CELL - 1))
	var r := foot_rect(anchor, TREE_FOOT)
	if not occ_free(r):
		return false
	occ_fill(r, Occ.PROP)

	var node: Node2D = TREE_SCENE.instantiate()
	# props 레이어는 타일을 안 찍지만 좌표 변환에는 계속 쓴다.
	node.position = props.map_to_local(anchor)
	# 루트 바로 밑에 붙인다. 루트가 y_sort_enabled 라 플레이어와 같은 정렬에 들어간다.
	add_child(node)
	# 나무는 다 패면 스스로 queue_free 한다. 그때 자리를 되돌려받아야 한다.
	return true






# ──────────────────────────────────────────────────────────────
# 좀비 배치 — 나무와 같은 방식이다. 기존 씬을 그대로 심는다.
# 다만 좀비는 스테이트머신이 매 프레임 돌고 NavigationAgent2D 가 경로를 잡는다.
# 나무는 가만히 있어서 마릿수가 늘어도 싸지만, 좀비는 마릿수가 곧 프레임 비용이다.
# ──────────────────────────────────────────────────────────────
func scatter_zombies() -> void:
	var b := city_bounds()
	for oy in range(b.position.y, b.end.y):
		for ox in range(b.position.x, b.end.x):
			if one_in(zombie_chance):
				place_zombie(Vector2i(ox, oy))


func place_zombie(omt: Vector2i) -> bool:
	var cell := omt * CELL + Vector2i(rng.randi_range(0, CELL - 1), rng.randi_range(0, CELL - 1))
	# 좀비는 돌아다니므로 자리를 잡아두지 않는다. 나무 안에서 시작만 안 하면 된다.
	if occ_at(cell) == Occ.PROP:
		return false

	var node: Node2D = ZOMBIE_SCENE.instantiate()
	node.position = props.map_to_local(cell)
	add_child(node)
	# 죽으면 스스로 queue_free 한다. 그때 목록에서 빼야 카운트가 맞는다.
	node.tree_exited.connect(_on_zombie_removed.bind(cell, node))
	zombie_nodes[cell] = node
	return true


func clear_zombies() -> void:
	for node: Node in zombie_nodes.values():
		if is_instance_valid(node):
			node.queue_free()
	zombie_nodes.clear()


func _on_zombie_removed(cell: Vector2i, node: Node) -> void:
	# 나무 쪽과 같은 이유 — 재생성 때 지운 옛 좀비의 콜백이 늦게 도착한다.
	if zombie_nodes.get(cell) != node:
		return
	zombie_nodes.erase(cell)


# ──────────────────────────────────────────────────────────────
# 도끼 지급 — 벌목 자체는 나무 씬이 알아서 한다.
# 플레이어 HitComponent(tool=AxeWood) 가 나무의 HurtComponent 에 닿으면
# DamageComponent 가 데미지를 쌓고, max_damage 에 도달하면 통나무를 떨구고 사라진다.
# ──────────────────────────────────────────────────────────────
func give_axe() -> void:
	Inventory.add_item(AXE)
	Inventory.select_slot(0)


# ──────────────────────────────────────────────────────────────
# 플레이어 배치 + 디버그 UI
# ──────────────────────────────────────────────────────────────
# 도시 중앙 사거리 한복판. OMT 좌표 -> 픽셀 좌표.
func city_center_px() -> Vector2:
	return Vector2(city_pos * CELL * TILE_PX) + Vector2.ONE * (CELL * TILE_PX * 0.5)


func place_player() -> void:
	player.position = city_center_px()
	camera.position = Vector2.ZERO
	camera.make_current()


# 도시 전체가 화면에 들어오는 줌 배율. 카메라가 플레이어 자식이라 중심은 플레이어.
func zoom_fit() -> void:
	var b := city_bounds()
	var px := Vector2(b.size * CELL * TILE_PX)
	var vp := get_viewport_rect().size
	camera.zoom = Vector2.ONE * minf(vp.x / px.x, vp.y / px.y)


func _setup_debug_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "DebugUI"
	layer.layer = 128
	add_child(layer)

	var box := HBoxContainer.new()
	box.position = Vector2(8, 8)
	box.add_theme_constant_override("separation", 4)
	layer.add_child(box)

	var fit := Button.new()
	fit.text = "fit"
	fit.focus_mode = Control.FOCUS_NONE
	fit.pressed.connect(zoom_fit)
	box.add_child(fit)

	for z in [0.25, 1.0]:
		var b := Button.new()
		b.text = "%d%%" % int(z * 100)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func() -> void: camera.zoom = Vector2.ONE * z)
		box.add_child(b)

	var reroll := Button.new()
	reroll.text = "reroll"
	reroll.focus_mode = Control.FOCUS_NONE
	reroll.pressed.connect(func() -> void:
		world_seed = 0  # 매번 새 시드
		_generate()
		place_player())
	box.add_child(reroll)

	_hud = Label.new()
	_hud.position = Vector2(8, 220)
	_hud.add_theme_color_override("font_color", Color(1, 0.95, 0.6))
	layer.add_child(_hud)

	var mini := Control.new()
	mini.name = "Minimap"
	mini.position = Vector2(8, 40)
	mini.custom_minimum_size = Vector2(OMAP_SIZE, OMAP_SIZE) * MINIMAP_SCALE
	mini.draw.connect(_draw_minimap.bind(mini))
	layer.add_child(mini)
	_minimap = mini


const MINIMAP_SCALE := 4.0
var _minimap: Control
var _hud: Label


# OMT 1칸 = 4px. 도로 재귀 결과를 타일과 무관하게 눈으로 검증하는 용도.
# 회색 = 도로, 흰색 = 맨홀, 빨강 = 도시 중심, 노랑 = 플레이어.
func _draw_minimap(c: Control) -> void:
	var s := MINIMAP_SCALE
	c.draw_rect(Rect2(Vector2.ZERO, Vector2(OMAP_SIZE, OMAP_SIZE) * s), Color(0, 0, 0, 0.5))
	for pos in grid:
		var col := Color(0.9, 0.9, 0.9) if manholes.has(pos) else Color(0.45, 0.45, 0.5)
		c.draw_rect(Rect2(Vector2(pos) * s, Vector2(s, s)), col)
	c.draw_rect(Rect2(Vector2(city_pos) * s, Vector2(s, s)), Color(1, 0.3, 0.2))
	var po := player.position / float(CELL * TILE_PX) * s
	c.draw_circle(po, 2.0, Color(1, 0.9, 0.2))


func _process(_delta: float) -> void:
	if _minimap != null:
		_minimap.queue_redraw()
	if _hud != null:
		# 나무를 씬으로 심은 대가가 노드 수와 fps 에 그대로 보인다.
		_hud.text = "나무 %d  벌목 %d  |  씬 노드 %d  fps %d" % [
			Engine.get_frames_per_second()]
