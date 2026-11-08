class_name LootActions extends Node

const ITEM_STACK_INSTANCE := preload("res://scenes/objects/pickables/item_stack_instance.tscn")


static func drop_loot(loot: Array[LootData], position: Vector2) -> void:
	var level := (Engine.get_main_loop() as SceneTree).current_scene
	for entry in loot:
		if randf() >= entry.chance:
			continue
		var drop := ITEM_STACK_INSTANCE.instantiate() as ItemStackInstance
		drop.stack = ItemStack.new(entry.item, entry.amount)
		level.add_child(drop)
		drop.global_position = position
