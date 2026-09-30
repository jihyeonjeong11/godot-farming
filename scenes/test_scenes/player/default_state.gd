extends NodeState

@export var player: Player

var is_playing = false


func _ready() -> void:
	player.body.animation_finished.connect(_on_animation_finished)


func _on_enter() -> void:
	is_playing = false
	player.play_action("idle")


func _on_physics_process(_delta: float) -> void:
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
		player.play_action("idle")
		return
	player.face(input)
	player.velocity = input * player.speed
	player.move_and_slide()
	player.play_action("walk")


func _on_animation_finished() -> void:
	if not is_playing:
		return
	is_playing = false
	player.play_action("idle")
