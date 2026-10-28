extends CharacterBody2D

const PART_KEYS := {KEY_1: "Hair", KEY_2: "Shirt", KEY_3: "Pants", KEY_4: "Shoes", KEY_5: "Bag"}
const ROW_NAMES := ["left", "down", "up", "right"]
const ROWS := {Vector2.LEFT: 0, Vector2.DOWN: 1, Vector2.UP: 2, Vector2.RIGHT: 3}

@export var speed := 60.0

@onready var body: AnimatedSprite2D = $Body

var facing := Vector2.DOWN
var busy := false
var outfit := {}
var _saved_outfit := {}


func _ready() -> void:
	for part in PART_KEYS.values():
		outfit[part] = 0
	body.animation_finished.connect(func() -> void: busy = false)
	body.frame_changed.connect(_sync)
	body.animation_changed.connect(_sync)
	_play("idle")


func variant_count(part: String) -> int:
	return (body.get_node(part) as Sprite2D).variant_count()


func describe() -> String:
	var parts := PackedStringArray()
	for key in PART_KEYS:
		var part: String = PART_KEYS[key]
		var v: int = outfit[part]
		parts.append("%s %s" % [part.to_lower(), "없음" if v < 0 else "%d/%d" % [v + 1, variant_count(part)]])
	return "  ".join(parts)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode in PART_KEYS:
		var part: String = PART_KEYS[event.keycode]
		var next: int = outfit[part] + 1
		_wear(part, -1 if next >= variant_count(part) else next)
	elif event.keycode == KEY_0:
		if _saved_outfit.is_empty():
			_saved_outfit = outfit.duplicate()
			for part in PART_KEYS.values():
				_wear(part, -1)
		else:
			for part in _saved_outfit:
				_wear(part, _saved_outfit[part])
			_saved_outfit = {}
	else:
		return
	get_viewport().set_input_as_handled()


func _wear(part: String, variant: int) -> void:
	outfit[part] = variant
	var layer: Sprite2D = body.get_node(part)
	layer.visible = variant >= 0
	if variant >= 0:
		layer.variant = variant
	_sync()


func _sync() -> void:
	for layer in body.get_children():
		if layer.has_method("sync"):
			layer.sync(body.animation, body.frame)


func _physics_process(_delta: float) -> void:
	if busy:
		return
	if Input.is_action_just_pressed("hit"):
		_start("swing")
		return
	if Input.is_action_just_pressed("interact") and facing.x != 0.0:
		_start("pickup")
		return
	var input := Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	if input != Vector2.ZERO:
		if absf(input.x) >= absf(input.y):
			facing = Vector2.RIGHT if input.x > 0.0 else Vector2.LEFT
		else:
			facing = Vector2.DOWN if input.y > 0.0 else Vector2.UP
	velocity = input * speed
	move_and_slide()
	_play("walk" if input != Vector2.ZERO else "idle")


func _start(act: String) -> void:
	busy = true
	velocity = Vector2.ZERO
	_play(act)


func _play(act: String) -> void:
	var anim := StringName("%s_%s" % [act, ROW_NAMES[ROWS.get(facing, 1)]])
	if body.animation != anim or not body.is_playing():
		body.play(anim)
