extends Node

const TOAST := preload("res://scenes/ui/toast/toast.tscn")

func _ready() -> void:
	var toast := TOAST.instantiate()
	add_child(toast)

	# 등장 직후 / 다 뜬 뒤 / 사라지는 중 세 장.
	await _shot(0.05, "toast_a_rising")
	await _shot(0.25, "toast_b_shown")
	await _shot(2.00, "toast_c_fading")
	get_tree().quit()

func _shot(at: float, name: String) -> void:
	await get_tree().create_timer(at, true, false, true).timeout
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("user://%s.png" % name)
	print("saved ", name)
