class_name DroppedItem extends Sprite2D


@export var item: Item: set = set_item, get = get_item

var stack: ItemStack: set = set_stack

@onready var collectable_component: CollectableComponent = $CollectableComponent

func bounce() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.25, 0.75), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.35)\
		.set_trans(Tween.TRANS_ELASTIC)\
		.set_ease(Tween.EASE_OUT)


func _ready() -> void:
	_refresh()
	bounce()
	_warn_if_empty.call_deferred()


func _warn_if_empty() -> void:
	if stack == null or not stack.is_valid():
		push_warning("failed" % name)


func set_item(value: Item) -> void:
	set_stack(ItemStack.new(value, 1) if value != null else null)


func get_item() -> Item:
	return stack.item if stack != null else null


func set_stack(value: ItemStack) -> void:
	stack = value
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	if stack == null or stack.item == null:
		return

	var spec := stack.item
	texture = spec.world_texture if spec.world_texture != null else spec.item_texture
	collectable_component.stack = stack
