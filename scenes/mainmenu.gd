extends Control

@onready var play: Button = $CanvasLayer/Container/MarginContainer/VBoxContainer/Play
@onready var load_game: Button = $CanvasLayer/Container/MarginContainer/VBoxContainer/Load
@onready var settings: Button = $CanvasLayer/Container/MarginContainer/VBoxContainer/Settings
@onready var quit: Button = $CanvasLayer/Container/MarginContainer/VBoxContainer/Quit
@onready var menu_panel: PanelContainer = $CanvasLayer/Container
@onready var settings_panel: Control = $CanvasLayer/SettingsPanel
@onready var save_slots: SaveSlots = $CanvasLayer/SaveSlots

@onready var camera_2d: Camera2D = $Camera2D
@onready var tile_map_layer: TileMapLayer = $TileMapLayer

@export var pan_delay: float = 1.0
@export var pan_duration: float = 6.0

var _slot_mode: SaveSlots.Mode = SaveSlots.Mode.NEW
var _pan_tween: Tween
var _pan_target: Vector2


func _ready() -> void:
	menu_panel.visible = false
	settings_panel.visible = false
	save_slots.visible = false

	play.pressed.connect(_on_play_pressed)
	load_game.pressed.connect(_on_load_pressed)
	settings.pressed.connect(_on_settings_pressed)
	quit.pressed.connect(_on_quit_pressed)
	settings_panel.closed.connect(_on_settings_closed)
	save_slots.slot_selected.connect(_on_slot_selected)
	save_slots.closed.connect(_on_slots_closed)

	_start_camera_pan()


func _input(event: InputEvent) -> void:
	if _pan_tween == null:
		return
	if event is InputEventMouseButton and event.pressed:
		get_viewport().set_input_as_handled()
		_finish_camera_pan()


func _start_camera_pan() -> void:
	var used := tile_map_layer.get_used_rect()
	var tile_size := Vector2(tile_map_layer.tile_set.tile_size)
	var map_left_top := tile_map_layer.to_global(tile_map_layer.map_to_local(used.position) - tile_size / 2)
	var map_size := Vector2(used.size) * tile_size * tile_map_layer.global_scale
	var half_view := get_viewport_rect().size / camera_2d.zoom / 2

	var mid_y := map_left_top.y + map_size.y / 2
	var start := Vector2(map_left_top.x + half_view.x, mid_y)
	_pan_target = Vector2(map_left_top.x + map_size.x / 2, mid_y)

	camera_2d.global_position = start
	camera_2d.reset_smoothing()

	_pan_tween = create_tween()
	_pan_tween.tween_interval(pan_delay)
	_pan_tween.tween_property(camera_2d, "global_position", _pan_target, pan_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pan_tween.finished.connect(_finish_camera_pan)


func _finish_camera_pan() -> void:
	if _pan_tween == null:
		return
	_pan_tween.kill()
	_pan_tween = null
	camera_2d.global_position = _pan_target
	camera_2d.reset_smoothing()
	menu_panel.visible = true
	play.grab_focus()


func _on_play_pressed() -> void:
	_open_slots(SaveSlots.Mode.NEW)


func _on_load_pressed() -> void:
	_open_slots(SaveSlots.Mode.LOAD)


func _open_slots(mode: SaveSlots.Mode) -> void:
	_slot_mode = mode
	menu_panel.visible = false
	save_slots.open(mode)


## 슬롯이 정해져야 어느 폴더를 읽고 쓸지가 정해진다. 그래서 게임을 여는 신호에
## 슬롯 번호를 실어 보낸다.
func _on_slot_selected(slot: int) -> void:
	if _slot_mode == SaveSlots.Mode.LOAD:
		SignalBus.load_game_requested.emit(slot)
	else:
		SignalBus.new_game_requested.emit(slot)


func _on_slots_closed() -> void:
	menu_panel.visible = true
	play.grab_focus()


func _on_settings_pressed() -> void:
	menu_panel.visible = false
	settings_panel.open()


func _on_settings_closed() -> void:
	menu_panel.visible = true
	settings.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()
