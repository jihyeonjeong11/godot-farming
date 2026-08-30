extends AnimatedSprite2D

var lit = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$InteractableComponent.interacted.connect(_on_interacted)

func _on_interacted() -> void:
	lit = not lit
	play(&"on" if lit else &"off")
