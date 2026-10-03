class_name Player
extends CharacterBody2D

const DIR_SUFFIX := {
	Vector2.UP: "up",
	Vector2.LEFT: "left",
	Vector2.DOWN: "down",
	Vector2.RIGHT: "right",
}

@export var body: AnimatedSprite2D
@export var tool_layer: Sprite2D
@export var hands_layer: Sprite2D

const OUTFIT_PARTS := ["Hair", "Shirt", "Pants", "Shoes"]

@export var base_stats: BaseCharacterStats

@onready var buff_component: PlayerBuffComponent = $PlayerBuffComponent
@onready var needs_decay: NeedsDecayComponent = $NeedsDecayComponent

var stats: BaseCharacterStats

var facing := Vector2.DOWN
var ground_type: String = ""
var _ground_layers: Array[TileMapLayer] = []

@export var is_freeze: bool = false

func _ready() -> void:
	if Inventory.player_stats == null:
		Inventory.player_stats = base_stats.duplicate()
		Inventory.player_stats.setup_stats()
	stats = Inventory.player_stats
	buff_component.bind(stats)
	needs_decay.stats = stats
	_ground_layers = TileUtils.ground_layers(owner)
	body.frame_changed.connect(_sync_layers)
	body.animation_changed.connect(_sync_layers)
	body.animation_finished
	for part in OUTFIT_PARTS.size():
		equip(part, Inventory.get_vanity(part))
	Inventory.selected_slot_changed.connect(_equip_selected.unbind(1))
	Inventory.inventory_updated.connect(_equip_selected)
	_equip_selected()
		
func get_terrain_type() -> String:
	return TileUtils.terrain_at(_ground_layers, global_position)

func _process(_delta: float) -> void:
	if is_freeze:
		return
	tool_layer.aim_at(get_global_mouse_position())

func consume_selected() -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if is_freeze:
		return
	var slot := GameInputEvents.number_key_input(event)
	if slot >= 0:
		Inventory.select_slot(slot)
		get_viewport().set_input_as_handled()


func _equip_selected() -> void:
	var item := Inventory.get_selected_item()
	tool_layer.set_tool(String(item.item_id) if item != null else "")
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
