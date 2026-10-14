## TODO: Savemanager 추가한다음에 abstract_class 추가 상속할
extends AbstractGameState

var current_scene: DataTypes.Levels = DataTypes.Levels.MainMenu
## TODO: 인벤토리와 버프는 딕셔너리 형태로 변환해야 세이브 가능하
var inventory: Array[ItemStack] = []
# 0 ~ 9
var selected_slot: int = 0
## TODO: 아직 계절이 없음
var current_weather: DataTypes.WeatherType = DataTypes.WeatherType.Sunny
var current_time : Dictionary = {
	"day": 0,
	"hour": 6,
	"minute": 0
}

var player_stat: BaseCharacterStats
var player_buffs: Array[StatBuff] = []
var level_data: Dictionary = {}



var did_skip_tutorial: bool = false
var did_kill_first_zombie: bool = false
