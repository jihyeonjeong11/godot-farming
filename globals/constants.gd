const tile_size: int = 32
# 사실 이거 하나면 되지않나? 
const tile_reach_range: int = 32
# 이 두개 삭제하는게 나을듯?
const base_interaction_range: int = tile_size
const base_tool_use_range: int = tile_size

const base_place_range: int = tile_size * 2
# 이건 왜있지?
const tool_reach_tiles: int = 1

## 이것도 나중에 base로 바꾸고 버프나 이것저것으로 바꿀 수 있어야하ㅣㄹ듯?
const default_sell_multiplier: float = 0.1

# 이건 gameState로 가야함
const is_dev = true

# maybe need better way to store scene key
# 근데 튜토리얼 ui 숨기는 역할만이라면? 그냥 gameState에 플래그 하나만 있으면되긴함.
const SCENE_MAINMENU := "res://scenes/mainmenu.tscn"
const LEVEL_SCENES := {
	DataTypes.Levels.Farm: "res://scenes/levels/main_farm.tscn",
	DataTypes.Levels.RuinCity: "res://scenes/test_scenes/proc_gen_city_ruin.tscn",
	DataTypes.Levels.Tutorial: "res://scenes/levels/tutorial.tscn",
}
