class_name AudioManager
extends Node

const MUSIC_MAIN_MENU = preload("uid://d0tck7y58df7h")

const MUSIC_INGAME = [
	preload("uid://dnguc31xgki31"),  # Ain_t that a kick in the head.mp3
	preload("uid://oefnqb6itinp"),  # Big Iron.mp3
	preload("uid://0qqwitqwb8kj"),  # Hallo Mister X.mp3
]

## 효과음 키. 부르는 쪽이 문자열을 직접 치면 오타가 나도 조용히 넘어가므로
## 상수로 묶는다.
const SFX_TREE_SHAKING := "TREE_SHAKING"
const SFX_TREE_HITTING := "TREE_HITTING"
const SFX_EATING := "EATING"
const SFX_TILLING_GROUND := "TILLING_GROUND"
const SFX_WATERING_CROPS := "WATERING_CROPS"

const SOUND_EFFECTS := {
	SFX_TREE_SHAKING: preload("uid://cf5dkduwvar7f"),
	SFX_TREE_HITTING: preload("uid://dclgtskcouocj"),
	SFX_EATING: preload("uid://3ehkno4ns3if"),
	SFX_TILLING_GROUND: preload("uid://b5ll7oh7g02ah"),
	SFX_WATERING_CROPS: preload("uid://s3cy4shkem8o"),
}

const SFX_POOL_SIZE := 4

@onready var music: AudioStreamPlayer = $Music

var _sfx_players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SignalBus.game_state_changed.connect(on_change_game_state)
	SignalBus.sound_requested.connect(play_sound_effect)
	music.finished.connect(on_music_finished)
	_build_sfx_pool()


func _build_sfx_pool() -> void:
	for _i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_sfx_players.append(player)


func play_sound_effect(key: String) -> void:
	var stream: AudioStream = SOUND_EFFECTS.get(key)

	var player := _idle_sfx_player()
	if player == null:
		return

	player.stream = stream
	player.play()

func _idle_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player

	return null


func on_change_game_state(game_state: DataTypes.GameState) -> void:
	match game_state:
		DataTypes.GameState.MainMenu:
			play_music(MUSIC_MAIN_MENU)
		DataTypes.GameState.Game:
			play_next_ingame()


func on_music_finished() -> void:
	if music.stream in MUSIC_INGAME:
		play_next_ingame()

func play_music(stream: AudioStream) -> void:
	if music.stream == stream and music.playing:
		return

	music.stream = stream
	music.play()


func play_next_ingame() -> void:
	music.stream = _pick_next_ingame()
	music.play()

func _pick_next_ingame() -> AudioStream:
	if MUSIC_INGAME.size() <= 1:
		return MUSIC_INGAME[0]

	var candidates := MUSIC_INGAME.duplicate()
	candidates.erase(music.stream)
	return candidates.pick_random() as AudioStream


func stop_music() -> void:
	music.stop()
