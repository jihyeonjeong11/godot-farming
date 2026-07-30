class_name NonPlayableCharacter
extends CharacterBody2D

@export var min_walk_cycle: int = 2
@export var max_walk_cycle: int = 6

var walk_cycles: int
var current_walk_cycle: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
