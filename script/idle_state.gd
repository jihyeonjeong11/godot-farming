extends NodeState

@export var player: Player
@export var animated_sprite_2d: AnimatedSprite2D

func _on_process(_delta : float) -> void:
	pass


func _on_physics_process(_delta : float) -> void:
	if player.player_direction == Vector2.UP:
		animated_sprite_2d.play("idle_back")
	elif player.player_direction == Vector2.RIGHT:
		animated_sprite_2d.play("idle_right")
	elif player.player_direction == Vector2.DOWN:
		animated_sprite_2d.play("idle_front")
	elif player.player_direction == Vector2.LEFT:
		animated_sprite_2d.play("idle_left")
	else:
		animated_sprite_2d.play("idle_front")


func _on_next_transitions() -> void:
	GameInputEvents.movement_input()	
	
	if Input.is_action_just_pressed("select_inventory_0"):
		player.current_tool = DataTypes.Tools.AxeWood
	if Input.is_action_just_pressed("select_inventory_1"):
		player.current_tool = DataTypes.Tools.TillGround
	if GameInputEvents.is_movement_input():
		transition.emit("Walk")


	if player.current_tool == DataTypes.Tools.AxeWood && GameInputEvents.use_tool():
		transition.emit("chopping")
	elif player.current_tool == DataTypes.Tools.TillGround && GameInputEvents.use_tool():
		transition.emit("tilling")
	elif player.current_tool == DataTypes.Tools.WaterCrops && GameInputEvents.use_tool():
		transition.emit("watering")
	elif player.current_tool == DataTypes.Tools.PlantCorn && GameInputEvents.use_tool():
		transition.emit("chopping")


func _on_enter() -> void:
	pass


func _on_exit() -> void:
	pass
