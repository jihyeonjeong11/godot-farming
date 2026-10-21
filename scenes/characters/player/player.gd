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
@onready var hit_component: HitComponent = $HitComponent
@onready var hit_shape: CollisionShape2D = $HitComponent/CollisionShape2D

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
		equip(part, GameState.player_vanity[part])
	InventoryManager.stack_selected.connect(_equip_selected.unbind(1))
	InventoryManager.updated_inventory.connect(_equip_selected)
	_equip_selected()
		
func get_terrain_type() -> String:
	return TileUtils.terrain_at(_ground_layers, global_position)

func _process(_delta: float) -> void:
	if is_freeze:
		return
	tool_layer.aim_at(get_global_mouse_position())
	
func emitSound() -> void:
	
	pass

func _unhandled_input(event: InputEvent) -> void:
	if is_freeze:
		return
	
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				InventoryActions.consume(GameState.selected_slot)
			MOUSE_BUTTON_WHEEL_DOWN:
				InventoryActions.quickbar_select(wrapi(GameState.selected_slot + 1, 0, InventoryManager.QUICKBAR_LIMIT))
			MOUSE_BUTTON_WHEEL_UP:
				InventoryActions.quickbar_select(wrapi(GameState.selected_slot - 1, 0, InventoryManager.QUICKBAR_LIMIT))
			_:
				return
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1, KEY_KP_1:
				InventoryActions.quickbar_select(0)
			KEY_2, KEY_KP_2:
				InventoryActions.quickbar_select(1)
			KEY_3, KEY_KP_3:
				InventoryActions.quickbar_select(2)
			KEY_4, KEY_KP_4:
				InventoryActions.quickbar_select(3)
			KEY_5, KEY_KP_5:
				InventoryActions.quickbar_select(4)
			KEY_6, KEY_KP_6:
				InventoryActions.quickbar_select(5)
			KEY_7, KEY_KP_7:
				InventoryActions.quickbar_select(6)
			KEY_8, KEY_KP_8:
				InventoryActions.quickbar_select(7)
			KEY_9, KEY_KP_9:
				InventoryActions.quickbar_select(8)
			KEY_0, KEY_KP_0:
				InventoryActions.quickbar_select(9)
			_:
				return
		get_viewport().set_input_as_handled()



func _equip_selected() -> void:
	var stack := InventoryManager.get_item_stack_by_index(GameState.selected_slot)
	var item := stack.item if stack != null else null
	tool_layer.set_tool(String(item.item_id) if item != null else "")
	tool_layer.set_melee(item.item_texture if item != null and item.item_type == DataTypes.ItemType.Melee else null)
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
	_sync_layers()


func _outfit_layer(part: int) -> Sprite2D:
	return body.get_node(OUTFIT_PARTS[part]) as Sprite2D


func play_action(action: String) -> void:
	var directional := "%s_%s" % [action, DIR_SUFFIX[facing]]
	body.play(directional if body.sprite_frames.has_animation(directional) else action)
	_sync_layers()


func begin_melee(item: Item) -> void:
	hit_component.current_tool = item.tool_type
	hit_component.hit_damage = item.melee_damage
	hit_component.knockback_vector = facing
	var shape := item.melee_shape
	if shape == null:
		var circle := CircleShape2D.new()
		circle.radius = item.melee_radius
		shape = circle
	hit_shape.shape = shape
	var hand: Vector2 = hit_component.to_local(body.to_global(tool_layer.melee_pivot()))
	hit_shape.position = hand + facing * item.melee_reach
	hit_shape.rotation = facing.angle()
	hit_shape.set_deferred("disabled", false)


func end_melee() -> void:
	hit_shape.set_deferred("disabled", true)


func action_length() -> float:
	var frames := body.sprite_frames
	var fps := frames.get_animation_speed(body.animation)
	if fps <= 0.0:
		return 0.0
	var total := 0.0
	for i in frames.get_frame_count(body.animation):
		total += frames.get_frame_duration(body.animation, i)
	return total / fps


func _sync_layers() -> void:
	for layer in body.get_children():
		if layer.has_method("sync"):
			layer.sync(body.animation, body.frame)
