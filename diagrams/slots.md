# 슬롯 조작 — 스타듀밸리 방식 조사

출처: [WeDias/StardewValley](https://github.com/WeDias/StardewValley) (디컴파일 1.5.6).
아래 줄번호는 전부 그 레포 기준. 우리가 뭘 가져올지 정하려고 훑은 기록이다.

---

## 1. 두 가지 큰 구조 차이

### (1) 드래그가 아니라 "커서에 든다"

스듀에는 드래그앤드랍이 없다. 클릭으로 집어서 **커서가 들고 다니고**, 다시 클릭해서 놓는다.
그 손에 든 것이 `heldItem` (`MenuWithInventory.cs:94`) — 멀티플레이 동기화용으로는
`Game1.player.CursorSlotItem`.

버튼을 누르고 있을 필요가 없으니 메뉴를 넘나들며 들고 다닐 수 있고, 그래서 "절반만 집기",
"한 개씩 놓기" 같은 세밀한 조작이 성립한다. 우리 `_get_drag_data`/`_drop_data` 로는 안 나오는 것들이다.

### (2) 슬롯 격자는 이벤트를 받지 않는다 — 메뉴가 물어본다

이게 더 중요하다. `InventoryMenu`(칸 격자)의 클릭 핸들러는 **비어 있다**:

```csharp
// InventoryMenu.cs:526
public override void receiveLeftClick(int x, int y, bool playSound = true) { }
public override void receiveRightClick(int x, int y, bool playSound = true) { }
public override void performHoverAction(int x, int y) { }
```

대신 격자는 두 개의 **순수 함수**만 노출한다.

| 함수 | 위치 | 하는 일 (그게 전부다) |
|---|---|---|
| `leftClick(x, y, toPlace)` | `InventoryMenu.cs:259` | 커서가 비었으면 그 칸 스택 **전부** 뽑아서 반환 / 들고 있으면 **놓고** 밀려난 것을 반환 |
| `rightClick(x, y, toAddTo)` | `InventoryMenu.cs:323` | **한 개** 뽑기 (Shift면 절반) / 들고 있으면 **한 개** 더 얹기 |

그리고 각 메뉴가 자기 `receiveLeftClick`에서 이 함수를 **불러서** 나온 아이템으로 무엇을 할지 정한다.

- 인벤토리 페이지: 나온 걸 커서에 올린다 (`InventoryPage.cs:363`)
- 상자: 나온 걸 반대편으로 옮긴다 (`ItemGrabMenu.cs:684`)
- 상점: 나온 걸 **판다** (`ShopMenu.cs:805`)

즉 **"스택 전부 뽑기 / 한 개 뽑기"라는 조작만 슬롯이 알고, 그 뜻은 전부 메뉴가 정한다.**
우리가 논의하던 "UI마다 다른 액션"의 답이 여기 있다. 다만 방향이 반대다 —
우리는 슬롯이 시그널을 **쏘고**(push), 스듀는 메뉴가 슬롯에 **물어본다**(pull).

---

## 2. 기본 조작 — 모든 메뉴 공통

`Utility.addItemToInventory` (`Utility.cs:7907`) 가 놓기 규칙의 핵심이다:
빈 칸이면 넣고 · 같은 아이템이면 합치고 **넘치는 만큼은 커서에 남기고** · 다른 아이템이면 자리를 맞바꾼다.

| 조작 | 커서가 비었을 때 | 뭔가 들고 있을 때 |
|---|---|---|
| 좌클릭 | 스택 **전부** 집기 | **전부** 놓기 → 합치기, 안 되면 맞바꾸기 |
| 우클릭 | **한 개** 집기 | **한 개** 놓기 |
| Shift + 우클릭 | **절반** 집기 (`ceil(n/2)`) | **절반** 얹기 |
| 호버 | 툴팁 | 툴팁 |

> ⚠️ 앞서 대화에서 내가 "우클릭 = 절반"이라고 했는데 **틀렸다.**
> 실제로는 **우클릭 = 한 개**, **Shift+우클릭 = 절반** 이다 (`InventoryMenu.cs:344, 358`).

우클릭에는 예외가 하나 더 있다. 그 칸이 도구고 커서에 든 게 부속(미끼·보석)이면 **장착이 우선**한다
(`InventoryMenu.cs:333`). 우리로 치면 총에 탄창 끼우기가 여기 자리다.

---

## 3. 메뉴별로 다른 뜻

### 인벤토리 페이지 (`InventoryPage.cs`)

| 조작 | 결과 |
|---|---|
| 가방 칸 좌/우클릭 | 위 기본 표 그대로 (`:363`, `:490`) |
| 장비 칸 좌클릭 | 커서에 든 것과 **맞바꿈**. 부위가 맞아야 들어간다 (`:226~344`) |
| 장비 칸 **Shift+좌클릭** | 벗어서 가방 첫 빈칸으로 (`:345`) |
| 가방 칸 **Shift+좌클릭** | 들고 있는 게 장비면 **즉시 착용** (`:370~`) |
| 쓰레기통에 놓기 | 삭제. 등급에 따라 일부 환급 (`:461`) |
| **메뉴 바깥** 클릭 | 들고 있던 것을 땅에 던지기 (`:467`) |
| 정리 버튼 | 배열 전체 정렬 (`:472`, 슬롯 조작 아님) |

특수 케이스 하나: 스타드롭(id 434)을 집으면 그 자리에서 **먹고** 메뉴가 닫힌다 (`:364`).
슬롯 조작이 아이템별로 갈라질 수 있다는 예시.

### 상자 (`ItemGrabMenu.cs`)

**좌클릭 한 번에 통째로 건너간다. 양방향 다.**

- 상자 칸 좌클릭 → 집은 뒤 `addItemToInventoryBool` 로 바로 가방행. 가방이 꽉 찼으면 커서에 남는다 (`:684`)
- 가방 칸 좌클릭 → `base`가 집고, `behaviorFunction`이 상자로 넣는다 (`:694`)
- 우클릭은 기본 표대로 (한 개 / Shift면 절반) — 나눠 담을 때 쓴다
- **기존 스택에 합치기** 버튼: `FillOutStacks()` (`:761`) — 상자에 이미 있는 종류만 골라 밀어넣는다
- **정리** 버튼: `organizeItemsInList`
- 메뉴 밖에 놓기 → `DropHeldItem()` 땅에 (`:746`)

### 상점 (`ShopMenu.cs`)

| 조작 | 결과 |
|---|---|
| 매물 좌클릭 | **1개** 구매 (`:877`) |
| **Shift** + 매물 좌클릭 | **5개** |
| **Shift+Ctrl** + 매물 좌클릭 | **25개** |
| 내 가방 칸 좌클릭 | 그 칸 **통째로** 판매 (`:805`) |
| 내 가방 칸 우클릭 | **한 개씩** 판매. 꾹 누르면 연속 (`:1302`, `:1321`) |
| 휠 | 매물 목록 스크롤 (`:727`) |

산 물건은 커서에 올라오는데, Shift를 누르고 있었으면 알아서 가방에 들어간다 (`:896`).

### 조합 (`CraftingPage.cs`)

| 조작 | 결과 |
|---|---|
| 레시피 좌클릭 | **1개** 제작 → 커서에 올림 (`:367`) |
| **Shift** + 좌클릭 | **5개** (`:332`) |
| **Shift+Ctrl** + 좌클릭 | **25개** |
| 우클릭 | 좌클릭과 같음 (`:419`) |

Shift를 누르고 있으면 만든 걸 가방에 자동으로 넣는다 (`:338`). 커서에 이미 같은 게 있으면
스택에 더한다.

### 툴바 / 퀵바 (`Toolbar.cs`)

메뉴 슬롯과 완전히 다른 규칙이다. **집기·놓기가 없다.**

- 좌클릭 = 그 칸 **선택**만 (`CurrentToolIndex`, `:46`)
- 우클릭 = **아무것도 안 함** (`:68` 빈 함수)
- 숫자키 1~0 = 선택, 휠 = 순환 (`shifted()`, `:92`)

---

## 4. 정리 — 우리 코드에 옮긴다면

### 없어지는 것
- `_get_drag_data` / `_can_drop_data` / `_drop_data` (`inventory_slot.gd:34~76`) 세 콜백 전부
- `EquipmentSlot`이 `_can_drop_data` 하나 때문에 상속하는 구조 (`equipment_slot.gd:12`)
  → 부위 검사는 놓기 규칙 한 곳으로
- `draggable` 플래그 (`inventory_slot.gd:14`) — 조합·상점은 애초에 집기라는 개념이 없는 메뉴가 된다

### 생기는 것
- `Inventory`에 커서 상태 하나 (`var held: ItemStack`)
- 커서를 따라다니는 그림 노드 (Godot 드래그 미리보기를 못 쓰므로 `CanvasLayer` + 마우스 추적)
- 두 개의 순수 함수. 스듀의 `leftClick`/`rightClick`에 해당한다:
  ```gdscript
  # 스택 전부 뽑기 / 놓기. 나온 걸 어쩔지는 부르는 쪽이 정한다.
  func take_all(source: Array, index: int) -> ItemStack
  func take_one(source: Array, index: int, half: bool = false) -> ItemStack
  func put(source: Array, index: int, stack: ItemStack) -> ItemStack  # 밀려난 것 반환
  ```
- **스택 합치기.** 지금 `_drop_data`는 무조건 swap이라 합치기가 없다.
  `addItemToInventory` 자리에 해당하는 함수 하나에서 해결된다.

### 우리 UI 대응

| 우리 것 | 스듀 대응 | 좌클릭 | 우클릭 |
|---|---|---|---|
| 인벤토리 격자 (`scene_ingame_overlay_menu.gd:66`) | InventoryPage | 전부 집기/놓기 | 한 개 |
| 조합 격자 (`:87`) | CraftingPage | 1개 제작 (Shift 5) | 제작 |
| 상자 UI (`container_inventory_ui.gd`) | ItemGrabMenu | 통째 이동 | 한 개 이동 |
| 상점 (`shop_ui.gd`) | ShopMenu | 구매 1 / 통째 판매 | 한 개씩 판매 |
| 퀵바 (`quick_bar.gd`) | Toolbar | 선택만 | 없음 |
| 장비칸 (`equipment_panel.gd`) | equipmentIcons | 맞바꿈 | — |

### 열어둔 질문
- **push vs pull.** 스듀는 메뉴가 슬롯에 물어보는 pull 구조인데, Godot는 `Button`이 시그널을 쏘는
  push가 자연스럽다. 우리는 push를 유지하되 `activated(gesture, index)` 하나로 통일하고
  각 UI가 `match` 표를 갖는 쪽이 맞아 보인다. 제스처 어휘는
  `LEFT / RIGHT / SHIFT_LEFT / SHIFT_RIGHT / SHIFT_CTRL_LEFT` 다섯 개면 위 표가 전부 덮인다.
- 지금 우리 우클릭은 "버리기"(`scene_ingame_overlay_menu.gd:120`)인데 스듀에선 "한 개 집기"다.
  커서 모델로 가면 버리기는 **메뉴 밖 클릭**으로 옮겨가야 한다.
- 드래그를 남길지. 스듀는 안 쓴다. 같이 두면 좌클릭을 두 모델이 다투게 된다.
