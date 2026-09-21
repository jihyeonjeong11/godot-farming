@tool
class_name ObjectInstance
extends Sprite2D

const ITEM_STACK_INSTANCE := preload("res://scenes/objects/pickables/item_stack_instance.tscn")
const SHAKE_SHADER := preload("res://scenes/objects/placables/object_shake.gdshader")
const CROSS_ICON := preload("res://assets/temp/cross.png")
const PROCESS_SLOT := preload("res://scenes/ui/process_slot.tscn")
const PROCESS_SLOT_GAP := 4.0
const SCATTER_TIME := 0.25
const SLEEP_FADE_DURATION := 0.4
const SLEEP_DURATION := 1.5
const WAKE_HOUR := 6

@export var object: PlaceableObject: set = set_object

var current_health: int
var shake_tween: Tween
var current_animation: StringName
var inventory: ContainerInventoryComponent
var process_slot: ProcessSlot
var process_state: Dictionary = {}
var _frame: int = 0
var _frame_time: float = 0.0
var _sleeping: bool = false

@onready var hurt_component: HurtComponent = $Hurtbox
@onready var hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var body_shape: CollisionShape2D = get_node_or_null(^"StaticBody2D/CollisionShape2D")


func _ready() -> void:
	if Engine.is_editor_hint():
		_refresh_visual()
		return

	hurt_component.hurt.connect(on_hurt)
	SignalBus.time_tick.connect(_on_time_tick)
	_refresh()
	add_to_group("object")


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
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
	if Engine.is_editor_hint():
		_refresh_visual()
		return
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

	hurt_component.release_effects()
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
		DataTypes.InteractableActions.Process:
			process()


func process() -> void:
	if not process_state.is_empty():
		if _process_done():
			_collect_result()
		return

	var held := Inventory.get_selected_item()
	if held == null:
		return

	var recipe := _recipe_for(held)
	if recipe == null:
		return

	var missing := _missing_ingredients(recipe)
	if not missing.is_empty():
		for item in missing:
			SignalBus.toast_requested.emit(CROSS_ICON, "Needs %d more %s" % [missing[item], item.item_name])
		return

	for id in recipe.ingredients:
		Inventory.consume_item(ItemDB.get_item(id), recipe.ingredients[id])

	var now := _now_minutes()
	process_state = {
		"recipe": recipe.resource_path,
		"started_at": now,
		"done_at": now + recipe.process_minutes,
	}
	play_animation(object.toggle_animation)
	if not object.toggle_on_sfx.is_empty():
		SignalBus.sound_requested.emit(object.toggle_on_sfx)
	_show_process_slot(recipe)
	_refresh_process(now)


func _show_process_slot(recipe: CraftRecipe) -> void:
	if process_slot == null:
		process_slot = PROCESS_SLOT.instantiate() as ProcessSlot
		add_child(process_slot)
		var top := -texture.get_size().y * 0.5 if centered else offset.y
		process_slot.position = Vector2(-process_slot.size.x * 0.5, top - process_slot.size.y - PROCESS_SLOT_GAP)
	process_slot.show_result(recipe.result_item(), maxi(recipe.result_amount, 1))


func _now_minutes() -> int:
	var tm := TimeManager.find(get_tree())
	return tm.total_minutes() if tm != null else 0


func _process_done() -> bool:
	return _now_minutes() >= int(process_state.get("done_at", 0))


func _on_time_tick(day: int, hour: int, minute: int) -> void:
	if process_state.is_empty():
		return
	_refresh_process(TimeManager.minutes_of(day, hour, minute))


func _refresh_process(now: int) -> void:
	var started: int = process_state["started_at"]
	var done: int = process_state["done_at"]
	var ratio := 1.0 if done <= started else float(now - started) / float(done - started)
	if process_slot != null:
		process_slot.set_progress(ratio)

	if now >= done and current_animation != object.default_animation:
		play_animation(object.default_animation)
		if not object.toggle_off_sfx.is_empty():
			SignalBus.sound_requested.emit(object.toggle_off_sfx)


func _collect_result() -> void:
	var recipe := load(process_state["recipe"]) as CraftRecipe
	if recipe == null:
		process_state = {}
		process_slot.clear()
		return

	var stack := ItemStack.new(recipe.result_item(), maxi(recipe.result_amount, 1))
	if not Inventory.add_item(stack):
		SignalBus.toast_requested.emit(CROSS_ICON, "Inventory full")
		return

	SignalBus.sound_requested.emit("ITEM_PICKUP")
	process_state = {}
	process_slot.clear()


func _recipe_for(held: Item) -> CraftRecipe:
	var held_id := StringName(held.item_id)
	for recipe in object.recipes:
		if recipe != null and recipe.ingredients.has(held_id):
			return recipe
	return null


func _missing_ingredients(recipe: CraftRecipe) -> Dictionary[Item, int]:
	var missing: Dictionary[Item, int] = {}
	for id in recipe.ingredients:
		var need := ItemDB.get_item(id)
		if need == null:
			continue
		var short: int = recipe.ingredients[id] - Inventory.count_item(need)
		if short > 0:
			missing[need] = short
	return missing


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
	if not process_state.is_empty():
		state["process"] = process_state.duplicate()
	return state


func apply_state(state: Variant) -> void:
	if state is not Dictionary:
		return

	var animation := StringName(state.get("anim", ""))
	if not animation.is_empty():
		play_animation(animation)
	if inventory != null and state.get("inventory") is Array:
		inventory.apply(state["inventory"])

	process_state = {}
	if state.get("process") is Dictionary:
		var recipe := load(state["process"].get("recipe", "")) as CraftRecipe
		if recipe != null:
			process_state = state["process"].duplicate()
			_show_process_slot(recipe)
			_refresh_process(_now_minutes())


func sleep() -> void:
	if _sleeping:
		return

	_sleeping = true

	await ScreenFade.fade_out(SLEEP_FADE_DURATION)
	await get_tree().create_timer(SLEEP_DURATION).timeout

	var tm := TimeManager.find(get_tree())
	if tm != null:
		tm.skip_to(tm.today() + 1, WAKE_HOUR)

	await ScreenFade.fade_in(SLEEP_FADE_DURATION)

	_sleeping = false


func roll_loot() -> Array[ItemStack]:
	var stacks: Array[ItemStack] = []
	if object == null:
		return stacks
	for loot in object.dropped_items:
		if loot == null or loot.item == null:
			continue
		stacks.append(ItemStack.new(loot.item, randi_range(loot.min, loot.max)))
	return stacks


func drop_loot() -> void:
	var host := get_parent()
	if host == null or object == null:
		return

	var dropped: Array[Node2D] = []
	for stack in roll_loot():
		for i in stack.amount:
			var instance := ITEM_STACK_INSTANCE.instantiate() as ItemStackInstance
			instance.stack = ItemStack.new(stack.item, 1)
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

	_refresh_visual()
	_refresh_inventory()
	_refresh_hurtbox()
	_refresh_body()
	_refresh_shake()
	_refresh_radiation()


func _refresh_visual() -> void:
	if object == null:
		texture = null
		return

	texture = object.object_texture
	centered = object.centered
	offset = Vector2(object.offset)
	scale = Vector2.ONE * object.sprite_scale

	current_animation = &""
	if object.sprite_frames != null:
		play_animation(object.default_animation)


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


func _refresh_radiation() -> void:
	var features := _map_features()
	if features == null:
		return
	features.unregister(self)
	features.register(self)


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	var features := _map_features()
	if features != null:
		features.unregister(self)


func _map_features() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().get_first_node_in_group(&"map_features")


func _refresh_body() -> void:
	if body_shape == null:
		return

	if object.collision_size != Vector2i.ZERO:
		var rect := RectangleShape2D.new()
		rect.size = Vector2(object.collision_size)
		body_shape.shape = rect
	else:
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
