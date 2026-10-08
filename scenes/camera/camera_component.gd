extends Camera2D

@export var target: Node2D
@export var follow_offset := Vector2(0, -12)

@export var level_y = 100
@export var level_x = 100


func _ready() -> void:
	make_current()
	get_level_size()
	if is_instance_valid(target):
		global_position = target.global_position + follow_offset
	reset_smoothing.call_deferred()


func _physics_process(_delta: float) -> void:
	if is_instance_valid(target):
		global_position = target.global_position + follow_offset


func get_level_size() -> void:
	pass
