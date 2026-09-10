class_name ObjectInstance
extends Sprite2D

const ITEM_STACK_INSTANCE := preload("res://scenes/objects/pickables/item_stack_instance.tscn")
const SCATTER_TIME := 0.25

@export var object: PlaceableObject: set = set_object

var current_health: int

@onready var hurt_component: HurtComponent = $Hurtbox
@onready var hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var body_shape: CollisionShape2D = $StaticBody2D/CollisionShape2D


func _ready() -> void:
	hurt_component.hurt.connect(on_hurt)
	_refresh()


func set_object(value: PlaceableObject) -> void:
	object = value
	current_health = value.object_max_health if value != null else 0
	if is_node_ready():
		_refresh()


func on_hurt(hit_damage: int) -> void:
	current_health -= hit_damage
	if current_health > 0:
		return

	drop_loot.call_deferred()
	queue_free()


func drop_loot() -> void:
	var host := get_parent()
	if host == null or object == null:
		return

	var dropped: Array[Node2D] = []
	for loot in object.dropped_items:
		if loot == null or loot.item == null:
			continue
		for i in randi_range(loot.min, loot.max):
			var instance := ITEM_STACK_INSTANCE.instantiate() as ItemStackInstance
			instance.stack = ItemStack.new(loot.item, 1)
			host.add_child(instance)
			instance.global_position = global_position
			dropped.append(instance)

	for i in dropped.size():
		var target := global_position + _scatter_offset(i, dropped.size())
		dropped[i].create_tween().tween_property(
			dropped[i], "global_position", target, SCATTER_TIME
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _refresh() -> void:
	if object == null:
		return

	texture = object.object_texture
	centered = object.centered
	offset = Vector2(object.offset)

	_refresh_hurtbox()
	_refresh_body()


func _refresh_hurtbox() -> void:
	hurt_component.tool = object.destructible_tool
	var sound := hurt_component.tool_hit_sound()
	if sound != null:
		hurt_component.hit_audio_stream_player.stream = sound

	var circle := CircleShape2D.new()
	circle.radius = float(object.hurtbox_radius)
	hurtbox_shape.shape = circle
	hurtbox_shape.position = Vector2(object.hurtbox_offset)


func _refresh_body() -> void:
	var circle := CircleShape2D.new()
	circle.radius = float(object.collision_radius)
	body_shape.shape = circle
	body_shape.position = Vector2(object.collision_offset)


func _scatter_offset(index: int, total: int) -> Vector2:
	if total <= 1:
		return Vector2.DOWN * object.scatter_radius

	var t := float(index) / float(total - 1)
	var angle := lerpf(PI * 0.15, PI * 0.85, t)
	return Vector2.RIGHT.rotated(angle) * object.scatter_radius
