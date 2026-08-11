extends Node2D

@onready var game_tile_map: TileMapLayer = $GameTileMap/Floors


@export var noise_height_text: NoiseTexture2D
@export var noise_tree_text: NoiseTexture2D

var noise: Noise
var tree_noise: Noise

var land_source_id = 0
var water_source_id = 2
var water_atlas = Vector2i(0, 0)
var land_atlas = Vector2i(5, 0)

var proc_terrains_set_id = 1
var sand_tiles_arr = []
var terrain_sand_int = 0

var grass_tiles_arr = []
var terrain_grass_int = 1

var cliff_tiles_arr = []
var terrain_cliff_int = 2

@export var tree_scene: PackedScene = preload("res://scenes/objects/trees/SmallTree.tscn")
var tree_tiles_arr = []


var width: int = 100
var height: int = 100

var noise_val_arr = []

func _ready():
	noise = noise_height_text.noise
	tree_noise = noise_tree_text.noise
	generate_world()
	_add_debug_zoom_buttons()

func _add_debug_zoom_buttons() -> void:
	var layer := CanvasLayer.new()
	layer.name = "DebugZoomButtons"
	layer.layer = 128  
	add_child(layer)

	var box := HBoxContainer.new()
	box.position = Vector2(8, 8)
	box.add_theme_constant_override("separation", 4)
	layer.add_child(box)

	for factor in [1.0, 3.0, 5.0]:
		var b := Button.new()
		b.text = "%dx" % factor
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_set_debug_zoom.bind(factor))
		box.add_child(b)

func _set_debug_zoom(factor: float) -> void:
	var cam := get_node_or_null("Player/Camera2D") as Camera2D
	if cam == null:
		return
	cam.zoom = Vector2.ONE / factor

func generate_world():
	for x in range(-width/2, width/2):
		for y in range(-height/2, height/2):
			var noise_val = noise.get_noise_2d(x, y)
			var tree_noise_val = tree_noise.get_noise_2d(x, y)

			noise_val_arr.append(noise_val)

			# placing ground
			if noise_val > 0.0:
				if noise_val > 0.2:
					if noise_val > 0.6:
						cliff_tiles_arr.append(Vector2i(x,y))
					grass_tiles_arr.append(Vector2i(x,y))
				sand_tiles_arr.append(Vector2i(x,y))

				# placing trees
				if noise_val > 0.05 and noise_val < 0.17 and tree_noise_val > 0.17:
					tree_tiles_arr.append(Vector2i(x,y))
				pass


			elif noise_val < 0.0:
				game_tile_map.set_cell(Vector2i(x,y), water_source_id, water_atlas)
				pass
	game_tile_map.set_cells_terrain_connect(sand_tiles_arr, proc_terrains_set_id, terrain_sand_int)
	game_tile_map.set_cells_terrain_connect(grass_tiles_arr, proc_terrains_set_id, terrain_grass_int)
	game_tile_map.set_cells_terrain_connect(cliff_tiles_arr, proc_terrains_set_id, terrain_cliff_int)

	place_trees()

	print("highest", noise_val_arr.max())
	print("lowest", noise_val_arr.min())
	print("sand=%d  grass=%d  cliff=%d  tree=%d" % [sand_tiles_arr.size(), grass_tiles_arr.size(), cliff_tiles_arr.size(), tree_tiles_arr.size()])

func place_trees():
	if tree_scene == null:
		return

	# 나무끼리, 그리고 플레이어와 앞뒤가 맞도록 y_sort 컨테이너에 담는다.
	var container = Node2D.new()
	container.name = "Trees"
	container.y_sort_enabled = true
	add_child(container)

	for coords in tree_tiles_arr:
		var tree = tree_scene.instantiate()
		tree.position = game_tile_map.map_to_local(coords)
		container.add_child(tree)
