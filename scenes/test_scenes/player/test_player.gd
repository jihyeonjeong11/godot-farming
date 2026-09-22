extends AnimatedSprite2D

const TOOL_KEYS := {KEY_1: "axe", KEY_2: "pickaxe", KEY_3: "hoe", KEY_4: "watering_can", KEY_5: "sickle", KEY_6: "pistol"}

@export var speed := 60.0

@onready var tool_layer: Sprite2D = $Tool
@onready var hands_layer: Sprite2D = $Hands

var facing := "down"
var acting := false


func _ready() -> void:
	animation_finished.connect(_on_animation_finished)
	frame_changed.connect(_on_frame_changed)
	animation_changed.connect(_on_frame_changed)


func _process(delta: float) -> void:
	tool_layer.aim_at(get_global_mouse_position())
	if acting:
		return
	var dir := Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	if dir == Vector2.ZERO:
		play("idle_" + facing)
		return
	position += dir * speed * delta
	if absf(dir.x) > absf(dir.y):
		facing = "right" if dir.x > 0 else "side"
	else:
		facing = "down" if dir.y > 0 else "up"
	play("walk_" + facing)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and TOOL_KEYS.has(key.keycode):
		tool_layer.set_tool(TOOL_KEYS[key.keycode])
		hands_layer.held = tool_layer.is_held()
		_on_frame_changed()
		return
	if acting:
		return
	var mb := event as InputEventMouseButton
	var click := mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	if click or event.is_action_pressed("hit"):
		acting = true
		play(_action_anim())
		_on_frame_changed()


func _on_animation_finished() -> void:
	if not acting:
		return
	acting = false
	play("idle_" + facing)
	_on_frame_changed()


func _on_frame_changed() -> void:
	for layer in get_children():
		if layer.has_method("sync"):
			layer.sync(animation, frame)


func _action_anim() -> StringName:
	var act: String = tool_layer.act()
	return StringName(act if facing == "side" else act + "_" + facing)
