extends Node

const CONFIG_PATH := "user://config.cfg"
const MASTER_BUS := "Master"

const DEFAULT_MASTER_VOLUME := 100.0
const DEFAULT_WINDOW_MODE := "windowed"

const SAVE_DELAY := 0.4

var master_volume: float = DEFAULT_MASTER_VOLUME
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
	window_mode = String(_config.get_value("display", "mode", DEFAULT_WINDOW_MODE))
	apply_all()


func save_settings() -> void:
	_config.set_value("audio", "master_volume", master_volume)
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
