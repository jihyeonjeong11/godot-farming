extends Node

var current_scene: DataTypes.Levels


func should_hide_ui() -> bool:
	match current_scene:
		DataTypes.Levels.Tutorial:
			return true
	return false
