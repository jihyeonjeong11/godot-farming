class_name ItemStackInstance
extends Sprite2D

@export var item: Item: set = set_item, get = get_item

var stack: ItemStack: set = set_stack
@onready var collectable_component: Node = $CollectableComponent


func _ready() -> void:
	_refresh()

	_warn_if_empty.call_deferred()


func _warn_if_empty() -> void:
	if stack == null or not stack.is_valid():
		push_warning("stack이 끝내 비어 있는 ItemStackInstance다: %s" % name)


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


func capture_state() -> Dictionary:
	var saved: Variant = stack.to_dict() if stack != null else null
	return {"stack": saved}


func apply_state(state: Dictionary) -> void:
	var saved: Variant = state.get("stack", null)
	if saved == null:
		var legacy_path: String = state.get("item", "")
		if not legacy_path.is_empty():
			saved = {"item": legacy_path, "amount": 1}

	var restored := ItemStack.from_dict(saved)
	if restored == null:
		queue_free()
		return

	set_stack(restored)
