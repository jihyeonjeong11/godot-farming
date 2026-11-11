class_name NatureSpawner extends WorldObject

const TREE_OBJECT := preload("res://world_objects/nature/tree_object.tscn")
const GRASS_OBJECT := preload("res://world_objects/nature/grass_object.tscn")
const ROCK_OBJECT := preload("res://world_objects/nature/rock_object.tscn")

@export var trees: Array[WorldObjectData] = [
	preload("res://world_objects/tres/oak_tree.tres"),
	preload("res://world_objects/tres/pine_tree.tres"),
]
@export var grass: WorldObjectData = preload("res://world_objects/tres/grass.tres")
@export var rock: WorldObjectData = preload("res://world_objects/tres/rock.tres")
@export var tree_weight := 1.0
@export var grass_weight := 3.0
@export var rock_weight := 1.0
@export var empty_weight := 1.0

var first_day := false


func _ready() -> void:
	super()
	TimeManager.day_passed.connect(advance_day)
	if GameState.once("nature_seeded_%s" % name):
		first_day = true
		advance_day.call_deferred()


func advance_day(_day: int = 0) -> void:
	var mature := first_day
	first_day = false
	var land := CursorActions.current_land()
	if land == null or CursorActions.layers_at(self.global_position).size() != 1:
		return
	if CursorActions.object_in_cell(land, CursorActions.cell_of(land, global_position), self):
		return
	var rng := RandomNumberGenerator.new()
	match rng.rand_weighted(PackedFloat32Array([tree_weight, grass_weight, rock_weight, empty_weight])):
		0:
			_spawn_tree(mature)
		1:
			_spawn_grass()
		2:
			_spawn_rock()


func _spawn_tree(mature: bool) -> void:
	if trees.is_empty():
		return
	var tree := TREE_OBJECT.instantiate() as TreeObject
	tree.data = WorldObjectDB.get_data(trees.pick_random().id)
	if mature:
		tree.state["growth_stage"] = tree.data.max_growth_stage
	tree.position = position
	get_parent().add_child(tree)


func _spawn_grass() -> void:
	if grass == null:
		return
	var grass_object := GRASS_OBJECT.instantiate() as GrassObject
	grass_object.data = grass
	grass_object.position = position
	get_parent().add_child(grass_object)


func _spawn_rock() -> void:
	if rock == null:
		return
	var rock_object := ROCK_OBJECT.instantiate() as RockObject
	rock_object.data = rock
	rock_object.position = position
	get_parent().add_child(rock_object)
