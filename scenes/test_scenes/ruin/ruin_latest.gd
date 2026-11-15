extends Base_level


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	GameState.current_level = DataTypes.Levels.RuinCity


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
