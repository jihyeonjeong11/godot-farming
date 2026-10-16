extends Base_level

@export var title_scene: PackedScene
@export var logos_scene: PackedScene

@onready var camera_2d: Camera2D = $Camera2D
@onready var tile_map_layer: TileMapLayer = $TileMapLayer

@export var pan_delay: float = 1.0
@export var pan_duration: float = 6.0
@onready var player: Player = $Player

@onready var title: Node2D = $CanvasLayer/Title
@onready var canvas_layer: CanvasLayer = $CanvasLayer



#var _slot_mode: SaveSlots.Mode = SaveSlots.Mode.NEW
var _pending_slot := -1
var _pan_tween: Tween
var _pan_target: Vector2


func _ready() -> void:
	player.is_freeze = true


	if not SessionState.has_seen_logos:
		var logos = logos_scene.instantiate()
		canvas_layer.add_child(logos)
		await logos.finished
		logos.queue_free()
		SessionState.has_seen_logos = true
	_start_camera_pan()


func cue_title() -> void :
	title.global_position = Vector2(1920 * 0.5, 1080 * 0.2)
	title.appear()

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
	cue_title()



#func _on_slot_selected(slot: int) -> void:
	#if _slot_mode == SaveSlots.Mode.LOAD or SaveAndLoad.has_save(slot):
		#SignalBus.load_game_requested.emit(slot)
		#return
	#_pending_slot = slot



func _on_customization_confirmed() -> void:
	SignalBus.new_game_requested.emit(_pending_slot)
