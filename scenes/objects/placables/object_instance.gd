class_name ObjectInstance
extends Sprite2D

const ITEM_STACK_INSTANCE := preload("res://scenes/objects/pickables/item_stack_instance.tscn")
const SHAKE_SHADER := preload("res://scenes/objects/placables/object_shake.gdshader")
const SCATTER_TIME := 0.25
const SLEEP_FADE_DURATION := 0.4
const SLEEP_DURATION := 1.5
const WAKE_HOUR := 6

@export var object: PlaceableObject: set = set_object

var current_health: int
var shake_tween: Tween
var current_animation: StringName
var inventory: ContainerInventoryComponent
var _frame: int = 0
var _frame_time: float = 0.0
var _sleeping: bool = false

@onready var hurt_component: HurtComponent = $Hurtbox
@onready var hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var body_shape: CollisionShape2D = get_node_or_null(^"StaticBody2D/CollisionShape2D")


func _ready() -> void:
	hurt_component.hurt.connect(on_hurt)
	_refresh()
	add_to_group("object")
	if object != null and object.interactable_actions != DataTypes.InteractableActions.None:
		add_to_group("interactables")


func _process(delta: float) -> void:
	if object == null or object.sprite_frames == null or current_animation.is_empty():
		return

	var frames := object.sprite_frames
	var speed := frames.get_animation_speed(current_animation)
	if speed <= 0.0:
		return

	_frame_time += delta
	var duration := frames.get_frame_duration(current_animation, _frame) / speed
	while _frame_time >= duration:
		_frame_time -= duration
		var count := frames.get_frame_count(current_animation)
		if _frame + 1 >= count:
			if not frames.get_animation_loop(current_animation):
				_frame_time = 0.0
				return
			_frame = 0
		else:
			_frame += 1
		texture = frames.get_frame_texture(current_animation, _frame)
		duration = frames.get_frame_duration(current_animation, _frame) / speed


func set_object(value: PlaceableObject) -> void:
	object = value
	current_health = value.object_max_health if value != null else 0
	if is_node_ready():
		_refresh()


func on_hurt(hit_damage: int) -> void:
	if inventory != null and not inventory.is_empty():
		play_shake()
		return

	current_health -= hit_damage
	if current_health > 0:
		play_shake()
		return

	drop_loot.call_deferred()
	queue_free()


func interact() -> void:
	if object == null:
		return

	match object.interactable_actions:
		DataTypes.InteractableActions.Sleep:
			sleep()
		DataTypes.InteractableActions.Toggle:
			toggle()
		DataTypes.InteractableActions.Open:
			if inventory != null:
				SignalBus.container_opened.emit(inventory.slots)


func toggle() -> void:
	var turning_on := current_animation != object.toggle_animation
	play_animation(object.toggle_animation if turning_on else object.default_animation)
	var sfx := object.toggle_on_sfx if turning_on else object.toggle_off_sfx
	if not sfx.is_empty():
		SignalBus.sound_requested.emit(sfx)


func play_animation(animation: StringName) -> void:
	if object == null or object.sprite_frames == null or not object.sprite_frames.has_animation(animation):
		return

	current_animation = animation
	_frame = 0
	_frame_time = 0.0
	texture = object.sprite_frames.get_frame_texture(animation, 0)


func capture_state() -> Variant:
	var state := {}
	if not current_animation.is_empty():
		state["anim"] = String(current_animation)
	if inventory != null:
		state["inventory"] = inventory.capture()
	return state


func apply_state(state: Variant) -> void:
	if state is not Dictionary:
		return

	var animation := StringName(state.get("anim", ""))
	if not animation.is_empty():
		play_animation(animation)
	if inventory != null and state.get("inventory") is Array:
		inventory.apply(state["inventory"])


func sleep() -> void:
	if _sleeping:
		return

	_sleeping = true

	await ScreenFade.fade_out(SLEEP_FADE_DURATION)
	await get_tree().create_timer(SLEEP_DURATION).timeout

	DayAndNightCycle.skip_to(DayAndNightCycle.current_day + 1, WAKE_HOUR)

	await ScreenFade.fade_in(SLEEP_FADE_DURATION)

	_sleeping = false


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
	scale = Vector2.ONE * object.sprite_scale

	current_animation = &""
	if object.sprite_frames != null:
		play_animation(object.default_animation)

	_refresh_inventory()
	_refresh_hurtbox()
	_refresh_body()
	_refresh_shake()


func _refresh_inventory() -> void:
	var chest := object as Chest
	if chest == null:
		if inventory != null:
			inventory.queue_free()
			inventory = null
		return

	if inventory == null:
		inventory = ContainerInventoryComponent.new()
		inventory.name = "ContainerInventoryComponent"
		add_child(inventory)

	inventory.slot_count = chest.slot_count
	inventory.slots.resize(chest.slot_count)
	inventory.fill(chest.initial_items, chest.initial_amounts)


func _refresh_hurtbox() -> void:
	hurt_component.tool = object.destructible_tool
	var sound := hurt_component.tool_hit_sound()
	if sound != null:
		hurt_component.hit_audio_stream_player.stream = sound

	var circle := CircleShape2D.new()
	circle.radius = float(object.hurtbox_radius)
	hurtbox_shape.shape = circle
	hurtbox_shape.position = Vector2(object.hurtbox_offset)


func play_shake() -> void:
	var shake_material := material as ShaderMaterial
	if shake_material == null:
		return

	if shake_tween != null and shake_tween.is_valid():
		shake_tween.kill()

	shake_material.set_shader_parameter("shake_intensity", object.shake_intensity)
	shake_tween = create_tween()
	shake_tween.tween_property(
		shake_material, "shader_parameter/shake_intensity", 0.0, object.shake_duration
	).set_ease(Tween.EASE_OUT)


func _refresh_shake() -> void:
	if object.shake_intensity <= 0.0 or texture == null:
		material = null
		return

	var height := texture.get_size().y
	var shake_material := ShaderMaterial.new()
	shake_material.shader = SHAKE_SHADER
	shake_material.set_shader_parameter("base_y", height * 0.5 if centered else offset.y + height)
	shake_material.set_shader_parameter(
		"bend_height", object.shake_bend_height if object.shake_bend_height > 0.0 else maxf(height, 1.0)
	)
	shake_material.set_shader_parameter("shake_speed", object.shake_speed)
	shake_material.set_shader_parameter("shake_intensity", 0.0)
	material = shake_material


func _refresh_body() -> void:
	if body_shape == null:
		return

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
