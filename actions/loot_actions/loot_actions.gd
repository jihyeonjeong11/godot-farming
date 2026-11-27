class_name LootActions extends Node

const DROPPED_ITEM := preload("res://items/dropped_item/dropped_item.tscn")


static func drop_loot(loot: Array[LootData], position: Vector2) -> void:
	var level := (Engine.get_main_loop() as SceneTree).current_scene
	for entry in loot:
		if randf() >= entry.chance:
			continue
		var drop := DROPPED_ITEM.instantiate() as DroppedItem
		drop.stack = ItemStack.new(entry.item, entry.amount)
		level.add_child(drop)
		drop.global_position = position
