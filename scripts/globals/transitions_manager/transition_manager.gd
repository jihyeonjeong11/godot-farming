extends Node

signal changing_scene(next_scene_path: String)

var is_transitioning: bool = false

var scene_path: String = ""

func _ready() -> void:
	pass

func go_to_scene(next_scene: Variant) -> void :
	scene_path = next_scene if next_scene is String else next_scene.resource_path
	_swap_scene()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _swap_scene() -> void :
	if not scene_path.is_empty():
		changing_scene.emit(scene_path)
		var err = get_tree().change_scene_to_file(scene_path)
		assert (err == OK, "Cannot find scene \"%s\"" % scene_path)
