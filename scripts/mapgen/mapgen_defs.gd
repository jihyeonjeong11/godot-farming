## CDDA 의 ter_t / furn_t 대응.
##
## 여기 들어있는 건 "이 칸이 무엇인가"지 "어떤 스프라이트인가"가 아니다.
## CDDA 가 지형을 이렇게 두 겹(의미 / 그림)으로 갈라놓는 이유는 그림 때문이 아니라
## 그 뒤에 오는 모든 단계가 의미를 물어보기 때문이다 —
##   * 이동/시야    : 이 칸 통과되나, 너머가 보이나
##   * #7 폐허화    : t_wall -> t_wall_broken -> t_rubble. 스프라이트 교체가 아니라 상태 전이다.
##   * 지붕 붕괴    : SUPPORTS_ROOF 를 잃은 칸 위의 지붕이 무너진다
##   * 아이템/좀비  : 실내인가(INDOORS), 가구 위인가
##
## 그래서 mapgen 은 타일맵에 직접 그리지 않는다. 이 값을 격자에 찍고,
## 렌더 패스가 그 격자를 읽어 타일을 고른다. 순서를 거꾸로 하면 #7 이 붙을 자리가 없다.
class_name MapgenDefs
extends RefCounted

# ──────────────────────────────────────────────────────────────
# 지형 (ter)
# ──────────────────────────────────────────────────────────────
enum Ter {
	NULL,          ## 건물 밖. 도로/흙은 아직 이 격자에 안 들어온다.
	FLOOR,         ## t_floor — 실내 바닥
	WALL,          ## t_wall
	WINDOW,        ## t_window — 못 지나가지만 너머가 보인다
	DOOR_C,        ## t_door_c — 닫힌 문
	DOOR_O,        ## t_door_o — 열린 문
	WALL_BROKEN,   ## t_wall_broken — #7 이 t_wall 을 여기로 내린다
	RUBBLE,        ## t_rubble — #7 의 종착점. 지나갈 수 있고 지붕을 못 받친다.
}

# 플래그 비트. CDDA 의 ter_t::flags 를 필요한 것만 추린 것이다.
const F_PASSABLE := 1 << 0       ## 걸어서 통과된다
const F_TRANSPARENT := 1 << 1    ## 시야가 통과된다
const F_SUPPORTS_ROOF := 1 << 2  ## 위층/지붕을 받친다. #7 의 붕괴 판정이 이걸 센다.
const F_INDOORS := 1 << 3        ## 실내로 친다 (비/조명/스폰 판정용)

## Ter 순서와 1:1로 맞춘다. 인덱스 조회라 40만 칸을 돌아도 부담이 없다.
const TER_FLAGS: Array[int] = [
	F_PASSABLE | F_TRANSPARENT,                                # NULL
	F_PASSABLE | F_TRANSPARENT | F_INDOORS,                    # FLOOR
	F_SUPPORTS_ROOF,                                           # WALL
	F_SUPPORTS_ROOF | F_TRANSPARENT,                           # WINDOW
	F_SUPPORTS_ROOF | F_INDOORS,                               # DOOR_C
	F_SUPPORTS_ROOF | F_PASSABLE | F_TRANSPARENT | F_INDOORS,  # DOOR_O
	F_TRANSPARENT,                                             # WALL_BROKEN — 뚫렸지만 아직 못 지나간다
	F_PASSABLE | F_TRANSPARENT,                                # RUBBLE
]

## 문자열 id -> Ter. mapgen JSON 이 CDDA 와 같은 이름을 쓰게 하려는 것이다.
const TER_BY_ID := {
	"t_null": Ter.NULL,
	"t_floor": Ter.FLOOR,
	"t_wall": Ter.WALL,
	"t_window": Ter.WINDOW,
	"t_door_c": Ter.DOOR_C,
	"t_door_o": Ter.DOOR_O,
	"t_wall_broken": Ter.WALL_BROKEN,
	"t_rubble": Ter.RUBBLE,
}

# ──────────────────────────────────────────────────────────────
# 가구 (furn)
# ──────────────────────────────────────────────────────────────
## CDDA 처럼 지형과 별개 레이어다. 가구 밑에는 항상 지형이 따로 있다 —
## 그래서 책상을 부숴도 바닥이 남고, #7 이 가구만 쓸어낼 수 있다.
enum Furn {
	NULL,
	TABLE,
	COUNTER,
	SHELF,
	SINK,
	FRIDGE,
	LOCKER,
}

const FURN_BY_ID := {
	"f_null": Furn.NULL,
	"f_table": Furn.TABLE,
	"f_counter": Furn.COUNTER,
	"f_shelf": Furn.SHELF,
	"f_sink": Furn.SINK,
	"f_fridge": Furn.FRIDGE,
	"f_locker": Furn.LOCKER,
}

## 가구는 전부 못 지나간다. 나중에 종류별로 갈릴 자리라 함수로 남겨둔다.
static func furn_blocks(f: int) -> bool:
	return f != Furn.NULL


static func ter_has(t: int, flag: int) -> bool:
	return (TER_FLAGS[t] & flag) != 0


static func ter_passable(t: int) -> bool:
	return (TER_FLAGS[t] & F_PASSABLE) != 0


## "건물 껍데기의 일부인가" — 벽 9-slice 가 이웃을 볼 때 쓰는 판정이다.
## 문과 창문은 벽에 뚫린 구멍이지 껍데기 밖이 아니므로 같이 친다.
static func is_shell(t: int) -> bool:
	return t == Ter.WALL or t == Ter.WINDOW or t == Ter.DOOR_C \
		or t == Ter.DOOR_O or t == Ter.WALL_BROKEN
