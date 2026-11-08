extends NodeState

@export var player: Player

#@onready var player_buff_component: PlayerBuffComponent = $"../../PlayerBuffComponent"

const FOOTSTEP_INTERVAL := 0.42
const MELEE_SWING_TIME := 0.22
const FOOTSTEP = preload("uid://bhcyvr82bqnal")
const FOOTSTEP_GRASS = preload("uid://d2ytgjedd650g")
const FOOTSTEP_CONCRETE = preload("uid://igeuw168phye")
const FOOTSTEP_BY_TERRAIN := {
	"Grass": FOOTSTEP_GRASS,
	"Concrete": FOOTSTEP_CONCRETE,
	"Asphalt": FOOTSTEP_CONCRETE,
}

var is_playing = false
var _meleeing := false
var _footstep_timer := 0.0
var _footstep_stream: AudioStream


func _ready() -> void:
	player.body.animation_finished.connect(_on_animation_finished)


func _on_enter() -> void:
	is_playing = false
	_footstep_timer = 0.0
	player.play_action("idle")

func _on_physics_process(delta: float) -> void:
	if SessionState.cinematic_stack_size > 0:
		player.velocity = Vector2.ZERO
		_stop_footstep()
		player.play_action("idle")
		return
	if is_playing:
		return
	if player.is_freeze:
		player.velocity = Vector2.ZERO
		_stop_footstep()
		player.play_action("idle")
		return
	if Input.is_action_just_pressed("hit") and get_viewport().gui_get_hovered_control() == null:
		var itemstack := InventoryManager.get_item_stack_by_index(GameState.selected_slot)
		var item = itemstack.item if itemstack != null else null
		if item != null and item.item_type == DataTypes.ItemType.Melee:
			if player.stats.stamina > 15:
				SessionState.cursor_freeze = true
				is_playing = true
				_meleeing = true
				player.stats.stamina -= 15
				player.play_action("swing")
				player.body.speed_scale = player.action_length() / MELEE_SWING_TIME * item.melee_speed
				player.begin_melee(item)
				return
		elif player.tool_layer.has_tool():
			SessionState.cursor_freeze = true
			is_playing = true
			player.play_action(player.tool_layer.act())
			return
	var input := Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	if input == Vector2.ZERO:
		player.velocity = Vector2.ZERO
		_footstep_timer = 0.0
		_stop_footstep()
		player.play_action("idle")
		return
	player.face(input)
	player.velocity = input * player.stats.current_speed
	player.move_and_slide()
	player.play_action("walk")
	_tick_footstep(delta)


func _tick_footstep(delta: float) -> void:
	_footstep_timer -= delta
	if _footstep_timer > 0.0:
		return
	_footstep_timer = FOOTSTEP_INTERVAL
	player.ground_type = player.get_terrain_type()
	_footstep_stream = FOOTSTEP_BY_TERRAIN.get(player.ground_type, FOOTSTEP)
	SoundManager.play_sound(_footstep_stream)


func _stop_footstep() -> void:
	if _footstep_stream == null:
		return
	SoundManager.stop_sound(_footstep_stream)
	_footstep_stream = null


func _on_animation_finished() -> void:
	if not is_playing:
		return
	is_playing = false
	player.body.speed_scale = 1.0
	player.play_action("idle")
	if _meleeing:
		_meleeing = false
		player.end_melee()
		SessionState.cursor_freeze = false
		return
	player.finish_tool_use()
	SessionState.cursor_freeze = false


func _on_exit() -> void:
	SessionState.cursor_freeze = false
	_stop_footstep()
	if _meleeing:
		_meleeing = false
		is_playing = false
		player.body.speed_scale = 1.0
		player.end_melee()
