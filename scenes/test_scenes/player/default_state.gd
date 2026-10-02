extends NodeState

@export var player: Player

const FOOTSTEP_INTERVAL := 0.42
const FOOTSTEP_BY_TERRAIN := {
	"Grass": AudioManager.SFX_FOOTSTEP_GRASS,
	"Concrete": AudioManager.SFX_FOOTSTEP_CONCRETE,
	"Asphalt": AudioManager.SFX_FOOTSTEP_CONCRETE,
}

var is_playing = false
var _footstep_timer := 0.0


func _ready() -> void:
	player.body.animation_finished.connect(_on_animation_finished)


func _on_enter() -> void:
	is_playing = false
	_footstep_timer = 0.0
	player.play_action("idle")


func _on_physics_process(delta: float) -> void:
	if is_playing:
		return
	if player.is_freeze:
		player.velocity = Vector2.ZERO
		player.play_action("idle")
		return
	if Input.is_action_just_pressed("hit") and get_viewport().gui_get_hovered_control() == null:
		is_playing = true
		player.play_action(player.tool_layer.act())
		return
	var input := Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	if input == Vector2.ZERO:
		player.velocity = Vector2.ZERO
		_footstep_timer = 0.0
		player.play_action("idle")
		return
	player.face(input)
	player.velocity = input * player.speed
	player.move_and_slide()
	player.play_action("walk")
	_tick_footstep(delta)


func _tick_footstep(delta: float) -> void:
	_footstep_timer -= delta
	if _footstep_timer > 0.0:
		return
	_footstep_timer = FOOTSTEP_INTERVAL
	player.ground_type = player.get_terrain_type()
	SignalBus.sound_requested.emit(FOOTSTEP_BY_TERRAIN.get(player.ground_type, AudioManager.SFX_FOOTSTEP))


func _on_animation_finished() -> void:
	if not is_playing:
		return
	is_playing = false
	player.play_action("idle")
