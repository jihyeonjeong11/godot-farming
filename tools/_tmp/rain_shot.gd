extends Node

func _ready() -> void:
	var lvl: Node = load("res://scenes/test_scenes/farm/farm_sprite_test.tscn").instantiate()
	add_child(lvl)
	var cam := Camera2D.new()
	cam.position = Vector2(1100, 760)
	cam.zoom = Vector2(2, 2)
	add_child(cam)
	for i in 10:
		cam.make_current()
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tools/_tmp/rain_shot.png")
	get_tree().quit()
