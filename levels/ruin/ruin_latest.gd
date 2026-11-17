
extends BaseLevel

const GRASS_SCENE := preload("res://world_objects/nature/grass_object.tscn")
const DEAD_CROPS_SCENE := preload("res://world_objects/salvage/dead_crops.tscn")
const NOISE := preload("res://levels/ruin/ruin_noise.tres")
const DIRT_TERRAIN := 1

@export var grass_threshold := 0.0
@export var dead_crops_threshold := 0.25
@export var grass_density := 0.55
@export var dead_crops_density := 0.7
@export var clearance := 64.0

@onready var back: TileMapLayer = $Tilemap/Back


func _ready() -> void:
	super()
	#_scatter()


func _process(delta: float) -> void:
	pass


func _scatter() -> void:
	var blocked := _blocked_rects()
	var keep_away := _keep_away_points()
	var root := Node2D.new()
	root.name = "Scatter"
	root.y_sort_enabled = true
	add_child(root)
	var noise: Noise = NOISE.noise
	var half := Vector2.ONE * Constants.tile_size * 0.5
	for cell in back.get_used_cells():
		var tile := back.get_cell_tile_data(cell)
		if tile == null or tile.terrain != DIRT_TERRAIN:
			continue
		var center := back.to_global(back.map_to_local(cell))
		var cell_rect := Rect2(center - half, half * 2.0)
		if blocked.any(func(r: Rect2) -> bool: return r.intersects(cell_rect)):
			continue
		if keep_away.any(func(p: Vector2) -> bool: return p.distance_to(center) < clearance):
			continue
		var n := noise.get_noise_2dv(center)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(cell)
		var scene: PackedScene = null
		if n > dead_crops_threshold and rng.randf() < dead_crops_density:
			scene = DEAD_CROPS_SCENE
		elif n > grass_threshold and rng.randf() < grass_density:
			scene = GRASS_SCENE
		if scene == null:
			continue
		var obj: Node2D = scene.instantiate()
		obj.position = root.to_local(center + Vector2(rng.randi_range(-6, 6), half.y - 4))
		root.add_child(obj)


func _blocked_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for node in get_tree().get_nodes_in_group(Building.GROUP):
		var rect: Rect2 = (node as Building).global_footprint_rect()
		if rect.has_area():
			rects.append(rect)
	var farm_ruin := get_node_or_null(^"Tilemap/FarmRuin")
	if farm_ruin != null:
		for layer in farm_ruin.find_children("*", "TileMapLayer", true, false):
			var used: Rect2i = layer.get_used_rect()
			if used.has_area():
				var size := Vector2(layer.tile_set.tile_size)
				rects.append(layer.global_transform * Rect2(Vector2(used.position) * size, Vector2(used.size) * size))
	return rects


func _keep_away_points() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for path in [^"Player", ^"SpawnFromFarm", ^"ToFarm"]:
		var node := get_node_or_null(path) as Node2D
		if node != null:
			points.append(node.global_position)
	for node in $Salvage.get_children():
		points.append((node as Node2D).global_position)
	return points
