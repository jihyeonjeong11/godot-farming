@tool
extends WorldObject

@onready var anim: AnimationPlayer = $AnimationPlayer

var state: Dictionary = {
	"is_on": true
}

func _ready() -> void:
	super()
	state = SnapshotActions.populate(global_position, data.id, state)
	_apply_lit()

func on_interact() -> void:
	state.is_on = not state.is_on
	_apply_lit()

func _apply_lit() -> void:
	anim.play(&"on" if state.is_on else &"off")
