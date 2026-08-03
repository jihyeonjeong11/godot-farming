# Global game state (autoload). Owns pause state across scene changes.
extends Node


func _ready() -> void:
	# Autoloads inherit PAUSABLE from root by default, which would freeze this
	# node the moment we pause and make unpausing impossible.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	var paused = not get_tree().paused
	if event.is_action_pressed("pause"):
		toggle_pause(paused)
		get_viewport().set_input_as_handled()
		SignalBus.game_paused.emit(paused)

	if event.is_action_pressed("ingame_pause"):
		toggle_pause(paused)
		SignalBus.ingame_paused.emit(paused)


func toggle_pause(prev: bool) -> void:
	set_paused(prev)


func set_paused(value: bool) -> void:
	if get_tree().paused == value:
		return

	get_tree().paused = value
