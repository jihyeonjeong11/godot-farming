@tool
extends WorldObject

@onready var anim: AnimationPlayer = $AnimationPlayer

var state: Dictionary = {
	"is_open": false,
	"inventory": []
}

func _ready() -> void:
	super()
	state = SnapshotActions.populate(global_position, data.id, state)
	state.is_open = false
	_apply_open()

func on_interact() -> void:
	if state.is_open:
		return
	var limit: int = (data as ContainerObject).inventory_limit if data is ContainerObject else 0
	var stacks: Array = []
	for entry in state.inventory:
		stacks.append(ItemStack.from_dict(entry))
	stacks.resize(limit)
	state.is_open = true
	_apply_open()
	SignalBus.container_closed.connect(_on_container_closed, CONNECT_ONE_SHOT)
	SignalBus.container_opened.emit(stacks)

func _on_container_closed(stacks: Array) -> void:
	state.inventory = stacks.map(func(stack: ItemStack) -> Variant: return stack.to_dict() if stack != null else null)
	state.is_open = false
	_apply_open()

func _apply_open() -> void:
	anim.play(&"open" if state.is_open else &"closed")
	anim.advance(0)
