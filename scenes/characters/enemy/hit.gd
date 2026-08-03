extends ApoNodeState

@export var zombie: CharacterBody2D

const SPEED = 30
const FRICTION = 500

var velocity

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print('knockback')
	transition.emit('chase')
	#velocity = velocity.move_toward(Vector2.ZERO, FRICTION)
	#zombie.move_and_slide()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
