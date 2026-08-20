class_name GameInputEvents

const QUICK_SLOT_ACTIONS: Array[StringName] = [
	&"select_inventory_1", &"select_inventory_2", &"select_inventory_3",
	&"select_inventory_4", &"select_inventory_5", &"select_inventory_6",
	&"select_inventory_7", &"select_inventory_8", &"select_inventory_9",
	&"select_inventory_10",
]

static var direction: Vector2
static var selected: DataTypes.Tools

static func pause_input() -> bool:
	if Input.is_action_pressed("pause"):
		return true
	return false

static func movement_input() -> Vector2:
	if Input.is_action_pressed("walk_left"):
		direction = Vector2.LEFT
	elif Input.is_action_pressed("walk_right"):
		direction = Vector2.RIGHT
	elif Input.is_action_pressed("walk_up"):
		direction = Vector2.UP
	elif Input.is_action_pressed("walk_down"):
		direction = Vector2.DOWN
	else:
		direction = Vector2.ZERO

	return direction

static func is_movement_input() -> bool:
	if direction == Vector2.ZERO:
		return false
	else:
		return true
		
static func is_use_tool() -> bool:
	var use_tool_value: bool = Input.is_action_just_pressed("hit")
	if use_tool_value == true:
		return true
	else:
		return true

static func use_tool() -> bool:
	var use_tool_value: bool = Input.is_action_just_pressed("hit")

	return use_tool_value

static func interact() -> bool:
	return Input.is_action_just_pressed("interact")

static func number_key_input(event: InputEvent) -> int:
	for i in QUICK_SLOT_ACTIONS.size():
		if event.is_action_pressed(QUICK_SLOT_ACTIONS[i]):
			return i
	return -1
