class_name NatureSpawner extends WorldObject

@export var trees: Array[WorldObjectData] = [
	preload("res://world_objects/tres/dead_tree.tres")
]
@export var grass: WorldObjectData = preload("res://world_objects/tres/grass.tres")
@export var rock: WorldObjectData = preload("res://world_objects/tres/rock.tres")
@export var tree_weight := 1.0
@export var grass_weight := 3.0
@export var rock_weight := 1.0
@export var empty_weight := 1.0


func spawn_table() -> Dictionary:
	var tree_ids: Array[StringName] = []
	for tree in trees:
		if tree != null:
			tree_ids.append(tree.id)
	return {
		"weights": [tree_weight, grass_weight, rock_weight, empty_weight],
		"trees": tree_ids,
		"grass": grass.id if grass != null else &"",
		"rock": rock.id if rock != null else &"",
	}
