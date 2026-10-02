class_name Player
extends CharacterBody2D

const DIR_SUFFIX := {
	Vector2.UP: "up",
	Vector2.LEFT: "left",
	Vector2.DOWN: "down",
	Vector2.RIGHT: "right",
}

const TOOL_KEYS := {KEY_1: "axe", KEY_2: "pickaxe", KEY_3: "hoe", KEY_4: "watering_can", KEY_5: "sickle", KEY_6: "pistol"}

@export var speed := 60.0
@export var body: AnimatedSprite2D
@export var tool_layer: Sprite2D
@export var hands_layer: Sprite2D

const OUTFIT_PARTS := ["Hair", "Shirt", "Pants", "Shoes"]


var stats: BaseCharacterStats

var facing := Vector2.DOWN
var ground_type: String = ""
var _ground_layers: Array[TileMapLayer] = []

@export var is_freeze: bool = false


func _ready() -> void:
	_ground_layers = TileUtils.ground_layers(owner)
	body.frame_changed.connect(_sync_layers)
	body.animation_changed.connect(_sync_layers)
	for part in OUTFIT_PARTS.size():
		equip(part, Inventory.get_vanity(part))
		
# 로드하면 스탯및 각종 수치 추가하기
func load_player() -> void:
	pass
	
func get_terrain_type() -> String:
	return TileUtils.terrain_at(_ground_layers, global_position)

# 로드 없으면 새로 만들
func initiate_player() -> void:
	stats = stats.duplicate()
	pass

# 툴 벨트
func attach_tool_belt() -> void:
	pass

# 오른쪽 클릭에서 해당 타일에 오브젝트가 있는지 확인
func get_interactable_object() -> void:
	pass
	
# 왼쪽 클릭에서 해당 타일이 어떤 타일인지 확인함
func get_tool_usable_tile() -> void:
	pass

func _process(_delta: float) -> void:
	if is_freeze:
		return
	tool_layer.aim_at(get_global_mouse_position())

func consume_selected() -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if is_freeze:
		return
	var key := event as InputEventKey
	if key != null and key.pressed and TOOL_KEYS.has(key.keycode):
		tool_layer.set_tool(TOOL_KEYS[key.keycode])
		hands_layer.held = tool_layer.is_held()
		_sync_layers()


func face(input: Vector2) -> void:
	if input.dot(facing) > 0.0:
		return
	if absf(input.x) >= absf(input.y):
		facing = Vector2.RIGHT if input.x > 0.0 else Vector2.LEFT
	else:
		facing = Vector2.DOWN if input.y > 0.0 else Vector2.UP


func outfit_count(part: int) -> int:
	return _outfit_layer(part).variant_count()


func equip(part: int, index: int) -> void:
	var layer := _outfit_layer(part)
	layer.visible = index >= 0
	if index >= 0:
		layer.variant = index
	Inventory.set_vanity(part, index)
	_sync_layers()


func _outfit_layer(part: int) -> Sprite2D:
	return body.get_node(OUTFIT_PARTS[part]) as Sprite2D


func play_action(action: String) -> void:
	var directional := "%s_%s" % [action, DIR_SUFFIX[facing]]
	body.play(directional if body.sprite_frames.has_animation(directional) else action)
	_sync_layers()


func _sync_layers() -> void:
	for layer in body.get_children():
		if layer.has_method("sync"):
			layer.sync(body.animation, body.frame)
