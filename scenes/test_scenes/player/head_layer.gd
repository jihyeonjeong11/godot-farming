extends Sprite2D

const COLS := 20
const ROWS := {"side": 0, "down": 1, "up": 2, "right": 3}
const ANIM_COLS := {
	"idle": [0, 1, 2, 3],
	"walk": [4, 5, 6, 7],
	"swing": [11, 12, 13, 14, 11],
	"water": [15, 16],
	"sickle": [17, 18, 19],
}
const HEAD_OFFSET := [
	[Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(-1, 2), Vector2i(-1, 2), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0)],
	[Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 0), Vector2i.ZERO, Vector2i.ZERO, Vector2i.ZERO, Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 2), Vector2i(0, 1), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0)],
	[Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 0), Vector2i.ZERO, Vector2i.ZERO, Vector2i.ZERO, Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 2), Vector2i(0, 1), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0)],
	[Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 0), Vector2i.ZERO, Vector2i.ZERO, Vector2i.ZERO, Vector2i(0, 0), Vector2i(0, 0), Vector2i(1, 2), Vector2i(1, 2), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0)],
]

const TORSO_OFFSET := [
	[Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(-1, 2), Vector2i(-1, 2), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0)],
	[Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0)],
	[Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0)],
	[Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(-1, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(1, 2), Vector2i(1, 2), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0)],
]

@export var torso := false

var _base := Vector2.ZERO


func _ready() -> void:
	hframes = 4
	vframes = 1
	_base = position


func sync(anim: StringName, frame_i: int) -> void:
	var parts := String(anim).split("_")
	var act := parts[0]
	var dir := parts[1] if parts.size() > 1 else "side"
	if not ANIM_COLS.has(act) or not ROWS.has(dir):
		return
	var row: int = ROWS[dir]
	var cols: Array = ANIM_COLS[act]
	var col: int = cols[mini(frame_i, cols.size() - 1)]
	frame = row
	var off: Vector2i = (TORSO_OFFSET if torso else HEAD_OFFSET)[row][col]
	position = _base + Vector2(off)
