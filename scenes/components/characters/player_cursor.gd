extends Node

@onready var player: Player = $"../Level/Player"
var player_interaction_range = 60


func _physics_process(_delta: float) -> void:
	if get_tree().paused:
		return

	if GameInputEvents.use_tool():
		on_left_click()

	if GameInputEvents.interact():
		on_right_click()


func on_left_click() -> void:
	print(111)
	# require which cell is targeted
	# if holding weapons, just fire and end
	# if holding tool, request if cell is tool_usable
	# if holding placeables, install placeable to target cell
	# plant seed / reload / mineRock -> remove crops and tilledsoil
	# later we can add some add ingredient action: furnace -> scrap_irons

	pass


func on_right_click() -> void:
	print(222)
	# require which cell is targeted
	# if interactable, interact
	# elseif grown crops, harvest
	# elseif holding consumable, consume
	# else do nothing

	pass
