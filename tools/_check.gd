extends Node

func _ready() -> void:
	var city := (load("res://scenes/test_scenes/proc_gen_city_ruin.tscn") as PackedScene).instantiate()
	add_child(city)
	await get_tree().process_frame
	var root := city.get_node_or_null("PrefabObjects")
	var doors := 0
	var broken := 0
	var sample := ""
	for n in root.get_children():
		if not n.has_method("interact"):
			continue
		doors += 1
		if String(n.get("target_scene")).is_empty():
			broken += 1
		elif sample.is_empty():
			sample = "%s -> %s / spawn=%s" % [n.name, n.get("target_scene"), n.get("target_spawn")]
	print("RESULT objects=", root.get_child_count(), " doors=", doors, " empty_target=", broken)
	print("RESULT sample: ", sample)
	get_tree().quit()
