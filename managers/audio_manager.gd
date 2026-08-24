class_name AudioManager
extends Node

const MUSIC_MAIN_MENU = preload("uid://d0tck7y58df7h")

const MUSIC_INGAME := [
	preload("uid://dnguc31xgki31"),  # Ain_t that a kick in the head.mp3
	preload("uid://oefnqb6itinp"),  # Big Iron.mp3
	preload("uid://0qqwitqwb8kj"),  # Hallo Mister X.mp3
]

@onready var music: AudioStreamPlayer = $Music

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SignalBus.game_state_changed.connect(on_change_game_state)
	music.finished.connect(on_music_finished)

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
