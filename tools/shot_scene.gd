extends Node
## 씬 하나를 SubViewport 에 띄워 통째로 PNG 로 찍는다. 오토로드가 필요하므로 씬으로 띄운다.
## 사용: godot --path . tools/shot_scene.tscn -- <scene.tscn> <out.png> [w h] [ox oy]

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("scene path and output path required")
		get_tree().quit(1)
		return

	var packed := load(args[0]) as PackedScene
	if packed == null:
		push_error("cannot load scene: %s" % args[0])
		get_tree().quit(1)
		return

	var size := Vector2i(1536, 1088)
	if args.size() >= 4:
		size = Vector2i(int(args[2]), int(args[3]))
	var origin := Vector2.ZERO
	if args.size() >= 6:
		origin = Vector2(float(args[4]), float(args[5]))

	var viewport := SubViewport.new()
	viewport.size = size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)

	var scene := packed.instantiate() as Node2D
	scene.position = -origin
	viewport.add_child(scene)
	for camera in scene.find_children("*", "Camera2D", true, false):
		(camera as Camera2D).enabled = false

	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw

	viewport.get_texture().get_image().save_png(args[1])
	print("saved ", args[1])
	get_tree().quit()
