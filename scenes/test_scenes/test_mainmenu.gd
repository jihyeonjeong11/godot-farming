extends Node2D

const TILE := 32

const STAGE_LEFT := -2
const STAGE_RIGHT := 43
const STAGE_TOP := -2
const STAGE_BOTTOM := 13
const DIRT_RIGHT := 29

const TERRAIN_SET := 0
const GROUND_ASPHALT := 0
const GROUND_CONCRETE := 1
const GROUND_DIRT := 2
const GROUND_GRASS := 3
const SOIL_TERRAIN := 0

const FENCE_SRC := 0
const FENCE_CAP_L := [Vector2i(17, 4), Vector2i(17, 5)]
const FENCE_CAP_R := [Vector2i(20, 4), Vector2i(20, 5)]
const FENCE_MID := [Vector2i(22, 7), Vector2i(22, 8)]
const FENCE_X0 := 28
const FENCE_X1 := 34
const FENCE_Y := 0

const BED_X0 := 31
const BED_X1 := 39
const BED_Y0 := 8
const BED_Y1 := 10
const CRYSTAL_CELL := Vector2i(35, 9)
const PLAYER_CELL := Vector2i(30, 7)

const CAMERA_START := Vector2(320, 176)
const CAMERA_STOP := Vector2(960, 176)
const PAN_TIME := 7.0
const LOGO_FADE := 1.4
const PROMPT_BLINK := 0.9

const HOUSE_SCENE: PackedScene = preload("res://scenes/prefabs/house.tscn")
const TREE_SCENE: PackedScene = preload("res://scenes/objects/placables/tree_instance.tscn")
const OBJECT_SCENE: PackedScene = preload("res://scenes/objects/placables/object_instance.tscn")
const PLAYER_FRAMES: SpriteFrames = preload("res://scenes/characters/player/player_frames.tres")

const OAK: PlaceableObject = preload("res://scripts/resources/placeable_object/nature/oak_tree.tres")
const TUFT: PlaceableObject = preload("res://scripts/resources/placeable_object/nature/grass.tres")
const PEBBLE: PlaceableObject = preload("res://scripts/resources/placeable_object/nature/stone_small.tres")
const ROCK: PlaceableObject = preload("res://scripts/resources/placeable_object/nature/rock.tres")
const TWIG: PlaceableObject = preload("res://scripts/resources/placeable_object/nature/twig.tres")

const CROPS: Array[PackedScene] = [
	preload("res://scenes/prefabs/crops/carrot_grown.tscn"),
	preload("res://scenes/prefabs/crops/potato_grown.tscn"),
	preload("res://scenes/prefabs/crops/wheat_grown.tscn"),
	preload("res://scenes/prefabs/crops/onion_grown.tscn"),
]

const HOUSES: Array = [
	[Vector2i(-11, -3), false],
	[Vector2i(24, -3), true],
]
const OAK_CELLS: Array[Vector2i] = [Vector2i(31, 2), Vector2i(33, 1)]

const RUBBLE: Array = [
	[ROCK, Vector2i(26, 9)],
	[PEBBLE, Vector2i(28, 4)],
	[TWIG, Vector2i(25, 6)],
	[PEBBLE, Vector2i(29, 10)],
	[ROCK, Vector2i(27, 3)],
	[ROCK, Vector2i(5, 8)],
	[TWIG, Vector2i(6, 10)],
	[PEBBLE, Vector2i(6, 5)],
]

const GREENERY: Array = [
	[TUFT, Vector2i(30, 3)],
	[TUFT, Vector2i(32, 5)],
	[TUFT, Vector2i(30, 9)],
	[TUFT, Vector2i(31, 10)],
	[PEBBLE, Vector2i(33, 6)],
	[PEBBLE, Vector2i(30, 6)],
]

const CRYSTAL_TINT := Color(0.45, 1.7, 0.85)
const CRYSTAL_LIGHT := Color(0.35, 1.0, 0.45)
const CRYSTAL_RADIUS := 320.0

@onready var ground: TileMapLayer = $Ground
@onready var tilled_soil: TileMapLayer = $TilledSoil
@onready var fence: TileMapLayer = $Fence
@onready var ruins: Node2D = $Ruins
@onready var props: Node2D = $Props
@onready var camera: Camera2D = $Camera2D
@onready var logo: Control = $Ui/Logo
@onready var prompt: Label = $Ui/Prompt
@onready var ambient: AudioStreamPlayer = $Ambient

var _pan: Tween
var _settled := false


func _ready() -> void:
	_paint_ground()
	_paint_beds()
	_paint_fence()
	_build_ruins()
	_build_props()
	_build_player()
	_build_crystal()

	if ambient.stream != null:
		ambient.finished.connect(ambient.play)
		ambient.play()

	_start_pan()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_confirm(event):
		return

	get_viewport().set_input_as_handled()
	if _settled:
		_start_pan()
	else:
		_skip_pan()


func _is_confirm(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventMouseButton:
		return event.pressed
	return false


func cell_pos(cell: Vector2i) -> Vector2:
	return Vector2(cell) * TILE + Vector2(TILE, TILE) * 0.5


func rect_cells(x0: int, x1: int, y0: int, y1: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			cells.append(Vector2i(x, y))
	return cells


func _paint_ground() -> void:
	ground.clear()
	ground.set_cells_terrain_connect(
		rect_cells(STAGE_LEFT, STAGE_RIGHT, STAGE_TOP, STAGE_BOTTOM), TERRAIN_SET, GROUND_GRASS, false)
	ground.set_cells_terrain_connect(
		rect_cells(STAGE_LEFT, DIRT_RIGHT, STAGE_TOP, STAGE_BOTTOM), TERRAIN_SET, GROUND_DIRT, false)


func _paint_beds() -> void:
	tilled_soil.clear()
	var cells := rect_cells(BED_X0, BED_X1, BED_Y0, BED_Y1)
	cells.erase(CRYSTAL_CELL)
	tilled_soil.set_cells_terrain_connect(cells, TERRAIN_SET, SOIL_TERRAIN, false)

	var kind := 0
	for cell in cells:
		var crop := CROPS[kind % CROPS.size()].instantiate() as Node2D
		crop.position = cell_pos(cell)
		props.add_child(crop)
		kind += 1
		if cell.x == BED_X1:
			kind += 1


func _paint_fence() -> void:
	fence.clear()
	for x in range(FENCE_X0, FENCE_X1 + 1):
		var pair := FENCE_MID
		if x == FENCE_X0:
			pair = FENCE_CAP_L
		elif x == FENCE_X1:
			pair = FENCE_CAP_R
		fence.set_cell(Vector2i(x, FENCE_Y), FENCE_SRC, pair[0])
		fence.set_cell(Vector2i(x, FENCE_Y + 1), FENCE_SRC, pair[1])


func _build_ruins() -> void:
	for entry in HOUSES:
		var house := HOUSE_SCENE.instantiate() as Node2D
		house.position = Vector2(entry[0]) * TILE
		if entry[1]:
			house.scale = Vector2(-1.0, 1.0)
		ruins.add_child(house)

	for entry in RUBBLE:
		props.add_child(_make_object(entry[0], entry[1]))


func _build_props() -> void:
	for cell in OAK_CELLS:
		var tree := TREE_SCENE.instantiate() as Node2D
		tree.position = cell_pos(cell)
		tree.set("object", OAK)
		tree.set("stage", 4)
		props.add_child(tree)

	for entry in GREENERY:
		props.add_child(_make_object(entry[0], entry[1]))


func _make_object(object: PlaceableObject, cell: Vector2i) -> Node2D:
	var node := OBJECT_SCENE.instantiate() as Node2D
	node.position = cell_pos(cell)
	node.set("object", object)
	return node


func _build_player() -> void:
	var sprite := AnimatedSprite2D.new()
	sprite.name = "PlayerFigure"
	sprite.sprite_frames = PLAYER_FRAMES
	sprite.animation = &"idle_front"
	sprite.offset = Vector2(0, -30)
	sprite.position = cell_pos(PLAYER_CELL)
	sprite.play()
	props.add_child(sprite)


func _build_crystal() -> void:
	var root := Node2D.new()
	root.name = "Cobalt60"
	root.position = cell_pos(CRYSTAL_CELL)

	var sprite := Sprite2D.new()
	sprite.texture = ROCK.object_texture
	sprite.modulate = CRYSTAL_TINT
	sprite.offset = Vector2(0, -16)
	sprite.scale = Vector2(1.05, 1.05)
	root.add_child(sprite)

	var ramp := Gradient.new()
	ramp.set_color(0, Color.WHITE)
	ramp.set_color(1, Color(1, 1, 1, 0))

	var glow := GradientTexture2D.new()
	glow.width = 256
	glow.height = 256
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5, 0.5)
	glow.fill_to = Vector2(1.0, 0.5)
	glow.gradient = ramp

	var light := PointLight2D.new()
	light.texture = glow
	light.color = CRYSTAL_LIGHT
	light.energy = 1.4
	light.texture_scale = CRYSTAL_RADIUS / 128.0
	light.position = Vector2(0, -16)
	root.add_child(light)

	props.add_child(root)

	var pulse := create_tween().set_loops()
	pulse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(light, "energy", 2.3, 1.3)
	pulse.tween_property(light, "energy", 1.1, 1.3)


func _start_pan() -> void:
	_settled = false
	logo.modulate.a = 0.0
	prompt.modulate.a = 0.0
	camera.position = CAMERA_START

	if _pan != null and _pan.is_valid():
		_pan.kill()

	_pan = create_tween()
	_pan.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pan.tween_property(camera, "position", CAMERA_STOP, PAN_TIME)
	_pan.tween_callback(_on_settled)


func _skip_pan() -> void:
	if _pan != null and _pan.is_valid():
		_pan.kill()
	camera.position = CAMERA_STOP
	_on_settled()


func _on_settled() -> void:
	if _settled:
		return

	_settled = true
	var reveal := create_tween()
	reveal.tween_property(logo, "modulate:a", 1.0, LOGO_FADE)
	reveal.tween_property(prompt, "modulate:a", 1.0, 0.4)
	reveal.tween_callback(_blink_prompt)


func _blink_prompt() -> void:
	var blink := create_tween().set_loops()
	blink.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	blink.tween_property(prompt, "modulate:a", 0.15, PROMPT_BLINK)
	blink.tween_property(prompt, "modulate:a", 1.0, PROMPT_BLINK)
