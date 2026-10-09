extends Node

var default_sell_multiplier: float = 0.1

var tile_size: int = 32

var base_interaction_range: int = tile_size
var base_tool_use_range: int = tile_size
var base_place_range: int = tile_size * 2

var tool_reach_tiles: int = 1
## TODO: 여기까지 constants로 바꿀것

var is_dev = true

const SCENE_MAINMENU := "res://scenes/mainmenu.tscn"
const LEVEL_SCENES := {
	DataTypes.Levels.Farm: "res://scenes/levels/main_farm.tscn",
	DataTypes.Levels.RuinCity: "res://scenes/test_scenes/proc_gen_city_ruin.tscn",
	DataTypes.Levels.Tutorial: "res://scenes/levels/tutorial.tscn",
}
