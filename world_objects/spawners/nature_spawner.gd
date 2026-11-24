class_name NatureSpawner extends WorldObject

@export var trees: Array[WorldObjectData] = [
	preload("res://world_objects/tres/dead_tree.tres")
]
@export var grass: WorldObjectData = preload("res://world_objects/tres/grass.tres")
@export var rock: WorldObjectData = preload("res://world_objects/tres/rock.tres")
@export var flower: WorldObjectData = preload("res://world_objects/tres/sunflower.tres")
@export var blueberry: WorldObjectData = preload("res://world_objects/tres/blueberry.tres")
@export var morel: WorldObjectData = preload("res://world_objects/tres/morel.tres")
@export var chanterelle: WorldObjectData = preload("res://world_objects/tres/chanterelle.tres")
@export var tree_weight := 1.0
@export var grass_weight := 3.0
@export var rock_weight := 1.0
@export var flower_weight := 0.1
@export var blueberry_weight := 0.1
@export var morel_weight := 0.1
@export var chanterelle_weight := 0.1
@export var empty_weight := 1.0


func spawn_table() -> Dictionary:
	var tree_ids: Array[StringName] = []
	for tree in trees:
		if tree != null:
			tree_ids.append(tree.id)
	return {
		"weights": [tree_weight, grass_weight, rock_weight, flower_weight, blueberry_weight, morel_weight, chanterelle_weight, empty_weight],
		"trees": tree_ids,
		"grass": grass.id if grass != null else &"",
		"rock": rock.id if rock != null else &"",
		"flower": flower.id if flower != null else &"",
		"blueberry": blueberry.id if blueberry != null else &"",
		"morel": morel.id if morel != null else &"",
		"chanterelle": chanterelle.id if chanterelle != null else &"",
	}
