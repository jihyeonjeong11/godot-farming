● 맞음, 지금 오브젝트 하나당 판정 소스가 사실 4개임 (그룹 등록 + global_position, HurtComponent의 Area2D, StaticBody2D,
placeables_layer면 스프라이트 rect). SproutValley는 이걸 셀 하나로 합쳐놨음. 코드 다 뜯어봤는데 구조가 꽤 깔끔함.

SproutValley가 하는 방식

1. GenericObject.tscn = StaticBody2D 하나가 전부

src/Objects/GenericObject.tscn — 모든 상호작용/파괴 가능 오브젝트가 이걸 상속함 (Tree, Bush, Stone, Chest, Bamboo,
Cactus...). groups=["GenericObject", "Persist"]. 여기에 다 들어있음:

- 물리 CollisionShape2D (걷기 막기)
- 플래그: destructable, interactable, interactable_by_hand_only, rotateable, hidden
- 시그널: interact, rotate_object, destroyed, player_hoe_ground, player_swing_axe, player_swing_pickaxe,
  player_water_ground
- extended: Array[Vector2] — 여러 칸 점유, shifted: Vector2 — 앵커 오프셋

2. WorldState 가 셀→오브젝트 딕셔너리 하나를 들고 있음 (src/WorldState.gd)

gdscript
func collect_objects():
for obj in get_tree().get_nodes_in_group("GenericObject"):
add_object(world_to_map(obj.global_position + obj.shifted), obj)

# add_object 는 obj.extended 칸까지 같이 등록

var objects_map = {} # Vector2 cell -> weakref(obj)

이게 유일한 판정임. 거리 계산 없음, 오브젝트별 Area2D 없음, 레이캐스트 없음. get_object(cell) 딕셔너리 조회 한 번.

3. PlayerTargeting 이 프레임당 target_cell 하나만 계산 (src/Actor/PlayerTargeting.gd:63)

마우스가 max_mouse_radius(70px, 패드면 50/40) 안이면 마우스 셀, 그것도 tool_range(기본 2칸, 낚싯대 4칸) 넘으면
방향으로 클램프. 마우스가 멀면 그냥 바라보는 방향 앞 칸. 그리고 그 칸에 핀/하이라이트를 띄움 — 플레이어가 판정을
눈으로 봄.

4. 사용도 파괴도 같은 줄을 씀

gdscript

# Player.gd:422 — 손/우클릭

var obj = WorldState.get_object(GameUtils.target_cell)
if obj.interactable: obj.emit_signal("interact")

# Player.gd:517 — 도구 스윙

var obj = WorldState.get_object(GameUtils.target_cell)
if obj: obj.emit_signal("player_swing_axe")

같은 lookup, 같은 칸. 어긋날 여지가 구조적으로 없음. TreeController.gd:209 \_on_Tree_player_swing_axe() 가 그걸 받아서
toughness 깎고 쓰러뜨림.

5. 충돌은 따로지만 같은 노드에 있음

CollisionShape2D는 걷기 전용이고 판정에 안 씀. 대신 오브젝트가 자기 자신이 StaticBody2D라서, 점유
칸(shifted/extended)이랑 충돌 모양이 한 씬 안에 나란히 있음. 따로 관리되는 게 아니라 같은 자리에서 편집됨.

6. 곁다리인데 좋은 것: $ToolMenu.guess_tool(obj) — 도구 틀렸을 때 알아서 맞는 도구로 바꿔줌. 오브젝트 레퍼런스가
   하나라서 가능한 것.

7. InteractionManagerArea (Area2D + radius + by_tool + action 라벨)도 있긴 한데 씬 9개에만 씀 — NPC, 집 문, 상점,
   보트. "가까이 가면 라벨 뜨고 E" 용도임. 격자에 안 맞는 것들 전용이고, 중복이 아니라 의도적으로 분리된 두 번째 시스템.

지금 프로젝트와 대조

┌──────┬───────────────────────────┬──────────────────────────────────────────────────────────────────────────────┐
│ │ SproutValley │ apo-farming │
├──────┼───────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
│ 사용 │ target_cell → objects_map │ interactables 그룹 → 원점 44px + 마우스 최근접 또는 placeables_layer 셀 + │
│ │ │ get_visual_rect │
├──────┼───────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
│ 파괴 │ target_cell → objects_map │ HitComponent Area2D ↔ HurtComponent Area2D 물리 겹침 │
├──────┼───────────────────────────┼──────────────────────────────────────────────────────────────────────────────┤
│ 충돌 │ 오브젝트 자신이 │ 오브젝트별 StaticBody2D 자식 │
│ │ StaticBody2D │ │
└──────┴───────────────────────────┴──────────────────────────────────────────────────────────────────────────────┘

제안

합치는 지렛대는 "모양"이 아니라 "칸"임. 이게 핵심. 셰이프를 통일하려고 하면 각 시스템이 원하는 게 달라서 계속
어긋나는데, 칸으로 내리면 하나로 떨어짐. 그리고 이 프로젝트엔 이미 근거가 다 있음 — OMT 한 칸 16x16,
FieldCursor/CropsCursor/PlaceableCursor 전부 이미 셀로 돌아가고, 앵커 1셀 + 사각형 점유는 이미 확정해둔 것이라
shifted/extended 에 그대로 대응됨.

들어갈 순서:

1. InteractableComponent 에 anchor_offset: Vector2i + footprint: Vector2i 를 @export 로 얹음 (= shifted/extended)
2. 셀→노드 레지스트리 오토로드 하나. 컴포넌트가 \_ready 에서 그룹 대신 여기에 등록 (queue_free 대비 weakref 또는
   tree_exiting 해제)
3. 플레이어가 target_cell 하나를 계산해서 소유. 커서 컴포넌트 4개가 각자 마우스를 다시 푸는 대신 그걸 읽음 — 아까 말한
   이중 호출 버그가 여기서 자동으로 사라짐
4. 우클릭/도구 둘 다 registry.get(target_cell) 로 해결
5. StaticBody2D 충돌은 footprint 에서 생성

한 가지 안 옮기는 게 좋은 것: HurtComponent/HitComponent Area2D는 적/전투용으로 남겨야 함. item.melee_shape 로 스윙
궤적을 만드는 구조라 칸 조회로 바꾸면 휘두르는 범위가 없어짐. 분리선은 "도구가 월드 오브젝트를 칠 때 → 칸", "무기가
움직이는 대상을 칠 때 → Area2D". SproutValley도 사실상 그렇게 갈라놨음.

2번 레지스트리부터 만들어볼까? 그거만 들어가면 나머지는 호출부 갈아끼우는 일이라서.
