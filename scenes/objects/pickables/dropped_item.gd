class_name DroppedItem
extends Sprite2D
## 땅에 떨어진 아이템 한 개. 무엇이 떨어졌는지는 이 씬이 모른다.
## 떨군 쪽(나무·바위·작물·인벤토리)이 [member item]에 자기 .tres를 꽂아준다.
##
## 꽂는 시점은 두 가지다. add_child 전에 넣으면 _ready가, 후에 넣으면 세터가
## 그림과 컴포넌트를 맞춘다. 세이브에서 되살아날 때는 LevelLayer가 add_child
## 다음에 apply_state를 부르므로 후자에 해당한다.

@export var item: Item: set = set_item

## CollectableComponent로 타입을 박지 않는다. 그쪽이 Inventory 오토로드에 묶여 있어서,
## 오토로드가 안 뜬 환경(헤드리스 검증 등)에서는 이 대입 자체가 터진다.
@onready var collectable_component: Node = $CollectableComponent


func _ready() -> void:
	_refresh()
	# 세이브에서 되살아날 때는 add_child 다음에야 아이템이 들어온다.
	# 그러니 한 프레임 뒤에도 비어 있을 때만 진짜 실수다.
	_warn_if_empty.call_deferred()


func _warn_if_empty() -> void:
	if item == null:
		push_warning("item이 끝내 비어 있는 DroppedItem이다: %s" % name)


func set_item(value: Item) -> void:
	item = value
	# _ready 전이면 노드가 아직 없다. 그때는 _ready가 대신 불러준다.
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	if item == null:
		return

	texture = item.world_texture if item.world_texture != null else item.item_texture
	collectable_component.item = item


## 세이브. 어떤 아이템이었는지만 남기면 씬은 공용이라 그대로 복원된다.
func capture_state() -> Dictionary:
	return {"item": item.resource_path if item != null else ""}


func apply_state(state: Dictionary) -> void:
	var path: String = state.get("item", "")
	if path.is_empty():
		queue_free()
		return
	set_item(load(path) as Item)
