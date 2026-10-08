extends Sprite2D

const TOOLS := preload("res://assets/temp/sdv_ref/tools.png")
const SICKLE := preload("res://assets/temp/sickle.png")
const PISTOL := preload("res://assets/Objects/items/pistol.png")

const DEFS := {
	"axe": {y = 144, h = 32, act = "swing"},
	"pickaxe": {y = 80, h = 32, act = "swing"},
	"hoe": {y = 16, h = 32, act = "swing"},
	"watering_can": {y = 224, h = 16, act = "water"},
	"sickle": {y = 0, h = 16, act = "sickle", tex = SICKLE},
	"pistol": {y = 0, h = 32, w = 32, act = "shoot", tex = PISTOL, held = true, aimed = true, scale = 0.5, flip = true},
}
const HELD_ANIMS := ["idle", "walk"]
const PX := 1
const ORIGIN := Vector2(16, 23)

const POSE := {
	&"swing_left": [
		{d = 2, p = Vector2(10, 25), o = Vector2(8, 29), r = 60, z = -1, flip = false},
		{d = 2, p = Vector2(17, 7), o = Vector2(8, 24), r = 25, z = -1, flip = false},
		{d = 2, p = Vector2(7, 31), o = Vector2(8, 22), r = -135, z = 1, flip = false},
		{d = 2, p = Vector2(7, 32), o = Vector2(8, 22), r = -140, z = 1, flip = false},
	],
	&"swing_right": [
		{d = 2, p = Vector2(22, 25), o = Vector2(8, 29), r = -60, z = -1, flip = true},
		{d = 2, p = Vector2(15, 7), o = Vector2(8, 24), r = -25, z = -1, flip = true},
		{d = 2, p = Vector2(25, 31), o = Vector2(8, 22), r = 135, z = 1, flip = true},
		{d = 2, p = Vector2(25, 32), o = Vector2(8, 22), r = 140, z = 1, flip = true},
	],
	&"swing_down": [
		{d = 0, p = Vector2(15, 12), o = Vector2(8, 26), r = 0, z = -1, flip = false},
		{d = 0, p = Vector2(15, 6), o = Vector2(8, 26), r = -10, z = -1, flip = false},
		{d = 3, p = Vector2(15, 26), o = Vector2(8, 6), r = 0, z = 1, flip = false},
		{d = 3, p = Vector2(15, 30), o = Vector2(8, 10), r = 0, z = 1, flip = false},
		{d = 0, p = Vector2(10, 26), o = Vector2(8, 26), r = 0, z = -1, flip = false},
	],
	&"swing_up": [
		{d = 4, p = Vector2(20, 26), o = Vector2(8, 26), r = 0, z = -1, flip = false},
		{d = 4, p = Vector2(19, 24), o = Vector2(8, 26), r = 10, z = -1, flip = false},
		{d = 2, p = Vector2(21, 30), o = Vector2(8, 20), r = 135, z = -1, flip = false},
		{d = 2, p = Vector2(22, 32), o = Vector2(8, 20), r = 140, z = -1, flip = false},
		{d = 4, p = Vector2(20, 26), o = Vector2(8, 26), r = 0, z = -1, flip = false},
	],
	&"water_left": [
		{d = 2, p = Vector2(9, 27), o = Vector2(8, 3), r = 0, z = 1, flip = true},
		{d = 3, p = Vector2(9, 23), o = Vector2(8, 3), r = 0, z = 1, flip = true},
	],
	&"water_right": [
		{d = 2, p = Vector2(23, 27), o = Vector2(8, 3), r = 0, z = 1, flip = false},
		{d = 3, p = Vector2(23, 23), o = Vector2(8, 3), r = 0, z = 1, flip = false},
	],
	&"water_down": [
		{d = 0, p = Vector2(15, 28), o = Vector2(8, 3), r = 0, z = 1, flip = false},
		{d = 1, p = Vector2(15, 24), o = Vector2(8, 2), r = 0, z = 1, flip = false},
	],
	&"water_up": [
		{d = 4, p = Vector2(15, 26), o = Vector2(8, 3), r = 0, z = -1, flip = false},
		{d = 4, p = Vector2(15, 17), o = Vector2(8, 3), r = 0, z = -1, flip = false},
	],
	&"sickle_left": [
		{d = 0, p = Vector2(21, 25), o = Vector2(4, 13), r = 45, z = -1, flip = true},
		{d = 0, p = Vector2(9, 26), o = Vector2(12, 13), r = -45, z = 1, flip = false},
		{d = 0, p = Vector2(6, 27), o = Vector2(12, 13), r = -60, z = 1, flip = false},
	],
	&"sickle_right": [
		{d = 0, p = Vector2(11, 25), o = Vector2(12, 13), r = -45, z = -1, flip = false},
		{d = 0, p = Vector2(23, 26), o = Vector2(4, 13), r = 45, z = 1, flip = true},
		{d = 0, p = Vector2(26, 27), o = Vector2(4, 13), r = 60, z = 1, flip = true},
	],
	&"sickle_down": [
		{d = 0, p = Vector2(9, 26), o = Vector2(12, 13), r = -60, z = 1, flip = false},
		{d = 0, p = Vector2(15, 27), o = Vector2(12, 13), r = -150, z = 1, flip = false},
		{d = 0, p = Vector2(21, 26), o = Vector2(4, 13), r = 60, z = 1, flip = true},
	],
	&"sickle_up": [
		{d = 0, p = Vector2(21, 26), o = Vector2(4, 13), r = 45, z = -1, flip = true},
		{d = 0, p = Vector2(15, 30), o = Vector2(12, 13), r = 0, z = -1, flip = false},
		{d = 0, p = Vector2(9, 26), o = Vector2(12, 13), r = -45, z = -1, flip = false},
	],
	&"hold_left": [
		{d = 0, p = Vector2(9, 23), o = Vector2(9, 21), r = 0, z = 1, flip = false, muzzle = Vector2(30, 13), recoil = 0},
	],
	&"shoot_left": [
		{d = 0, p = Vector2(9, 23), o = Vector2(9, 21), r = 0, z = 1, flip = false, muzzle = Vector2(30, 13), recoil = 1},
		{d = 0, p = Vector2(9, 23), o = Vector2(9, 21), r = 0, z = 1, flip = false, muzzle = Vector2(30, 13), recoil = 0},
	],
	&"hold_right": [
		{d = 0, p = Vector2(23, 23), o = Vector2(9, 21), r = 0, z = 1, flip = false, muzzle = Vector2(30, 13), recoil = 0},
	],
	&"shoot_right": [
		{d = 0, p = Vector2(23, 23), o = Vector2(9, 21), r = 0, z = 1, flip = false, muzzle = Vector2(30, 13), recoil = 1},
		{d = 0, p = Vector2(23, 23), o = Vector2(9, 21), r = 0, z = 1, flip = false, muzzle = Vector2(30, 13), recoil = 0},
	],
	&"hold_down": [
		{d = 0, p = Vector2(15, 25), o = Vector2(9, 21), r = 0, z = 1, flip = false, muzzle = Vector2(30, 13), recoil = 0},
	],
	&"shoot_down": [
		{d = 0, p = Vector2(15, 25), o = Vector2(9, 21), r = 0, z = 1, flip = false, muzzle = Vector2(30, 13), recoil = 1},
		{d = 0, p = Vector2(15, 25), o = Vector2(9, 21), r = 0, z = 1, flip = false, muzzle = Vector2(30, 13), recoil = 0},
	],
	&"hold_up": [
		{d = 0, p = Vector2(20, 25), o = Vector2(9, 21), r = 0, z = -1, flip = false, muzzle = Vector2(30, 13), recoil = 0},
	],
	&"shoot_up": [
		{d = 0, p = Vector2(20, 25), o = Vector2(9, 21), r = 0, z = -1, flip = false, muzzle = Vector2(30, 13), recoil = 1},
		{d = 0, p = Vector2(20, 25), o = Vector2(9, 21), r = 0, z = -1, flip = false, muzzle = Vector2(30, 13), recoil = 0},
	],
}

var tool_name := ""
var _anim: StringName = &""
var _frame := 0
var _muzzle := Vector2.ZERO
var _aim := Vector2.RIGHT
var _recoil := 0
var _base_pos := Vector2.ZERO
var _rest_index := -1


func set_tool(name: String) -> void:
	tool_name = name if DEFS.has(name) else ""
	sync(_anim, _frame)


func has_tool() -> bool:
	return DEFS.has(tool_name)


func act() -> String:
	return DEFS[tool_name].act if has_tool() else ""


func is_held() -> bool:
	return DEFS.get(tool_name, {}).get("held", false)


func is_aimed() -> bool:
	return DEFS.get(tool_name, {}).get("aimed", false)


func aim_at(target: Vector2) -> void:
	if not is_aimed():
		return
	_aim = (target - global_position).normalized()
	rotation = _aim.angle()
	flip_v = absf(rotation) > PI / 2
	_apply_recoil()


func muzzle_global() -> Vector2:
	var m := _muzzle
	if flip_v:
		m.y = region_rect.size.y - 1 - m.y
	return to_global(offset + m)


func _apply_recoil() -> void:
	position = _base_pos - _aim * _recoil * PX


func sync(anim: StringName, frame: int) -> void:
	_anim = anim
	_frame = frame
	if not has_tool():
		visible = false
		return
	var def: Dictionary = DEFS[tool_name]
	var key := anim
	if def.get("held", false) and String(anim).split("_")[0] in HELD_ANIMS:
		var parts := String(anim).split("_")
		var dir := parts[1] if parts.size() > 1 else "left"
		key = StringName("hold_" + dir)
		frame = 0
	if not POSE.has(key) or frame >= POSE[key].size():
		visible = false
		return
	var pose: Dictionary = POSE[key][frame]
	_muzzle = pose.get("muzzle", Vector2.ZERO)
	_recoil = pose.get("recoil", 0)
	var d: int = pose.d
	var flip: bool = pose.flip
	if def.act == "swing" and tool_name != "pickaxe":
		if d == 3:
			d = 1
		elif d == 2 and anim != &"swing_up":
			flip = not flip
	visible = true
	texture = def.get("tex", TOOLS)
	var w: int = def.get("w", 16)
	region_rect = Rect2(d * w, def.y, w, def.h)
	flip_h = flip != def.get("flip", false)
	scale = Vector2.ONE * def.get("scale", 1.0) * PX
	_base_pos = (pose.p - ORIGIN) * PX
	position = _base_pos
	offset = -pose.o
	var body := get_parent()
	if _rest_index < 0:
		_rest_index = get_index()
	body.move_child(self, body.get_child_count() - 1 if pose.z > 0 else _rest_index)
	show_behind_parent = pose.z < 0
	if is_aimed():
		_apply_recoil()
	else:
		rotation_degrees = pose.r
		flip_v = false
