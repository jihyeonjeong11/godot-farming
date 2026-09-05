- 캐릭터 스프라이트는 universal 이걸 사용함.
- 다만 총 스프라이트랑 애음니메이션을 찾고 싶
- 아이템 스프라이트는 itch io에 있었음

- [] UI 별 컨트롤 다르게(더블 클릭일때? 오른쪽 클ㄹ깅ㄹ때 템은 어케 버리지? 등) → 아래 "슬롯 컨트롤 — 스타듀밸리 조사" 참고

### 슬롯 컨트롤 — 스타듀밸리 조사 (2026-09-05)

출처: [WeDias/StardewValley](https://github.com/WeDias/StardewValley) 디컴파일 1.5.6. 줄번호는 그 레포 기준.
자세한 구조 분석은 `diagrams/slots.md`.

전제: 스듀에는 드래그앤드랍이 없다. 클릭으로 집어서 **커서가 들고 다니고**(`heldItem`) 다시 클릭해서 놓는다.
그리고 슬롯 격자(`InventoryMenu`)는 클릭 이벤트를 안 받는다 — `leftClick`/`rightClick` 두 함수만 노출하고
메뉴가 그걸 불러서 나온 아이템으로 무엇을 할지 정한다.

**슬롯에 직접 걸리는 클릭 제스처는 5종뿐이다.**
좌클릭 · 우클릭 · Shift+좌클릭 · Shift+우클릭 · Shift+Ctrl+좌클릭.
나머지는 전부 같은 제스처를 메뉴가 다르게 해석하거나, 키보드/휠/패드/호버/외부 버튼이다.

#### 1. 마우스 기본 (모든 메뉴 공통) — `InventoryMenu.cs:259, 323` / `Utility.cs:7907`

| 조작 | 커서 비었을 때 | 들고 있을 때 |
| --- | --- | --- |
| 좌클릭 | 스택 **전부** 집기 | **전부** 놓기 → 합치고 넘치면 커서에 남김, 다른 아이템이면 맞바꿈 |
| 우클릭 | **한 개** 집기 | **한 개** 얹기 |
| Shift+우클릭 | **절반** 집기 `ceil(n/2)` | **절반** 얹기 |

#### 2. 마우스 — 메뉴별로 뜻이 갈리는 것

| 메뉴 | 조작 | 결과 |
| --- | --- | --- |
| 인벤토리 | 장비칸 좌클릭 | 커서와 맞바꿈, 부위 안 맞으면 거부 (`InventoryPage.cs:226~344`) |
| 인벤토리 | 장비칸 Shift+좌클릭 | 벗어서 가방 첫 빈칸으로 (`:345`) |
| 인벤토리 | 가방칸 Shift+좌클릭 | 들고 있는 게 장비면 즉시 착용 (`:370~`) |
| 상자 | 좌클릭 | **원클릭 통째 이동**. 양방향 (`ItemGrabMenu.cs:684, 694`) |
| 상자 | 우클릭 | 한 개씩 나눠 담기 (`:499`) |
| 상점 | 매물 좌클릭 | **1개** 구매 (`ShopMenu.cs:877`) |
| 상점 | 매물 Shift+좌클릭 | **5개** |
| 상점 | 매물 Shift+Ctrl+좌클릭 | **25개** |
| 상점 | 가방칸 좌클릭 | 그 칸 **통째로** 판매 (`:805`) |
| 상점 | 가방칸 우클릭 | **한 개씩** 판매 (`:1302`) |
| 상점 | 가방칸 우클릭 꾹 | 연속 판매, `mouseClickPolling > 300` (`:1321`) |
| 조합 | 레시피 좌클릭 | **1개** 제작 → 커서에 (`CraftingPage.cs:367`) |
| 조합 | Shift+좌클릭 | **5개** (`:332`) |
| 조합 | Shift+Ctrl+좌클릭 | **25개** |
| 조합 | 우클릭 | 좌클릭과 동일 (`:419`) |
| 툴바 | 좌클릭 | 슬롯 **선택**만 (`Toolbar.cs:46`) |
| 툴바 | 우클릭 | **아무것도 안 함** (`:68` 빈 함수) |

#### 3. 아이템 종류가 클릭을 가로채는 것

| 조작 | 결과 |
| --- | --- |
| 도구 칸 우클릭 | **부속 장착**(미끼·보석). 다른 모든 우클릭보다 **우선** (`InventoryMenu.cs:333`) |
| 스타드롭 좌클릭 | 그 자리에서 먹고 메뉴 닫힘 (`InventoryPage.cs:364`) |
| 레시피 아이템 좌클릭 | 배우고 사라짐 (`ItemGrabMenu.cs:678`) |
| 드워프 두루마리 / 유물 좌클릭 | 즉시 해금 + 이펙트 (`ItemGrabMenu.cs:650, 657`) |
| `allowRightClick = false` 상자 | 우클릭이 **부속 장착만** 허용 (`ItemGrabMenu.cs:489`) |

#### 4. 키보드

| 키 | 결과 |
| --- | --- |
| 숫자 1~0 | 툴바 슬롯 선택. **인벤토리 메뉴가 열려 있어도 먹힘** (`InventoryPage.cs:154~`) |
| Delete | 커서에 든 것 삭제 (`InventoryPage.cs:152`, `ItemGrabMenu.cs:954`, `CraftingPage.cs:275`) |
| ESC/메뉴키 | 뭔가 들고 있으면 마우스를 쓰레기통 위로 옮겨줌 (패드 배려, `InventoryPage.cs:150`) |
| ESC (상점) | 커서에 든 것을 가방에 넣거나 땅에 떨굼 — `CollectOrDrop` (`ShopMenu.cs:762`) |
| 방향키 | snappy 모드에서 칸 사이 이동 (`applyMovementKey`) |

#### 5. 휠

| 위치 | 결과 |
| --- | --- |
| 인게임 툴바 | 슬롯 선택 순환 (`Toolbar.shifted()`, `:92`) |
| 조합 화면 | 레시피 **페이지** 넘김 (`CraftingPage.cs:285`) |
| 상점 | 매물 목록 스크롤 (`ShopMenu.cs:727`) |

#### 6. 게임패드

| 입력 | 결과 |
| --- | --- |
| 스틱/D패드 | snappy 커서가 칸에서 칸으로 **스냅** 이동 |
| Back | 정리(Organize) (`ItemGrabMenu.cs:893`, `InventoryPage.cs:482`) |
| RightShoulder | "기존 스택에 합치기" 버튼으로 스냅 (`ItemGrabMenu.cs:898`) |

#### 7. 호버 — `InventoryMenu.hover` (`:402`)

| 결과 |
| --- |
| 칸이 **1.0 → 1.1 로 확대**, 벗어나면 서서히 복귀 (`:412, 417`) |
| 툴팁 = 이름 + 설명 |
| **커서에 든 것과 비교한** 툴팁 — `getHoverBoxText(heldItem)`, 장비 능력치 비교용 (`:419`) |
| 커뮤니티센터 번들 재료면 강조 표시 (`:432`) |
| 쓰레기통 호버 시 뚜껑 열림 애니메이션 + 환급가 표시 (`MenuWithInventory.cs:132`) |

#### 8. 슬롯 밖이지만 슬롯 내용에 작용

| 조작 | 결과 |
| --- | --- |
| 쓰레기통에 놓기 | 삭제. 쓰레기통 등급에 따라 일부 환급 (`InventoryPage.cs:461`) |
| **메뉴 바깥** 클릭 | 들고 있던 것을 땅에 던짐 — `DropHeldItem` (`ItemGrabMenu.cs:746`) |
| 정리 버튼 | 배열 전체 정렬 (`organizeItemsInList`) |
| **기존 스택에 합치기** 버튼 | 상자에 이미 있는 종류만 골라 밀어넣음 — `FillOutStacks` (`ItemGrabMenu.cs:761`) |
| 되사기(buyback) 칸 | 방금 판 것 되사기 (`ShopMenu.cs:1180`) |

#### 우리 코드에 옮길 때 걸리는 것

- 지금 우리 우클릭은 **버리기**(`scene_ingame_overlay_menu.gd:120`)인데 스듀에선 **한 개 집기**다.
  커서 모델로 가면 버리기는 **메뉴 바깥 클릭**으로 옮겨가야 한다.
- 스택 합치기가 우리에겐 없다. `inventory_slot.gd:66-68` 은 무조건 swap.
- 커서 모델을 쓰면 드래그 콜백 3개(`inventory_slot.gd:34, 50, 54`)와 `draggable` 플래그,
  `EquipmentSlot._can_drop_data` 상속이 전부 사라진다.
- 아직 안 정함: 커서 모델로 갈아탈지, 드래그를 유지할지.

- 거래 UI

- 피커블 / 플레이서블 리팩터

- [x] items.gd -> item.gd 이름 바꾸기
- [x] item_stack.tscn 추가 refCounted
- [x] 기존 item_stack 옮기기
- [x] item_stack.tscn에 모든 기능 복제(droppable, )
- [x] dropped_item 스크립트 item_stack으로 바꾸기
- [x] 모든 dropped_item을 item_stack으로 변경
- [] 모든 item 참조를 item_id으로 변경

- [] 맨 마지막 tscn 아이템들 모두 정리
- [] 옮겨진 파일들 삭제

### 위 계획 점검 (2026-09-03 확인)

**1. item_stack.tscn 이 지금 깨져 있다**
Sprite2D 노드에 `item_stack.gd` 를 붙여놨는데 그 스크립트는
`class_name ItemStack extends Resource` 다. Resource 스크립트는 Node 에 못 붙는다.
인스턴스하는 순간 에러. → 씬으로 만들려면 스크립트를 새로 써야 한다.

**2. ItemStack 이름은 이미 인벤토리 칸이 쓰고 있다**
`item_stack.gd` = 인벤토리 한 칸(item + amount) 리소스. 참조 20군데 이상:

- `scripts/globals/inventory.gd` inventory / armor / boots 배열
- `scripts/globals/save_and_load.gd`, `container_inventory_component.gd`
- `shop_ui.gd`, `inventory_slot.gd`, `equipment_slot.gd`, `container_inventory_ui.gd`
- `craft_recipe.gd` + `axe_recipe.tres` / `container_recipe.tres` (tres 가 스크립트를 직접 참조)

여기에 월드 노드(dropped_item)까지 `class_name ItemStack` 을 달면 중복 선언이라
에디터가 안 뜬다. → 월드 노드와 인벤토리 칸 중 하나는 다른 이름을 써야 한다.
(예: 월드 노드 = ItemPickup / WorldItem, 칸 = ItemStack 유지)

**3. item.tscn / item_stack.tscn 둘 다 아무도 안 쓴다**
참조 0. dropped_item.tscn 복사본이다. item.tscn 은 스크립트도 안 붙어 있다.
→ 리팩터 중간 산물. 정리 대상.

**4. 계획에 amount 얘기가 없다 — 이게 진짜 목적 아닌가**
지금 상태:

- `dropped_item.gd` 는 `item: Item` 하나만 들고 amount 가 없다
- `collectable_component.gd:78` → `Inventory.add_item(item)` 무조건 1개
- `inventory.gd:155` 크래프팅 결과 3개면 add_item 을 3번 돈다
- 당근 5개 떨구려면 노드 5개를 깔아야 한다

이름만 ItemStack 으로 바꿔도 이건 그대로다. 스택으로 만드는 값어치는
"월드 드롭도 (item, amount) 를 갖는 것" 에 있다.

**5. `Inventory.add_item` 시그니처가 amount 를 못 받는다**
`add_item(item) -> bool`. 인벤 꽉 찼을 때 "5개 중 3개만 들어감" 을 표현 못 한다.
→ `add_item(item, amount := 1) -> int` (못 넣은 개수 반환) 로 바꿔야
collectable_component 가 남은 수량만큼 노드를 살려둘 수 있다.
`craft()` 의 for 루프도 이걸로 없어진다.

**6. "모든 item 참조를 item_stack으로 변경" 은 그대로 하면 안 된다**
`Item`(아이템 정의)과 `ItemStack`(수량 있는 칸)은 다른 개념이다.
`loot_table_component.roll()` 이 Item 을 반환하는 건 맞다.
스택이 필요한 건 "월드에 떨어지는 경계" 뿐이다.

**7. 순서 문제 — 세이브 포맷**
`dropped_item.gd` 의 `capture_state` / `apply_state` 는 지금 item 경로만 저장한다.
amount 를 넣으면 포맷이 바뀌므로, 노드에 amount 를 넣는 작업 다음에 손대야 한다.
이름 바꾸기(rename)는 맨 마지막. 에디터 rename 이 참조를 갱신해주니까
기능 변경이 다 끝난 뒤가 안전하다.

### 다시 짠 순서 (제안)

- [] item.tscn 삭제 (참조 0, 스크립트도 없음)
- [] item_stack.tscn 삭제하거나, 남길 거면 Node 용 스크립트를 새로 붙이기
- [] item_stack.gd 를 scripts/resources/ 로 이동 (리소스가 scenes/ 밑에 있는 게 이상함)
- [] Inventory.add_item(item, amount := 1) -> int 로 확장, craft() 루프 정리
- [] dropped_item.gd 에 amount 추가
- [] collectable_component 가 남은 개수 반영 (다 못 넣으면 노드 유지)
- [] capture_state / apply_state 에 amount 추가
- [] (원하면) 월드 노드 이름 변경 — ItemStack 은 이미 쓰이니 다른 이름으로

데모에 걸맞은 남은 일들

## 상점 UI

- [x] 골드 인게임 오버레이 추가
- [x] 골드 저장
- [x] 상점 UI
- [x] 상점 붕대 구매

## 좀비 ROOT TABLE

- [x] 씨앗 종류 중 무작위로 받게

- [] 각종 작물 추가 CRAFTWORLD

## 상점 ui 전

- menu 표시 시 pause 통일하기 - uimanager

## 농사 루프

- [x] 플레이어 클리닝
- [x] 작물 watered 타일
- [x] tilled soil watered soil 그룹
- [x] 물주기 타일 속성으로 변경
- [x] 현재 수확이 물뿌리개만 됨
- [x] 농사 growthCycle 저장

## 캐릭터

- [x] 배고픔
- [x] 목마름

## 자원관리

- [] 물
- [] 식량 - 시간 지나면 줄어듬, 체력 채우면서 줄어듬
- [] 체력 -
- [] 스태미너? 필요할것인지?

## 탄약

- [] 물뿌리개 물 소모

## 인벤토리

- [x] 상자 UI
- [x] 돈 추가 - 인벤토리에 포함 안됨 숫자로만

## 타일맵

## NPC

- [x] 상인 추가
- [x] 상점 UI 추가
- [] 판매 구매 로직 추가

- [] 무기 히트박스
- [] 메인 메뉴 스크린
- [] 세이브 슬롯
- [] 체력은 시간에 따라 소모함
- [] 작물 양 늘리기
- [] 작물 사용할 시 체력 증가
- [] 타일 액션 컴포넌트로 통일
- [] 사운드 붙이기
- [] 팜 static 지도
- [] ui 디자인 제대로
- [] 터미널 추가
- [] 상점 ui
- [] 살 수 있는 것 붕대 하나?

- 전투 관련 다음 잡
- [] 캐릭터 공격 스프라이트 추가
- [] 공격 컴포넌트는 타일 사용 안함.
- [] 도시 procedural generation

## refactor jobs

- 글로벌 -> game 안으로 넣을 것 날씨, 시간 등

다음 잡

- [] 갈 수 있는 타일 종류 체크 필요 - 타일맵 교체?

대

- ui 맵은 현재 그대로 -> 추후 szadi로 교체할거임
