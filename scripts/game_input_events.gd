class_name ApoGameInputEvents

static var direction: Vector2
static var selected: ApoDataTypes.Tools
const QUICK_SLOT_ACTIONS: Array[StringName] = [
		&"select_inventory_0",
		&"select_inventory_1",
		&"select_inventory_2",
		&"select_inventory_3",
		&"select_inventory_4",
  ]

static func number_input() -> int:
	for i in QUICK_SLOT_ACTIONS.size():
		if Input.is_action_just_pressed(QUICK_SLOT_ACTIONS[i]):
			print(i, "pressed")
		return i
	return -1

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
