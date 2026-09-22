extends Sprite2D

const COLS := 20
const ROWS := {"side": 0, "down": 1, "up": 2, "right": 3}
const ANIM_COLS := {
	"idle": [0, 1, 2, 3],
	"walk": [4, 5, 6, 7],
	"swing": [11, 12, 13, 14, 11],
	"water": [15, 16],
	"sickle": [17, 18, 19],
	"shoot": [0, 0],
}
const ACTIONS := ["swing", "water", "sickle"]

@export var action_sheet: Texture2D
@export var held_sheet: Texture2D

var held := false


func _ready() -> void:
	hframes = COLS
	vframes = ROWS.size()


func sync(anim: StringName, frame_i: int) -> void:
	var parts := String(anim).split("_")
	var act := parts[0]
	var dir := parts[1] if parts.size() > 1 else "side"
	if not ANIM_COLS.has(act) or not ROWS.has(dir):
		return
	if act in ACTIONS and action_sheet:
		texture = action_sheet
		visible = true
	elif held and held_sheet:
		texture = held_sheet
		visible = true
	else:
		visible = false
		return
	var cols: Array = ANIM_COLS[act]
	frame = ROWS[dir] * COLS + cols[mini(frame_i, cols.size() - 1)]
