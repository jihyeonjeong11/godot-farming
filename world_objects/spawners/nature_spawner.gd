class_name NatureSpawner extends WorldObject

const TREE_OBJECT := preload("res://world_objects/nature/tree_object.tscn")

@export var spawnables: Array[WorldObjectData] = [
	preload("res://world_objects/tres/oak_tree.tres"),
	preload("res://world_objects/tres/pine_tree.tres"),
]


func advance_day() -> void:
	var land := CursorActions.current_land()
	if land == null or spawnables.is_empty():
		return
	if CursorActions.object_at(CursorActions.cell_rect(land, CursorActions.cell_of(land, global_position))):
		return
	_spawn_tree()


func _spawn_tree() -> void:
	var tree_data: WorldObjectData = spawnables.pick_random().duplicate()
	tree_data.growth_stage = randi_range(0, tree_data.growth_textures.size() - 1)
	var tree := TREE_OBJECT.instantiate() as TreeObject
	tree.data = tree_data
	get_parent().add_child(tree)
	tree.global_position = global_position
