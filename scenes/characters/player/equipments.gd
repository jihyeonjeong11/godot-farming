extends AnimatedSprite2D

@onready var player: ApoPlayer = $".."



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print('ready')
	play("pistol_idle_front")
	pass # Replace with function body.
