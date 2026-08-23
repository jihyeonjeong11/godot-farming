class_name UIManager
extends Node

const SCENE_OVERAY = preload("uid://cgv3nwfyr3n17")
const SCENE_OVERLAY_MENU = preload("uid://6jsgfc4dh1hr")
const SCENE_INGAME_OVERLAY_MENU = preload("uid://dncd82n2y0aas")
const SCENE_CONTAINER_INVENTORY_UI = preload("uid://b7xqk2mcnv0ug")

enum Layer { PAUSE_MENU, INGAME_MENU, CONTAINER }

var stack: Array[int] = []

var ingame_overlay: CanvasLayer = null

var _layer_nodes: Dictionary = {}

## 화면을 만들 때 건네줄 값. Layer -> Variant
var _layer_payloads: Dictionary = {}

var _game_state: DataTypes.GameState = DataTypes.GameState.MainMenu
var _announced: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SignalBus.game_state_changed.connect(on_change_game_state)
	SignalBus.ui_close_requested.connect(close)
	SignalBus.container_opened.connect(on_container_opened)


func _shortcut_input(event: InputEvent) -> void:
	if _game_state == DataTypes.GameState.MainMenu:
		return
		
	if event.is_action_pressed("ingame_pause"):
		# Currently there are no consecutive menus.
		if stack.is_empty():
			_toggle(Layer.INGAME_MENU)
			get_viewport().set_input_as_handled()
		else:
			_pop()
		return

	if event.is_action_pressed("pause"):
		if stack.is_empty():
			_push(Layer.PAUSE_MENU)
		else:
			_pop()
		get_viewport().set_input_as_handled()


func on_change_game_state(game_state: DataTypes.GameState) -> void:
	_game_state = game_state

	close_all()

	match game_state:
		DataTypes.GameState.Game:
			open_ingame_overlay()
		DataTypes.GameState.MainMenu:
			close_ingame_overlay()


## 상자를 만졌다. 입력이 아니라 상호작용으로 들어오는 길.
func on_container_opened(slots: Array) -> void:
	# 같은 상자를 다시 만지면 닫는다. 다른 상자면 내용만 갈아끼운다.
	if is_open(Layer.CONTAINER):
		if is_same(_layer_payloads.get(Layer.CONTAINER), slots):
			close(Layer.CONTAINER)
		else:
			_layer_payloads[Layer.CONTAINER] = slots
			_apply_payload(Layer.CONTAINER)
		return

	open(Layer.CONTAINER, slots)


func open(layer: Layer, payload: Variant = null) -> void:
	if stack.has(layer):
		return
	_layer_payloads[layer] = payload
	_push(layer)


func close(layer: Layer) -> void:
	if not stack.has(layer):
		return
	stack.erase(layer)
	_sync()


func close_all() -> void:
	if stack.is_empty():
		return
	stack.clear()
	_sync()


func is_open(layer: Layer) -> bool:
	return stack.has(layer)


func top() -> Variant:
	return stack.back() if not stack.is_empty() else null


func open_ingame_overlay() -> void:
	if is_instance_valid(ingame_overlay):
		return

	ingame_overlay = SCENE_OVERAY.instantiate()
	add_child(ingame_overlay)


func close_ingame_overlay() -> void:
	if not is_instance_valid(ingame_overlay):
		return

	remove_child(ingame_overlay)
	ingame_overlay.queue_free()
	ingame_overlay = null


func _toggle(layer: Layer) -> void:
	if stack.has(layer):
		stack.erase(layer)
	else:
		stack.push_back(layer)
	_sync()


func _push(layer: Layer) -> void:
	stack.push_back(layer)
	_sync()


func _pop() -> void:
	if stack.is_empty():
		return
	stack.pop_back()
	_sync()


func _open_layer_node(layer: Layer) -> void:
	if _layer_nodes.has(layer):
		return

	var node: CanvasLayer = null
	match layer:
		Layer.PAUSE_MENU:
			node = SCENE_OVERLAY_MENU.instantiate()
		Layer.INGAME_MENU:
			node = SCENE_INGAME_OVERLAY_MENU.instantiate()
		Layer.CONTAINER:
			node = SCENE_CONTAINER_INVENTORY_UI.instantiate()

	if node == null:
		return

	_layer_nodes[layer] = node
	# add_child가 _ready를 먼저 돌린다. payload는 그다음이라 항상 초기화 이후다.
	add_child(node)
	_apply_payload(layer)


func _apply_payload(layer: Layer) -> void:
	var payload: Variant = _layer_payloads.get(layer)
	if payload == null:
		return

	var node: Node = _layer_nodes.get(layer)
	if not is_instance_valid(node) or not node.has_method(&"setup"):
		return

	node.call(&"setup", payload)


func _close_layer_node(layer: Layer) -> void:
	if not _layer_nodes.has(layer):
		return

	var node: Node = _layer_nodes[layer]
	_layer_nodes.erase(layer)
	_layer_payloads.erase(layer)

	if is_instance_valid(node):
		remove_child(node)
		node.queue_free()


func _sync() -> void:
	# 정지 여부를 먼저 확정한 뒤 각 화면에 알린다. 화면이 켜질 때는
	# 이미 트리가 멈춰 있어야 뒤에서 플레이어가 한 프레임 더 움직이지 않는다.
	SignalBus.ui_stack_changed.emit(not stack.is_empty())

	for layer in Layer.values():
		var opened := stack.has(layer)
		if _announced.get(layer, false) == opened:
			continue
		_announced[layer] = opened

		if opened:
			_open_layer_node(layer)
		else:
			_close_layer_node(layer)

		match layer:
			Layer.PAUSE_MENU:
				SignalBus.game_paused.emit(opened)
			Layer.INGAME_MENU:
				SignalBus.ingame_paused.emit(opened)
