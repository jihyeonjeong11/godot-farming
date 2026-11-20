class_name CraftingMenu
extends CanvasLayer

@onready var panel := %CraftingsPanel


func _ready() -> void:
	SignalBus.pause_game()


func setup(recipe_type: DataTypes.RecipeType) -> void:
	panel.recipe_type = recipe_type
	panel.refresh_recipes()


func close() -> void:
	SignalBus.pause_game(false)
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ingame_pause"):
		get_viewport().set_input_as_handled()
		close()
