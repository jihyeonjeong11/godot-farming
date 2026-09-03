extends Node

const OVERLAY := preload("res://scenes/ui/scene_overay.tscn")
const ITEMS := [
	preload("res://scripts/resources/consumables/apple.tres"),
	preload("res://scripts/resources/pickables/stone.tres"),
	preload("res://scripts/resources/pickables/log.tres"),
	preload("res://scripts/resources/pickables/carrot.tres"),
]

func _ready() -> void:
	add_child(OVERLAY.instantiate())
	await _wait(0.3)

	for i in 3:
		Inventory.add_item(ITEMS[i])
		await _wait(0.35)
	await _shot("stack_3")

	Inventory.add_item(ITEMS[3])
	await _wait(0.35)
	await _shot("stack_overflow")

	await _wait(2.2)
	await _shot("stack_after")
	get_tree().quit()

func _wait(t: float) -> void:
	await get_tree().create_timer(t, true, false, true).timeout

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://%s.png" % name)
	print("saved ", name)
