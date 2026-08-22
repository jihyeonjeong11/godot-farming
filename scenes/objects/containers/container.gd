extends Sprite2D

@export var initial_items: Array[Items] = []
@export var initial_amounts: Array[int] = []

@onready var inventory_component: ContainerInventoryComponent = $ContainerInventoryComponent


func _ready() -> void:
	if not initial_items.is_empty():
		inventory_component.fill(initial_items, initial_amounts)


## 만져졌다. 커서가 이 이름으로 부른다.
func interact() -> void:
	SignalBus.container_opened.emit(inventory_component.slots)


func capture_state() -> Variant:
	return inventory_component.capture()


## 레이어가 add_child 다음에 부른다. 그래서 _ready가 이미 끝나 있고,
## initial_items로 채워둔 것 위에 세이브가 덮인다.
func apply_state(state: Variant) -> void:
	if state is Array:
		inventory_component.apply(state)
