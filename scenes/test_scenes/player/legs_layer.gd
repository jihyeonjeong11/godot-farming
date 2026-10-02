extends Sprite2D

# 14 cells: 0 side_idle 1 side_stepA 2 side_stepB 3 side_crouch 4 down_idle 5 down_step 6 up_idle 7 up_step 8-11 side_walk 12 down_half 13 up_half
const CELLS := 14
const CELL_H := 96
const IDLE := {"left": 0, "down": 4, "up": 6, "right": 0}
const STEP := {"left": [1, 2], "down": [5, 5], "up": [7, 7], "right": [1, 2]}
# body sheet column -> (cell, flip, dx); anything not listed uses the idle cell
const COL_POSE := {
	"left": {4: [8, false, 0], 5: [9, false, 0], 7: [10, false, 0], 20: [11, false, 0], 10: [0, false, 2], 13: [3, false, 0], 14: [3, false, 0]},
	"down": {4: [5, false, 0], 5: [12, false, 0], 7: [5, true, -2], 20: [12, true, -2]},
	"up": {4: [7, false, 0], 5: [13, false, 0], 7: [7, true, -2], 20: [13, true, -2]},
}
const ANIM_COLS := {
	"idle": [0, 1, 2, 3],
	"walk": [4, 5, 6, 7, 20, 21],
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
	var dir := parts[1] if parts.size() > 1 else "left"
	if not ANIM_COLS.has(act) or not IDLE.has(dir):
		return
	var cols: Array = ANIM_COLS[act]
	var col: int = cols[mini(frame_i, cols.size() - 1)]
	var mirrored := dir == "right"
	var key := "left" if mirrored else dir
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
