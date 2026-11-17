extends Node2D

func _ready() -> void:
	var scene := load("res://world_objects/salvage/dead_crops.tscn") as PackedScene
	var seen := {}
	for i in 40:
		var o := scene.instantiate()
		o.position = Vector2(i * 37, i * 53)
		add_child(o)
	await get_tree().process_frame
	await get_tree().process_frame
	for o in get_children():
		seen[o.state["variant"]] = true
		assert(o.sprite.texture != null)
	print("VERIFY variants seen=", seen.size(), " sample offset=", get_child(0).sprite.offset, " rect=", get_child(0).global_collision_rect())
	get_tree().quit()
