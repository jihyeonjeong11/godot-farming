@tool
extends WorldObject


func on_interact() -> void:
	SignalBus.crafting_opened.emit(DataTypes.RecipeType.General)
