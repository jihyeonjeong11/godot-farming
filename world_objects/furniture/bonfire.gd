@tool
extends WorldObject

@export var is_lit: bool = true

@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	super()
	_apply_lit()

func on_interact() -> void:
	is_lit = not is_lit
	_apply_lit()

func _apply_lit() -> void:
	anim.play(&"on" if is_lit else &"off")
