@tool
extends WorldObject

@onready var anim: AnimationPlayer = $AnimationPlayer

func default_state() -> Dictionary:
	return {"is_on": true}

func _ready() -> void:
	super()
	_apply_lit()

func on_interact() -> void:
	state.is_on = not state.is_on
	_apply_lit()

func _apply_lit() -> void:
	anim.play(&"on" if state.is_on else &"off")
