extends Sprite2D

# 8 cells: 0 side_idle 1 side_stepA 2 side_stepB 3 side_crouch 4 down_idle 5 down_step 6 up_idle 7 up_step
const CELLS := 8
const CELL_H := 48
const IDLE := {"side": 0, "down": 4, "up": 6, "right": 0}
const STEP := {"side": [1, 2], "down": [5, 5], "up": [7, 7], "right": [1, 2]}
# body sheet column -> (cell, flip, dx); anything not listed uses the idle cell
const COL_POSE := {
	"side": {4: [1, false, 0], 6: [2, false, 0], 10: [0, false, 1], 13: [3, false, 0], 14: [3, false, 0]},
	"down": {4: [5, false, 0], 6: [5, true, -1]},
	"up": {4: [7, false, 0], 6: [7, true, -1]},
}
const ANIM_COLS := {
	"idle": [0, 1, 2, 3],
	"walk": [4, 5, 6, 7],
	"swing": [11, 12, 13, 14, 11],
	"water": [15, 16],
	"sickle": [17, 18, 19],
}

@export var variant := 0:
	set(v):
		variant = v
		frame = variant * hframes + frame % hframes

var _base := Vector2.ZERO


func _ready() -> void:
	hframes = CELLS
	vframes = maxi(1, texture.get_height() / CELL_H) if texture else 1
	_base = position


func sync(anim: StringName, frame_i: int) -> void:
	var parts := String(anim).split("_")
	var act := parts[0]
	var dir := parts[1] if parts.size() > 1 else "side"
	if not ANIM_COLS.has(act) or not IDLE.has(dir):
		return
	var cols: Array = ANIM_COLS[act]
	var col: int = cols[mini(frame_i, cols.size() - 1)]
	var mirrored := dir == "right"
	var key := "side" if mirrored else dir
	var pose: Array = COL_POSE[key].get(col, [IDLE[key], false, 0])
	var cell: int = pose[0]
	var flip: bool = pose[1]
	var dx: int = pose[2]
	if mirrored:
		flip = not flip
		dx = -dx
	frame = variant * hframes + cell
	flip_h = flip
	position = _base + Vector2(dx, 0)
