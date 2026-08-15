extends Sprite2D
## 세워두면 계속 남는 상자.
##
## 입력은 읽지 않는다. 우클릭을 읽는 곳은 플레이어 하나뿐이고, 어느 칸의 무엇을
## 눌렀는지는 BuidableCursorComponent가 푼다. 여기까지 오면 이미 이 상자가 확정이다.

## 처음부터 들어 있을 것. 씬에 미리 놓아둔 상자마다 다르게 줄 수 있다.
## 커서로 새로 세운 상자는 이 값이 비어 있어 빈 상자로 시작한다.
@export var initial_items: Array[Items] = []
## 위 항목별 개수. 짧으면 나머지는 1개로 본다.
@export var initial_amounts: Array[int] = []

@onready var inventory_component: ContainerInventoryComponent = $ContainerInventoryComponent


func _ready() -> void:
	# 자식이 먼저 _ready를 지나므로 여기서는 칸이 이미 잡혀 있다.
	if not initial_items.is_empty():
		inventory_component.fill(initial_items, initial_amounts)


## 만져졌다. 커서가 이 이름으로 부른다.
func interact() -> void:
	SignalBus.container_opened.emit(inventory_component.slots)


## LevelBuildables가 세이브를 뜰 때 부른다. 씬 경로와 위치는 레이어가 알아서 적고,
## 여기서는 그것만으로 복원되지 않는 속만 넘긴다.
func capture_state() -> Variant:
	return inventory_component.capture()


## 레이어가 add_child 다음에 부른다. 그래서 _ready가 이미 끝나 있고,
## initial_items로 채워둔 것 위에 세이브가 덮인다.
func apply_state(state: Variant) -> void:
	if state is Array:
		inventory_component.apply(state)
