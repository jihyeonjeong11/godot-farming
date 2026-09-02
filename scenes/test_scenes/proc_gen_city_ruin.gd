
  #1  그리드        (참조 거의 없음)
  #2  도로          cdda_overmap_city.cpp:384, 214, 306   ★
  #3  건물 자리      cdda_overmap_city.cpp:281, 235       ★
  #4  검증          mkmap.c:153, 258 / mklev.c:522
  #5  페인팅        house01.json / farm.tscn:738
  #6  프리팹        house01.json / house_nested.json
  #7  폐허화        cdda_post.cpp:440, 654, 623          ★ 새로 찾음
  #8  농사          farm_nested.json

  #┌─────┬──────────────────────────────────────────────────┬─────────────────┬───────────────────┐
  #│     │                       내용                       │      기대       │       비용        │
  #├─────┼──────────────────────────────────────────────────┼─────────────────┼───────────────────┤
  #│ A   │ 수집을 집합으로 (중복 제거)                      │ 1.23s → 0.6s    │ 작음, 겉모습 불변 │
  #├─────┼──────────────────────────────────────────────────┼─────────────────┼───────────────────┤
  #│ B   │ 경계 칸만 솔버, 안쪽은 set_cell로 변형 직접 찍기 │ 5.79s → 수십 ms │ 중간              │
  #├─────┼──────────────────────────────────────────────────┼─────────────────┼───────────────────┤
  #│ C   │ 흙을 타일맵에서 빼고 반복 텍스처로               │ 4.5s → 0        │ 반복 무늬가 보임  │
  #├─────┼──────────────────────────────────────────────────┼─────────────────┼───────────────────┤
  #│ D   │ OMT 단위 지연 생성                               │ 전체가 사라짐   │ 큼                │
  #└─────┴──────────────────────────────────────────────────┴─────────────────┴───────────────────┘

extends Node2D

const OMAP_SIZE := 40       # Possible Proc Gen tile size.
const CELL := 16            # One street size: 16 * 16
const TILE_PX := 32         # Actual Tile size.
const ROAD_W := 6           # Road size = 32 * 6
const WALK_W := 2           # Sidewalk size = 32 * 2
const PAINT_MARGIN := 2     # 32 * 2
const BUILDING_CHANCE := 4  # 1/4 25%
const TILES := OMAP_SIZE * CELL   # 640 — 타일 해상도 점유 맵의 한 변

## 동쪽 관문에 세울 문. 농장 문과 같은 씬을 그대로 쓴다.
const PORTAL_SCENE: PackedScene = preload("res://scenes/components/portal_component.tscn")
## 문 너머 — 농장 씬과 그쪽 스폰 지점 이름.
const FARM_SCENE := "uid://b0kcgeo77475t"
const FARM_SPAWN: StringName = &"outside"
## 농장 문이 이 씬을 부를 때 쓰는 이름. 동쪽 관문 안쪽에 세운다.
const GATE_SPAWN: StringName = &"farm_gate"
## 관문 앞을 비워둘 길이(타일). 문과 스폰 지점이 여기 들어간다.
const GATE_CLEAR := 8

const SRC := 0 # Tile id
const T_MANHOLE := [Vector2i(56, 26), Vector2i(57, 26),
					Vector2i(56, 27), Vector2i(57, 27)]                  # 2x2 맨홀
const TERRAIN_SET := 0
const TERRAIN_ASPHALT := 0 
const TERRAIN_CONCRETE := 1
const TERRAIN_DIRT := 2 

enum Cell { EMPTY, ROAD, BUILDING }
# 타일 해상도 점유. Dictionary는 40만 셀에서 메모리도 조회도 부담이라 바이트 배열을 쓴다.
enum Occ { FREE, ROAD, WALK, BLOCKED }
enum Dir { NORTH, EAST, SOUTH, WEST }
const DIR_VEC: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

# ──────────────────────────────────────────────────────────────
# 건물 — overmap_city.cpp:235 / :281
# ──────────────────────────────────────────────────────────────
enum Kind { HOUSE, SHOP, PARK }

## 필지 안에서 건물을 도로쪽 변에 붙일 때 남기는 앞마당 칸수.
const SETBACK := 2

## 존잉 파라미터. regional_settings.h:58 의 기본값 그대로다.
## town_dist 가 0~100 으로 정규화돼 있어서 도시 크기와 무관하게 같은 척도로 쓴다.
const SHOP_RADIUS := 30
const SHOP_SIGMA := 20
const PARK_RADIUS := 30
const PARK_SIGMA := 100 - PARK_RADIUS

## overmap_special 카탈로그 — 여기는 OMT 층이다. 실제 벽 배치는 여기 없다.
## CDDA 와 같은 2단 구조를 그대로 둔다:
##   1) 여기서 oter(=건물 종류)와 발자국을 정하고 OMT 를 예약한다  <- overmap_city.cpp
##   2) 그 OMT 에 들어갈 때 mapgen 이 oter 에 걸린 프리팹 중 하나를 뽑아 찍는다  <- mapgen.cpp
## 그래서 "집"은 하나지만 house_small / house_wide / house_deep 셋 중 하나로 나온다.
## 어느 쪽이 나올지는 data/mapgen/houses/*.json 의 weight 가 정하고, 이 표는 모른다.
##   oter — MAPGEN 의 키(=CDDA 의 om_terrain)와 맞아야 한다.
##   foot — OMT 단위 발자국. (가로=도로와 나란한 축, 세로=도로에서 멀어지는 축)
##   min_city — CDDA의 constraints.city_size. 큰 건물이 촌마을에 안 뜨게 한다.
##   unique — CITY_UNIQUE. 도시당 하나.
const CATALOG := [
	{"id": "house", "oter": "house", "kind": Kind.HOUSE, "foot": Vector2i(1, 1),
	 "weight": 20, "min_city": 1},
	{"id": "shop", "oter": "shop", "kind": Kind.SHOP, "foot": Vector2i(1, 1),
	 "weight": 10, "min_city": 1},
	{"id": "shop_1", "oter": "shop_1", "kind": Kind.SHOP, "foot": Vector2i(2, 2),
	 "weight": 6, "min_city": 3},
	{"id": "strip_mall", "oter": "strip_mall", "kind": Kind.SHOP, "foot": Vector2i(2, 1),
	 "weight": 4, "min_city": 6},
	{"id": "office", "oter": "office", "kind": Kind.SHOP, "foot": Vector2i(1, 2),
	 "weight": 3, "min_city": 5, "unique": true},
	{"id": "park", "oter": "park", "kind": Kind.PARK, "foot": Vector2i(1, 1),
	 "weight": 10, "min_city": 1},
]

# ──────────────────────────────────────────────────────────────
# mapgen 등록표 — mapgen.cpp 의 oter_mapgen
#
# CDDA 는 oter_id 에 mapgen 함수를 직접 박지 않는다. om_terrain 문자열마다 가중치 목록을
# 달아두고(oter_mapgen::add), 그 OMT 에 들어갈 때 거기서 한 장을 뽑는다. 그래서 "집"이라는
# 한 종류가 house01 / house02 / ... 로 갈린다. 이 표가 그 목록이고, 여기 없는 oter 는
# 아직 프리팹이 없는 것이라 building_2 로 때운다 (CDDA 라면 여기서 에러를 낸다).
#
# 프리팹 한 장 = OMT 한 칸 = CELL x CELL 타일. 앞마당까지 프리팹 안에 그려져 있고
# 정면은 남쪽 고정이다 — 3/4 시점 아트라 돌리면 지붕과 파사드가 같이 눕는다.
# ──────────────────────────────────────────────────────────────
const FALLBACK_SCENE: PackedScene = preload("res://scenes/buildings/building_2.tscn")

const MAPGEN := {
	"house": [{"scene": preload("res://scenes/prefabs/house.tscn"), "weight": 100}],
	"park": [{"scene": preload("res://scenes/prefabs/park.tscn"), "weight": 100}],
	"shop_1": [{"scene": preload("res://scenes/prefabs/shop.tscn"), "weight": 100}],
}

## 프리팹의 레이어 이름 -> 이 씬의 레이어 이름. 여기 없는 레이어는 무시한다.
## Props 는 프리팹 안의 잡동사니(덤불/쓰레기)라 가구와 같은 판에 얹는다.
const TEMPLATE_LAYERS := {
	"Ground": "land",
	"Path": "walk",
	"Floors": "floors",
	"Walls": "walls",
	"Furnitures": "furniture",
	"Props": "furniture",
	"Roofs": "roofs",
}

const TEMPLATE_TER := {
	"Floors": MapgenDefs.Ter.FLOOR,
	"Walls": MapgenDefs.Ter.WALL,
}

@export var world_seed: int = 0         
@export var city_size: int = 6

@onready var land: TileMapLayer = $Tilemap/Land  
@onready var walk: TileMapLayer = $Tilemap/Walk     
@onready var road: TileMapLayer = $Tilemap/Road     
@onready var floors: TileMapLayer = $Tilemap/Floors
@onready var walls: TileMapLayer = $Tilemap/Walls
@onready var furniture: TileMapLayer = $Tilemap/Furniture
@onready var roofs: TileMapLayer = $Tilemap/Roofs
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
var occ := PackedByteArray()             # TILES x TILES, 값은 Occ — "여기 뭘 놓을 수 있나"
## CDDA 의 map::ter / map::furn. "여기가 무엇인가" 쪽이고, occ 와 목적이 다르다.
## occ 는 배치용 임시 판정, 이쪽은 생성이 끝난 뒤에도 계속 살아있는 세계 상태다.
## #7 폐허화와 문/창문 상호작용이 읽을 것도 이쪽이다.
var ter := PackedByteArray()             # TILES x TILES, 값은 MapgenDefs.Ter
var furn := PackedByteArray()            # TILES x TILES, 값은 MapgenDefs.Furn
## 구워둔 프리팹 판. resource_path -> {cells, size, objects}. 좌상단 기준 오프셋으로 펴놨다.
## 건물마다 씬을 통째로 인스턴스하면 수백 채에서 노드가 폭발한다 — 타일은 베껴 찍고
## 노드라야 하는 것(나무)만 objects 로 따로 세운다.
var templates: Dictionary = {}
## 프리팹이 세운 노드들이 사는 곳. 재생성마다 통째로 비운다.
var objects_root: Node2D
var placed_buildings: Array[Dictionary] = []   # 배치 결과. 페인팅과 미니맵이 읽는다.
var park_omts: Dictionary = {}           # 공원으로 잡힌 OMT. 나무를 더 심는다.
var placed_unique: Dictionary = {}       # CITY_UNIQUE 중복 방지. CDDA는 도시마다 새로 만든다.
var gate: PortalComponent                # 동쪽 관문. 재생성 때마다 새 자리에 다시 세운다.
var gate_spawn: SpawnPoint               # 그 안쪽, 농장에서 넘어온 플레이어가 설 자리.


func _ready() -> void:
	# 프리팹은 시드와 무관하므로 한 번만 굽는다. 리롤은 뽑기만 다시 한다.
	objects_root = Node2D.new()
	objects_root.name = "PrefabObjects"
	objects_root.y_sort_enabled = true
	add_child(objects_root)
	bake_templates()
	_generate()
	place_player()
	# 디버그 UI(줌/리롤/미니맵)는 이 씬만 F6로 띄웠을 때만 붙인다.
	if is_standalone():
		_setup_debug_ui()


## 이 씬이 곧 실행 중인 씬이면 단독 실행(F6). game.tscn 밑이면 current_scene 은 Game 이다.
func is_standalone() -> bool:
	return get_tree().current_scene == self


func _generate() -> void:
	var t0 := Time.get_ticks_msec()
	active_seed = world_seed if world_seed != 0 else randi()
	rng.seed = active_seed
	grid.clear()
	manholes.clear()
	land.clear()
	walk.clear()
	road.clear()
	floors.clear()
	walls.clear()
	furniture.clear()
	roofs.clear()
	for child in objects_root.get_children():
		child.free()
	placed_buildings.clear()
	park_omts.clear()
	placed_unique.clear()
	occ_reset()
	ter_reset()

	build_city()
	var t1 := Time.get_ticks_msec()
	# grid 에 건물 칸도 들어가므로 도로만 따로 센다.
	var road_omts := 0
	for v: int in grid.values():
		if v == Cell.ROAD:
			road_omts += 1
	place_manholes()
	paint_all()
	# 관문 앞 통로는 건물보다 먼저 찜해둔다. 도시 밖 칸의 건물이 앞마당을 뻗어
	# 문을 벽으로 덮어버리면 농장으로 돌아갈 길이 없어진다.
	reserve_east_gate()
	var t2 := Time.get_ticks_msec()
	# 여기서부터가 CDDA 의 mapgen 이다. 예약된 OMT 마다 프리팹을 뽑아 ter/furn 에 굽고,
	# 그 다음에야 타일을 고른다. 두 단계를 붙여놓으면 #7 이 끼어들 자리가 없어진다.
	stamp_buildings()
	var t3 := Time.get_ticks_msec()
	render_buildings()
	place_east_gate()
	var t4 := Time.get_ticks_msec()
	print("[city] seed=%d  도로 %d칸 (%dms)  페인팅 흙%d+인도%d+도로%d셀 (%dms)  건물 %d채(공원 %d) 찍기 %dms 그리기 %dms"
		% [active_seed, road_omts, t1 - t0, dirt_cells.size(), walk_cells.size(), road_cells.size(),
		   t2 - t1, placed_buildings.size(), park_omts.size(), t3 - t2, t4 - t3])
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

	# CDDA는 connection.pick_subtype_for(ter_id) 로 이걸 거른다 — 건물이 깔린 OMT는
	# 도로 커넥션이 받아주는 지형이 아니라서 거기서 길이 끊긴다.
	# 이 한 줄이 있어야 "먼저 온 건물이 나중 도로를 막는" 그리디가 성립한다.
	if grid.get(pos, Cell.EMPTY) == Cell.BUILDING:
		return false

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

		if not one_in(BUILDING_CHANCE):
			place_building(rp, turn_left(dir))
		if not one_in(BUILDING_CHANCE):
			place_building(rp, turn_right(dir))

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
	land.set_cells_terrain_connect(dirt_cells, TERRAIN_SET, TERRAIN_DIRT, false)
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
		return Occ.BLOCKED    # 맵 밖은 막힌 것으로 친다
	return occ[cell.y * TILES + cell.x]


func occ_fill(r: Rect2i, kind: int) -> void:
	for y in range(r.position.y, r.end.y):
		var row := y * TILES
		for x in range(r.position.x, r.end.x):
			occ[row + x] = kind


# ──────────────────────────────────────────────────────────────
# 건물 자리 잡기 — overmap_city.cpp:235 / :281
# 건물은 별도 패스가 아니다. 도로를 깔면서 그 자리에서 같이 나온다.
# 그래서 백트래킹이 없다 — 먼저 온 놈이 자리를 먹고, 늦은 놈은 빈 땅으로 남는다.
# ──────────────────────────────────────────────────────────────

## 발자국이 덮는 OMT 목록. origin 이 도로에 붙은 칸이고,
## depth 축으로 도로에서 멀어지며, lateral 축은 turn_right(dir) 방향으로 뻗는다.
func building_cells(origin: Vector2i, foot: Vector2i, dir: int) -> Array[Vector2i]:
	var depth := DIR_VEC[dir]
	var lat := DIR_VEC[turn_right(dir)]
	var out: Array[Vector2i] = []
	for i in foot.y:
		for j in foot.x:
			out.append(origin + depth * i + lat * j)
	return out


## CDDA can_place_special 대응. 발자국 전체가 맵 안이고 비어 있어야 한다.
## 도로든 다른 건물이든 이미 뭔가 있으면 실패다.
func can_place_building(cells: Array[Vector2i]) -> bool:
	for p: Vector2i in cells:
		if not inbounds(p, 1):
			return false
		if grid.get(p, Cell.EMPTY) != Cell.EMPTY:
			return false
	return true


## overmap_city.cpp:235 — 도심에서의 거리로 용도를 정한다.
## 고정 반경이 아니라 건물마다 경계선을 정규분포로 새로 굴리는 게 핵심이다.
## max(radius, roll) 는 한쪽으로만 clamp 라서 실효 반경이 radius 위로 밀린다.
## park_sigma 가 70이라 공원은 도시 어디서든 나올 확률이 0이 아니다.
func pick_random_building(town_dist: int) -> Dictionary:
	var shop_normal := maxi(SHOP_RADIUS, int(rng.randfn(SHOP_RADIUS, SHOP_SIGMA)))
	var park_normal := maxi(PARK_RADIUS, int(rng.randfn(PARK_RADIUS, PARK_SIGMA)))

	var kind := Kind.HOUSE
	if shop_normal > town_dist:
		kind = Kind.SHOP
	elif park_normal > town_dist:
		kind = Kind.PARK

	# CDDA는 do-while 로 조건 맞을 때까지 다시 뽑는다. 데이터가 나쁘면 영원히 도는 구조라
	# 우린 후보를 먼저 걸러놓고 가중치 뽑기를 한 번만 한다. 결과 분포는 같다.
	var pool: Array = []
	var total := 0
	for b: Dictionary in CATALOG:
		if b["kind"] != kind:
			continue
		if city_size < b["min_city"]:
			continue
		if b.get("unique", false) and placed_unique.has(b["id"]):
			continue
		pool.append(b)
		total += b["weight"]
	if pool.is_empty():
		return {}

	var roll := rng.randi_range(0, total - 1)
	for b: Dictionary in pool:
		roll -= b["weight"]
		if roll < 0:
			return b
	return pool[pool.size() - 1]

func place_building(p: Vector2i, dir: int) -> void:
	var building_pos := p + DIR_VEC[dir]
	var building_dir := opposite(dir)
	var town_dist := int(Vector2(building_pos - city_pos).length() * 100.0 / maxi(city_size, 1))

	# 뽑기 → 발자국이 들어가나 검사 → 안 되면 다시 뽑기. 10번 다 실패하면 빈 땅으로 남는다.
	# CDDA 도시에 드문드문 있는 공터가 이거다.
	for _retry in 10:
		var spec := pick_random_building(town_dist)
		if spec.is_empty():
			return
		var cells := building_cells(building_pos, spec["foot"], dir)
		if not can_place_building(cells):
			continue

		for c: Vector2i in cells:
			grid[c] = Cell.BUILDING
		if spec.get("unique", false):
			placed_unique[spec["id"]] = true
		if spec["kind"] == Kind.PARK:
			for c: Vector2i in cells:
				park_omts[c] = true
		# 공원도 oter 를 가진 OMT 다 — CDDA 에서 park 는 제 mapgen 을 가진 지형이지
		# 건물이 아니어서 빠지는 예외가 아니다. 같은 줄에 세워 같은 길을 타게 한다.
		#
		# 크기를 여기서 못 정한다 — 어떤 프리팹이 나올지는 mapgen 이 정하고,
		# 그건 CDDA 에서 이 OMT 에 실제로 들어갈 때 일어나는 일이다.
		# 그래서 여기서는 필지만 남기고 stamp_buildings() 로 넘긴다.
		placed_buildings.append({
			"oter": spec["oter"],
			"cells": cells,
			"face": building_dir,
			"kind": spec["kind"],
		})
		return


## 발자국 OMT들이 만드는 필지 안에 실제 벽 사각형을 앉힌다.
## 도로를 바라보는 변에 SETBACK 만큼 앞마당을 남기고 붙이고, 나머지 축은 가운데 정렬.
func building_rect(cells: Array[Vector2i], size: Vector2i, face: int) -> Rect2i:
	var mn := cells[0]
	var mx := cells[0]
	for p: Vector2i in cells:
		mn = mn.min(p)
		mx = mx.max(p)
	var lot := Rect2i(mn * CELL, (mx - mn + Vector2i.ONE) * CELL)

	var pos := lot.position + (lot.size - size) / 2
	match face:
		Dir.NORTH:
			pos.y = lot.position.y + SETBACK
		Dir.SOUTH:
			pos.y = lot.end.y - SETBACK - size.y
		Dir.WEST:
			pos.x = lot.position.x + SETBACK
		Dir.EAST:
			pos.x = lot.end.x - SETBACK - size.x
	# 프리팹이 필지를 꽉 채우면 앞마당을 뺄 자리가 없다 — SETBACK 이 필지 밖으로 민다.
	# CDDA 의 mapgen 은 OMT 를 통째로 채우고 앞마당도 프리팹 안에 그리므로 그쪽이 정답이고,
	# 여기서는 잘라 필지 안에 붙인다. 작은 프리팹은 그대로 앞마당을 얻는다.
	pos.x = clampi(pos.x, lot.position.x, maxi(lot.position.x, lot.end.x - size.x))
	pos.y = clampi(pos.y, lot.position.y, maxi(lot.position.y, lot.end.y - size.y))
	return Rect2i(pos, size)


# ──────────────────────────────────────────────────────────────
# mapgen — CDDA 가 OMT 에 들어갈 때 하는 일
#
# 예약된 필지마다 프리팹을 하나 앉히고, 그 프리팹이 뭘 만드는지를 ter 격자에 굽는다.
# 여기서 타일은 하나도 안 찍는다. 찍는 건 render_buildings() 이고, 그 사이에
# #7 폐허화가 들어올 것이다 — 순서가 "굽기 -> (부수기) -> 그리기" 라야 한다.
# ──────────────────────────────────────────────────────────────
func ter_reset() -> void:
	ter.resize(TILES * TILES)
	furn.resize(TILES * TILES)
	ter.fill(MapgenDefs.Ter.NULL)
	furn.fill(MapgenDefs.Furn.NULL)


func ter_at(c: Vector2i) -> int:
	if c.x < 0 or c.y < 0 or c.x >= TILES or c.y >= TILES:
		return MapgenDefs.Ter.NULL
	return ter[c.y * TILES + c.x]


## 등록표에 실린 프리팹을 전부 한 번씩 구워둔다. 씬을 공유하는 항목은 한 번만 굽는다.
func bake_templates() -> void:
	templates.clear()
	bake_template(FALLBACK_SCENE)
	for oter: String in MAPGEN:
		for entry: Dictionary in MAPGEN[oter]:
			bake_template(entry["scene"])


## 프리팹 씬을 한 번만 읽어 좌상단 기준 오프셋 목록으로 펴둔다.
## 여기서 좌표계가 바뀐다 — 프리팹 안의 절대 좌표는 그린 사람 사정이고,
## 도시는 "필지 왼쪽 위에서 몇 칸"만 알면 된다.
func bake_template(scene: PackedScene) -> void:
	if templates.has(scene.resource_path):
		return

	var inst := scene.instantiate()
	var raw: Array[Dictionary] = []
	var nodes: Array[Dictionary] = []
	var mn := Vector2i(1 << 30, 1 << 30)
	var mx := Vector2i(-(1 << 30), -(1 << 30))
	# 자식 순서가 곧 그리는 순서다. Floors 가 먼저 오고 Walls 가 뒤에 와야
	# 겹치는 칸에서 ter 가 WALL 로 덮인다.
	for child in inst.get_children():
		var src := child as TileMapLayer
		if src != null:
			if not TEMPLATE_LAYERS.has(src.name):
				continue
			var dst: TileMapLayer = get(TEMPLATE_LAYERS[src.name])
			var t: int = TEMPLATE_TER.get(src.name, MapgenDefs.Ter.NULL)
			for c: Vector2i in src.get_used_cells():
				raw.append({
					"layer": dst,
					"at": c,
					"src": src.get_cell_source_id(c),
					"atlas": src.get_cell_atlas_coords(c),
					"ter": t,
				})
				mn = mn.min(c)
				mx = mx.max(c)
			continue
		# 타일로 못 그리는 것들 — 나무처럼 제 스크립트와 충돌체를 갖고 사는 것만 여기 온다.
		# 씬 파일을 들고 있다가 배치 때 세운다. 프리팹 노드 자체를 복제하면 원본이 딸려온다.
		if child.name == "Objects":
			for obj in child.get_children():
				var n := obj as Node2D
				if n == null or n.scene_file_path.is_empty():
					continue
				nodes.append({"path": n.scene_file_path, "at": n.position})
	inst.free()

	if raw.is_empty():
		push_warning("프리팹 %s 에 찍힌 타일이 없다" % scene.resource_path)
		return

	var origin_px := Vector2(mn * TILE_PX)
	for e: Dictionary in raw:
		e["at"] = e["at"] - mn
	for n: Dictionary in nodes:
		n["at"] = (n["at"] as Vector2) - origin_px

	templates[scene.resource_path] = {
		"cells": raw,
		"objects": nodes,
		"size": mx - mn + Vector2i.ONE,
	}


## oter 에 걸린 프리팹 중 하나를 가중치로 뽑는다 — mapgen.cpp 의 oter_mapgen::pick.
## 등록표에 없는 oter 는 아직 프리팹이 없는 것이라 fallback 이 나온다.
func pick_prefab(oter: String) -> Dictionary:
	var pool: Array = MAPGEN.get(oter, [])
	var chosen: PackedScene = FALLBACK_SCENE
	if not pool.is_empty():
		var total := 0
		for entry: Dictionary in pool:
			total += int(entry["weight"])
		var roll := rng.randi_range(0, maxi(total, 1) - 1)
		chosen = pool[pool.size() - 1]["scene"]
		for entry: Dictionary in pool:
			roll -= int(entry["weight"])
			if roll < 0:
				chosen = entry["scene"]
				break
	return templates.get(chosen.resource_path, {})


func stamp_buildings() -> void:
	for b: Dictionary in placed_buildings:
		# 프리팹 뽑기가 여기 있는 이유 — 자리 예약(#3)은 종류만 알고 크기를 모른다.
		# CDDA 도 OMT 에 실제로 들어갈 때 뽑는다.
		var tpl := pick_prefab(b["oter"])
		if tpl.is_empty():
			continue
		b["tpl"] = tpl
		# 프리팹은 3/4 시점으로 정면이 고정돼 그려져 있다. 돌리면 지붕과 파사드가
		# 같이 눕는다 — 그래서 face 는 회전이 아니라 앞마당을 어느 변에 둘지에만 쓴다.
		var r := building_rect(b["cells"], tpl["size"], b["face"])
		# 벽 안팎 전부 배치 금지로 막는다. 뒤에 오는 것들이 거실에 생기면 곤란하다.
		occ_fill(r, Occ.BLOCKED)
		b["rect"] = r

		for e: Dictionary in tpl["cells"]:
			var t: int = e["ter"]
			if t == MapgenDefs.Ter.NULL:
				continue
			var c: Vector2i = r.position + e["at"]
			if c.x < 0 or c.y < 0 or c.x >= TILES or c.y >= TILES:
				continue
			ter[c.y * TILES + c.x] = t


# ──────────────────────────────────────────────────────────────
# 렌더 패스 — 굽힌 자리에 프리팹 타일을 그대로 찍는다
# 여기가 유일하게 스프라이트를 아는 곳이다. 위쪽은 전부 의미만 다룬다.
# ──────────────────────────────────────────────────────────────
func render_buildings() -> void:
	for b: Dictionary in placed_buildings:
		if not b.has("rect"):
			continue
		var r: Rect2i = b["rect"]
		var tpl: Dictionary = b["tpl"]
		for e: Dictionary in tpl["cells"]:
			var layer: TileMapLayer = e["layer"]
			layer.set_cell(r.position + e["at"], e["src"], e["atlas"])

		var base := Vector2(r.position * TILE_PX)
		for n: Dictionary in tpl["objects"]:
			var scene: PackedScene = load(n["path"])
			if scene == null:
				continue
			var node := scene.instantiate() as Node2D
			node.position = base + (n["at"] as Vector2)
			objects_root.add_child(node)


# 농장 문이 농장 서쪽 끝에 있으니, 거기서 서쪽으로 걸어 나온 플레이어는 이 도시의
# 동쪽 끝으로 들어온다. 그래서 돌아가는 문도 동쪽 관문에 세운다.
func east_gate_omt() -> Vector2i:
	var omt := city_pos
	while is_road(omt + DIR_VEC[Dir.EAST]):
		omt += DIR_VEC[Dir.EAST]
	return omt

func east_gate_rect() -> Rect2i:
	var base := east_gate_omt() * CELL
	return Rect2i(base.x + CELL - GATE_CLEAR, base.y + (CELL - ROAD_W) / 2, GATE_CLEAR, ROAD_W)

func reserve_east_gate() -> void:
	occ_fill(east_gate_rect(), Occ.BLOCKED)


func place_east_gate() -> void:
	if is_instance_valid(gate):
		gate.queue_free()
	if is_instance_valid(gate_spawn):
		gate_spawn.queue_free()

	var r := east_gate_rect()
	var mid := r.position.y + ROAD_W / 2

	var portal := PORTAL_SCENE.instantiate() as PortalComponent
	portal.name = "PortalToFarm"
	portal.target_scene = FARM_SCENE
	portal.target_spawn = FARM_SPAWN
	portal.position = road.map_to_local(Vector2i(r.position.x + GATE_CLEAR - 2, mid))
	# 문짝 스프라이트는 16px 짜리라 32px 타일 위에선 점처럼 보인다.
	(portal.get_node("Sprite2D") as Sprite2D).scale = Vector2(3, 3)
	# 판정은 도로 폭을 통째로 막는 세로 띠로 키운다. 씬에 박힌 16x8 사각형은 여기선
	# 너무 작아 지나칠 수 있다. 그 리소스는 농장 문과 공유되니 건드리지 않고 새로 만든다.
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE_PX * 2, TILE_PX * ROAD_W)
	(portal.get_node("CollisionShape2D") as CollisionShape2D).shape = shape
	add_child(portal)
	gate = portal

	# 농장에서 넘어온 플레이어가 설 자리. 문 위에 세우면 닿자마자 되돌아가므로
	# 몇 칸 안쪽에 둔다.
	var point := SpawnPoint.new()
	point.name = "SpawnFromFarm"
	point.spawn_id = GATE_SPAWN
	point.position = road.map_to_local(Vector2i(r.position.x + 1, mid))
	add_child(point)
	gate_spawn = point


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
	for pos: Vector2i in grid:
		var col: Color
		if grid[pos] == Cell.BUILDING:
			# 초록 = 공원, 황토 = 건물. 도심에 황토가 몰리고 외곽으로 갈수록 흩어지면 존잉이 도는 것이다.
			col = Color(0.35, 0.6, 0.3) if park_omts.has(pos) else Color(0.75, 0.6, 0.35)
		elif manholes.has(pos):
			col = Color(0.9, 0.9, 0.9)
		else:
			col = Color(0.45, 0.45, 0.5)
		c.draw_rect(Rect2(Vector2(pos) * s, Vector2(s, s)), col)
	c.draw_rect(Rect2(Vector2(city_pos) * s, Vector2(s, s)), Color(1, 0.3, 0.2))
	var po := player.position / float(CELL * TILE_PX) * s
	c.draw_circle(po, 2.0, Color(1, 0.9, 0.2))


func _process(_delta: float) -> void:
	if _minimap != null:
		_minimap.queue_redraw()
	if _hud != null:
		_hud.text = "필지 %d  공원 %d  |  씬 노드 %d  fps %d" % [
			placed_buildings.size(), park_omts.size(),
			get_tree().get_node_count(), Engine.get_frames_per_second()]
