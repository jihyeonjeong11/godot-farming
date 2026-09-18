@tool
extends CharacterBody2D

const SHEET_DIR := "res://assets/temp/sdv_ref/"
const BODY_ORIGIN := Vector2(-8, -32)
const NAMES := {2: "down", 1: "right", 0: "up"}

const FEATURE_Y := [
	1, 2, 2, 0, 5, 6, 1, 2, 2, 1, 0, 2, 0, 1, 1, 0, 2, 2, 3, 3,
	2, 2, 1, 1, 0, 0, 2, 2, 4, 4, 0, 0, 1, 2, 1, 1, 1, 1, 0, 0,
	1, 1, 1, 0, 0, -2, -1, 1, 1, 0, -1, -2, -1, -1, 5, 4, 0, 0, 3, 2,
	-1, 0, 4, 2, 0, 0, 2, 1, 0, -1, 1, -2, 0, 0, 1, 1, 1, 1, 1, 1,
	0, 0, 0, 0, 1, -1, -1, -1, -1, 1, 1, 0, 0, 0, 0, 4, 1, 0, 1, 2,
	1, 0, 1, 0, 1, 2, -3, -4, -1, 0, 0, 2, 1, -4, -1, 0, 0, -3, 0, 0,
	-1, 0, 0, 2, 1, 1,
]

const IDLE_FRAME := {2: 0, 1: 6, 0: 12}
const WALK_FRAMES := {2: [1, 0, 2, 0], 1: [7, 6, 8, 6], 0: [13, 12, 14, 12]}
const SHIRT_ROW := {2: 0, 1: 8, 0: 24}
const HAIR_ROW := {2: 0, 1: 32, 0: 64}

const TOOL_SWING := {
	2: [
		{f = 66, ms = 150, d = 0, p = Vector2(-5, -5), o = Vector2(0, 16), r = 0.0},
		{f = 67, ms = 40, d = 0, p = Vector2(-3, 0), o = Vector2(0, 16), r = -PI / 24},
		{f = 68, ms = 40, d = 1, p = Vector2(0, 8), o = Vector2(0, 16), r = 0.0},
		{f = 69, ms = 170, d = 1, p = Vector2(0, 19), o = Vector2(0, 16), r = 0.0},
		{f = 70, ms = 75, d = 1, p = Vector2(0, 20), o = Vector2(0, 16), r = 0.0},
	],
	1: [
		{f = 48, ms = 100, d = 2, p = Vector2(-9, -2), o = Vector2(0, 16), r = -PI / 12},
		{f = 49, ms = 40, d = 2, p = Vector2(2, 9), o = Vector2(0, 32), r = PI / 12},
		{f = 50, ms = 40, d = 2, p = Vector2(7, 7), o = Vector2(0, 32), r = PI / 4},
		{f = 51, ms = 220, d = 2, p = Vector2(15, 8), o = Vector2(0, 32), r = PI * 7 / 12},
		{f = 52, ms = 75, d = 2, p = Vector2(15, 9), o = Vector2(0, 32), r = PI * 7 / 12},
	],
	0: [
		{f = 36, ms = 100, d = 3, p = Vector2(0, -10), o = Vector2(0, 16), r = 0.0},
		{f = 37, ms = 40, d = 4, p = Vector2(1, 2), o = Vector2(0, 16), r = 0.0},
		{f = 38, ms = 40, d = 4, p = Vector2(0, 8), o = Vector2(0, 16), r = 0.0},
		{f = 63, ms = 220, d = 4, hide = true},
		{f = 62, ms = 75, d = 4, hide = true},
	],
}

const Z_BODY := 0
const Z_PANTS := 1
const Z_SHIRT := 2
const Z_SHIRT_DYE := 3
const Z_ARM_UP := 4
const Z_HAIR := 5
const Z_ARM := 6
const Z_TOOL_FRONT := 7
const Z_TOOL_BACK := -1

@export var speed := 60.0
@export var tool_index := 21:
	set(v):
		tool_index = v
		if is_inside_tree():
			_build_animations()
			_refresh_pose()
@export var shirt_index := 8:
	set(v):
		shirt_index = v
		if is_inside_tree():
			_apply_look()
@export var hair_index := 0:
	set(v):
		hair_index = v
		if is_inside_tree():
			_apply_look()
@export var pants_index := 0:
	set(v):
		pants_index = v
		if is_inside_tree():
			_apply_look()
@export var shirt_color := Color.WHITE:
	set(v):
		shirt_color = v
		if is_inside_tree():
			_apply_look()
@export var pants_color := Color(0.31, 0.39, 0.67):
	set(v):
		pants_color = v
		if is_inside_tree():
			_apply_look()
@export var hair_color := Color(0.82, 0.55, 0.24):
	set(v):
		hair_color = v
		if is_inside_tree():
			_apply_look()

@onready var rig: Node2D = $Rig
@onready var body: Sprite2D = $Rig/Body
@onready var pants: Sprite2D = $Rig/Pants
@onready var shirt: Sprite2D = $Rig/Shirt
@onready var shirt_dye: Sprite2D = $Rig/ShirtDye
@onready var hair: Sprite2D = $Rig/Hair
@onready var arm: Sprite2D = $Rig/Arm
@onready var tool_sprite: Sprite2D = $Rig/Tool
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var facing := 2
var swinging := false
var _sheets := {}


func _ready() -> void:
	for n in ["farmer_base", "pants", "shirts", "hairstyles", "tools"]:
		_sheets[n] = load(SHEET_DIR + n + ".png")
	body.texture = _sheets.farmer_base
	arm.texture = _sheets.farmer_base
	pants.texture = _sheets.pants
	shirt.texture = _sheets.shirts
	shirt_dye.texture = _sheets.shirts
	hair.texture = _sheets.hairstyles
	tool_sprite.texture = _sheets.tools
	_apply_look()
	_play("idle")


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or swinging:
		return
	var dir := Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	velocity = dir * speed
	move_and_slide()
	if dir != Vector2.ZERO:
		if absf(dir.x) > absf(dir.y):
			facing = 1 if dir.x > 0 else 3
		else:
			facing = 2 if dir.y > 0 else 0
		_play("walk")
	else:
		_play("idle")
	if Input.is_action_just_pressed("hit") or Input.is_key_pressed(KEY_SPACE):
		swing()


func _unhandled_key_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return
	match (event as InputEventKey).keycode:
		KEY_T:
			var tools := [21, 105, 189]
			tool_index = tools[(tools.find(tool_index) + 1) % tools.size()]
		KEY_H:
			hair_index = (hair_index + 1) % 56
		KEY_C:
			shirt_index = (shirt_index + 1) % 112
		KEY_P:
			pants_index = (pants_index + 1) % 20


func swing() -> void:
	if swinging:
		return
	swinging = true
	velocity = Vector2.ZERO
	_play("hoe")
	await anim_player.animation_finished
	swinging = false
	_play("idle")


func _play(base: String) -> void:
	var f := 1 if facing == 3 else facing
	rig.scale.x = -1.0 if facing == 3 else 1.0
	var name := "%s_%s" % [base, NAMES[f]]
	if anim_player.current_animation != name:
		anim_player.play(name)


func _refresh_pose() -> void:
	var cur := anim_player.current_animation
	if cur != "":
		var pos := anim_player.current_animation_position
		anim_player.play(cur)
		anim_player.seek(pos, true)


@warning_ignore("integer_division")
func _apply_look() -> void:
	pants.modulate = pants_color
	hair.modulate = hair_color
	shirt_dye.modulate = shirt_color
	var base_img: Image = _sheets.farmer_base.get_image()
	var shirt_img: Image = _sheets.shirts.get_image()
	var sx := shirt_index * 8 % 128
	var sy := shirt_index * 8 / 128 * 32
	var mat: ShaderMaterial = arm.material
	for i in 3:
		mat.set_shader_parameter("src%d" % i, base_img.get_pixel(256 + i, 0))
		var dye := shirt_img.get_pixel(sx + 128, sy + 4 - i)
		var dst := dye * shirt_color if dye.a >= 1.0 else shirt_img.get_pixel(sx, sy + 4 - i)
		mat.set_shader_parameter("dst%d" % i, dst)
	_build_animations()
	_refresh_pose()


func _build_animations() -> void:
	var lib := AnimationLibrary.new()
	for f in [2, 1, 0]:
		var idle := [{f = IDLE_FRAME[f], ms = 100}]
		var walk: Array = WALK_FRAMES[f].map(func(fr): return {f = fr, ms = 200})
		lib.add_animation("idle_%s" % NAMES[f], _make_anim(idle, f, true))
		lib.add_animation("walk_%s" % NAMES[f], _make_anim(walk, f, true))
		lib.add_animation("hoe_%s" % NAMES[f], _make_anim(TOOL_SWING[f], f, false))
	if anim_player.has_animation_library(""):
		anim_player.remove_animation_library("")
	anim_player.add_animation_library("", lib)


@warning_ignore("integer_division")
func _make_anim(frames: Array, f: int, loop: bool) -> Animation:
	var anim := Animation.new()
	var tracks := {}
	var t := 0.0
	var pants_x := pants_index % 10 * 192
	var pants_y := pants_index / 10 * 688
	var sx := shirt_index * 8 % 128
	var sy: int = shirt_index * 8 / 128 * 32 + SHIRT_ROW[f]
	var hx := hair_index * 16 % 128
	var hy: int = hair_index * 16 / 128 * 96 + HAIR_ROW[f]
	for fr in frames:
		var frame: int = fr.f
		var col := frame % 6
		var row := frame / 6
		var fy: int = FEATURE_Y[frame]
		var body_rect := Rect2(col * 16, row * 32, 16, 32)
		_key(anim, tracks, t, "Rig/Body:region_rect", body_rect)
		_key(anim, tracks, t, "Rig/Pants:region_rect", Rect2(pants_x + col * 16, pants_y + row * 32, 16, 32))
		_key(anim, tracks, t, "Rig/Shirt:region_rect", Rect2(sx, sy, 8, 8))
		_key(anim, tracks, t, "Rig/ShirtDye:region_rect", Rect2(sx + 128, sy, 8, 8))
		_key(anim, tracks, t, "Rig/Shirt:position", BODY_ORIGIN + Vector2(4, 14 + fy))
		_key(anim, tracks, t, "Rig/ShirtDye:position", BODY_ORIGIN + Vector2(4, 14 + fy))
		_key(anim, tracks, t, "Rig/Hair:region_rect", Rect2(hx, hy, 16, 32))
		_key(anim, tracks, t, "Rig/Hair:position", BODY_ORIGIN + Vector2(0, fy))
		_key(anim, tracks, t, "Rig/Arm:region_rect", Rect2((col + 6) * 16, row * 32, 16, 32))
		_key(anim, tracks, t, "Rig/Arm:z_index", Z_ARM_UP if f == 0 else Z_ARM)
		var show_tool: bool = fr.has("d") and not fr.get("hide", false)
		_key(anim, tracks, t, "Rig/Tool:visible", show_tool)
		if show_tool:
			var idx: int = tool_index + fr.d
			_key(anim, tracks, t, "Rig/Tool:region_rect", Rect2(idx * 16 % 336, idx * 16 / 336 * 16, 16, 32))
			_key(anim, tracks, t, "Rig/Tool:position", BODY_ORIGIN + fr.p)
			_key(anim, tracks, t, "Rig/Tool:offset", -fr.o)
			_key(anim, tracks, t, "Rig/Tool:rotation", fr.r)
			_key(anim, tracks, t, "Rig/Tool:z_index", Z_TOOL_BACK if f == 0 else Z_TOOL_FRONT)
		t += fr.ms / 1000.0
	anim.length = t
	anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	return anim


func _key(anim: Animation, tracks: Dictionary, t: float, path: String, value: Variant) -> void:
	if not tracks.has(path):
		var idx := anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(idx, NodePath(path))
		anim.value_track_set_update_mode(idx, Animation.UPDATE_DISCRETE)
		tracks[path] = idx
	anim.track_insert_key(tracks[path], t, value)
