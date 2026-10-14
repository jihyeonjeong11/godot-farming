extends Node

signal settings_reset()

const CONFIG_PATH := "user://config.cfg"
const MASTER_BUS := "Master"

const DEFAULT_MASTER_VOLUME := 100.0
const DEFAULT_WINDOW_MODE := "windowed"

const SAVE_DELAY := 0.4

var master_volume: float = DEFAULT_MASTER_VOLUME

var music_volume: float = 0.3:
	set(value):
		music_volume = value
		SoundManager.set_music_volume(music_volume)
	get:
		return music_volume

var sounds_volume: float = 0.5:
	set(value):
		sounds_volume = value
		SoundManager.set_sound_volume(sounds_volume)
	get:
		return sounds_volume

var ui_sounds_volume: float = 0.5:
	set(value):
		ui_sounds_volume = value
		SoundManager.set_ui_sound_volume(ui_sounds_volume)
	get:
		return ui_sounds_volume

var full_screen_is_on: bool:
	set(value):
		set_window_mode("fullscreen" if value else "windowed")
	get:
		return window_mode == "fullscreen"

var assist_menu_animations_is_on: bool = true

var window_mode: String = DEFAULT_WINDOW_MODE



var _config := ConfigFile.new()
var _save_timer: Timer


func _ready() -> void:
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = SAVE_DELAY
	_save_timer.timeout.connect(save_settings)
	add_child(_save_timer)

	load_settings()

func load_settings() -> void:
	var err := _config.load(CONFIG_PATH)
	if err != OK:
		apply_all()
		save_settings()
		return

	master_volume = float(_config.get_value("audio", "master_volume", DEFAULT_MASTER_VOLUME))
	music_volume = float(_config.get_value("audio", "music_volume", music_volume))
	sounds_volume = float(_config.get_value("audio", "sounds_volume", sounds_volume))
	ui_sounds_volume = float(_config.get_value("audio", "ui_sounds_volume", ui_sounds_volume))
	window_mode = String(_config.get_value("display", "mode", DEFAULT_WINDOW_MODE))
	apply_all()


func save_settings() -> void:
	_config.set_value("audio", "master_volume", master_volume)
	_config.set_value("audio", "music_volume", music_volume)
	_config.set_value("audio", "sounds_volume", sounds_volume)
	_config.set_value("audio", "ui_sounds_volume", ui_sounds_volume)
	_config.set_value("display", "mode", window_mode)

	var err := _config.save(CONFIG_PATH)
	if err != OK:
		push_error("설정을 저장하지 못했다: %s" % error_string(err))

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 100.0)
	apply_master_volume()
	_save_timer.start()


func set_window_mode(mode: String) -> void:
	window_mode = mode
	apply_window_mode()
	_save_timer.start()


func reset_all_settings() -> void:
	music_volume = 0.3
	sounds_volume = 0.5
	ui_sounds_volume = 0.5
	full_screen_is_on = false

	settings_reset.emit()


func apply_all() -> void:
	apply_master_volume()
	apply_window_mode()


func apply_master_volume() -> void:
	var bus := AudioServer.get_bus_index(MASTER_BUS)
	if bus < 0:
		return

	if master_volume <= 0.0:
		AudioServer.set_bus_mute(bus, true)
		return

	AudioServer.set_bus_mute(bus, false)
	AudioServer.set_bus_volume_db(bus, linear_to_db(master_volume / 100.0))


func apply_window_mode() -> void:
	if window_mode == "fullscreen":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func current_window_mode() -> String:
	var mode := DisplayServer.window_get_mode()
	var is_fullscreen := mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

	return "fullscreen" if is_fullscreen else "windowed"


func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_CLOSE_REQUEST and what != NOTIFICATION_EXIT_TREE:
		return

	if _save_timer != null and not _save_timer.is_stopped():
		_save_timer.stop()
		save_settings()
