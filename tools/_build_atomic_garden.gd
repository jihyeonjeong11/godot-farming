extends SceneTree
## 아토믹 가든 프리팹 생성. godot --headless --path . --script tools/_build_atomic_garden.gd

const OUT := "res://scenes/prefabs/farm/atomic_garden.tscn"
const TILES := "res://tilesets/city_ruin.tres"
const SIZE := 16
const GROUND_SRC := 0
const PROP_SRC := 3
const TERRAIN_SET := 0
const DIRT := 2
const GRASS := 3

const PANEL := Vector2i(21, 20)
const PANEL_L := Vector2i(28, 20)
const PANEL_R := Vector2i(28, 25)
const GATE := Vector2i(22, 25)
const POST_W := Vector2i(27, 20)
const POST_E := Vector2i(20, 20)
const SIGN := Vector2i(10, 12)

const FENCE_N := 4
const FENCE_S := 15
const FENCE_W := 2
const FENCE_E := 13
const INNER := Rect2i(3, 5, 10, 10)
const PATH := Rect2i(7, 15, 3, 1)

const FENCE: Array = [
	[Vector2i(4, FENCE_N), PANEL],
	[Vector2i(7, FENCE_N), PANEL_L],
	[Vector2i(10, FENCE_N), PANEL],
	[Vector2i(13, FENCE_N), PANEL_R],
	[Vector2i(4, FENCE_S), PANEL],
	[Vector2i(11, FENCE_S), PANEL_L],
	[Vector2i(12, FENCE_S), PANEL_L],
	[Vector2i(13, FENCE_S), PANEL_R],
	[Vector2i(FENCE_W, 10), POST_W],
	[Vector2i(FENCE_E, 10), POST_E],
	[Vector2i(10, 10), SIGN],
]
const GATE_CELL := Vector2i(8, FENCE_S)


func _init() -> void:
	var tile_set: TileSet = load(TILES)
	var scene_root := Node2D.new()
	scene_root.name = "AtomicGarden"
	root.add_child(scene_root)

	var paint := TileMapLayer.new()
	paint.tile_set = tile_set
	root.add_child(paint)

	var outer: Array[Vector2i] = []
	var ring: Array[Vector2i] = []
	var inner: Array[Vector2i] = []
	for y in range(-1, SIZE + 1):
		for x in range(-1, SIZE + 1):
			var c := Vector2i(x, y)
			if INNER.has_point(c) or PATH.has_point(c):
				inner.append(c)
			elif x < 0 or y < 0 or x >= SIZE or y >= SIZE:
				ring.append(c)
			else:
				outer.append(c)
	paint.set_cells_terrain_connect(outer + ring, TERRAIN_SET, GRASS, false)
	paint.set_cells_terrain_connect(inner, TERRAIN_SET, DIRT, false)

	var ground := TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = tile_set
	scene_root.add_child(ground)
	ground.owner = scene_root
	for c in outer + inner:
		ground.set_cell(c, paint.get_cell_source_id(c), paint.get_cell_atlas_coords(c))

	var props := TileMapLayer.new()
	props.name = "Props"
	props.tile_set = tile_set
	scene_root.add_child(props)
	props.owner = scene_root
	for entry in FENCE:
		props.set_cell(entry[0], PROP_SRC, entry[1])

	var gate := TileMapLayer.new()
	gate.name = "Gate"
	gate.tile_set = tile_set
	gate.collision_enabled = false
	scene_root.add_child(gate)
	gate.owner = scene_root
	gate.set_cell(GATE_CELL, PROP_SRC, GATE)

	var body := StaticBody2D.new()
	body.name = "SideFences"
	scene_root.add_child(body)
	body.owner = scene_root
	for side in [["West", FENCE_W * 32 + 8], ["East", FENCE_E * 32 + 25]]:
		var x: int = side[1]
		var shape := CollisionShape2D.new()
		shape.name = side[0]
		var rect := RectangleShape2D.new()
		rect.size = Vector2(12, (FENCE_S - FENCE_N - 1) * 32)
		shape.shape = rect
		shape.position = Vector2(x, (FENCE_N + 1 + FENCE_S) * 16)
		body.add_child(shape)
		shape.owner = scene_root

	var packed := PackedScene.new()
	packed.pack(scene_root)
	var err := ResourceSaver.save(packed, OUT)
	print("saved %s (%d)" % [OUT, err])
	quit()
