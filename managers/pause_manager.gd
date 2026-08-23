class_name GameStateManager
extends Node

enum Mode { MAIN_MENU, GAMEPLAY }
enum Layer { PAUSE_MENU, INGAME_MENU }

var _mode: Mode = Mode.MAIN_MENU
var _stack: Array[int] = []
var _announced: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SignalBus.ui_close_requested.connect(close)


func _shortcut_input(event: InputEvent) -> void:
	if _mode == Mode.MAIN_MENU:
		return

	if event.is_action_pressed("ingame_pause"):
		_toggle(Layer.INGAME_MENU)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("pause"):
		if _stack.is_empty():
			_push(Layer.PAUSE_MENU)
		else:
			_pop()
		get_viewport().set_input_as_handled()


func enter_main_menu() -> void:
	_mode = Mode.MAIN_MENU
	_stack.clear()
	_sync()


func enter_gameplay() -> void:
	_mode = Mode.GAMEPLAY
	_stack.clear()
	_sync()


func open(layer: Layer) -> void:
	if _stack.has(layer):
		return
	_push(layer)


func close(layer: Layer) -> void:
	if not _stack.has(layer):
		return
	_stack.erase(layer)
	_sync()


func close_all() -> void:
	if _stack.is_empty():
		return
	_stack.clear()
	_sync()


func is_paused() -> bool:
	return not _stack.is_empty()


func top() -> Variant:
	return _stack.back() if not _stack.is_empty() else null


func _toggle(layer: Layer) -> void:
	if _stack.has(layer):
		_stack.erase(layer)
	else:
		_stack.push_back(layer)
	_sync()


func _push(layer: Layer) -> void:
	_stack.push_back(layer)
	_sync()


func _pop() -> void:
	if _stack.is_empty():
		return
	_stack.pop_back()
	_sync()


func _sync() -> void:
	get_tree().paused = not _stack.is_empty()

	for layer in [Layer.PAUSE_MENU, Layer.INGAME_MENU]:
		var is_open := _stack.has(layer)
		if _announced.get(layer, false) == is_open:
			continue
		_announced[layer] = is_open

		match layer:
			Layer.PAUSE_MENU:
				SignalBus.game_paused.emit(is_open)
			Layer.INGAME_MENU:
				SignalBus.ingame_paused.emit(is_open)
