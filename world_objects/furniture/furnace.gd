@tool
extends WorldObject

const FIRE_ON = preload("uid://cluwpcp6k6vrc")
const FIRE_OFF = preload("uid://by72sp3vkhet8")

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sounds: AudioStreamPlayer2D = $Sounds

func default_state() -> Dictionary:
	return {"is_on": false}

func _ready() -> void:
	super()
	_apply_lit()

func on_interact() -> void:
	state.is_on = not state.is_on
	sounds.stream = FIRE_ON if state.is_on else FIRE_OFF
	sounds.play()
	_apply_lit()

func _apply_lit() -> void:
	anim.play(&"on" if state.is_on else &"off")
