@tool
class_name CropObject extends WorldObject

const BASE_SIZE := Vector2(24, 12)
const SHAKE_SHADER := preload("res://shaders/object_shake.gdshader")
const SHAKE_INTENSITY := 2.0
const SHAKE_SPEED := 22.0
const SHAKE_DURATION := 0.3
const SHAKE_AREA_MARGIN := Vector2(8, 8)

@onready var collision_shape_2d: CollisionShape2D = $StaticBody2D/CollisionShape2D
@onready var interact_shape_2d: CollisionShape2D = $InteractArea/CollisionShape2D

var watered_days := 0
var start_stage := -1
var shake_tween: Tween

const FOOTSTEP_VEGETATION = preload("uid://ca2x0yqyi8ltc")

func _ready() -> void:
	super()
	if Engine.is_editor_hint() or data == null:
		return
	data = data.duplicate() as WorldObjectData
	if start_stage < 0:
		start_stage = data.growth_stage
	TimeManager.day_passed.connect(on_day_passed)
	$InteractArea.body_entered.connect(_on_body_entered)
	$InteractArea.body_exited.connect(_on_body_exited)



func capture_state() -> Dictionary:
	return {"watered_days": watered_days, "start_stage": start_stage}


func apply_state(state: Dictionary) -> void:
	watered_days = state["watered_days"]
	start_stage = state["start_stage"]


func is_harvestable() -> bool:
	return data != null and data.growth_stage == data.max_growth_stage


func is_regrowing() -> bool:
	return data != null and data.growth_stage > data.max_growth_stage


func is_tile_watered() -> bool:
	var watered := get_tree().get_first_node_in_group(WateredSoilLayer.GROUP) as WateredSoilLayer
	if watered == null:
		return false
	
	return watered.is_watered(watered.local_to_map(watered.to_local(global_position)))


func on_day_passed() -> void:
	if not is_tile_watered():
		return
	watered_days += 1
	growth_states()


func growth_states() -> void:
	if is_harvestable():
		return
	var final_stage := data.max_growth_stage
	if is_regrowing():
		if watered_days >= data.regrow_days:
			data.growth_stage = final_stage
			_apply_data()
		return
	var span := final_stage - start_stage
	var stage := start_stage + roundi(float(watered_days) * span / maxi(data.days_until_harvest, 1))
	data.growth_stage = clampi(stage, mini(start_stage + 1, final_stage), final_stage)
	_apply_data()


func _apply_data() -> void:
	if not is_node_ready() or data == null:
		return
	var stage := data.growth_stage
	var tex: Texture2D = data.growth_textures[stage] if stage < data.growth_textures.size() else null
	sprite.texture = tex
	sprite.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height()) if tex else Vector2.ZERO
	_apply_collision(tex)
	_apply_interact_area(tex)
	_apply_shake(tex)

func on_interact() -> void:
	play_shake()
	if is_harvestable():
		if data.loot:
			SoundManager.play_sound(preload("uid://dtkma6bmtb12v"))
			InventoryActions.obtain(ItemStack.new(data.loot))
		if data.regrow_days > 0:
			# go to last stage and wait for regrow
			watered_days = 0
			data.growth_stage = data.max_growth_stage + 1
			_apply_data()
		else:
			# loot generation
			queue_free()
	

func _apply_collision(tex: Texture2D) -> void:
	if tex == null:
		collision_shape_2d.shape = null
		collision_shape_2d.disabled = true
		return
	if is_harvestable():
		var shape := RectangleShape2D.new()
		shape.size = tex.get_size()
		collision_shape_2d.shape = shape
		collision_shape_2d.position = Vector2(0, -shape.size.y / 2.0)
		collision_shape_2d.disabled = true
		return
	var size := BASE_SIZE.min(tex.get_size())
	var shape := RectangleShape2D.new()
	shape.size = size
	collision_shape_2d.shape = shape
	collision_shape_2d.position = Vector2(0, -size.y / 2.0)
	if data.is_raised == false:
		collision_shape_2d.disabled = true
	else:
		collision_shape_2d.disabled = false


func _apply_interact_area(tex: Texture2D) -> void:
	if tex == null:
		interact_shape_2d.shape = null
		return
	var foot := BASE_SIZE.min(tex.get_size())
	var shape := RectangleShape2D.new()
	shape.size = foot + SHAKE_AREA_MARGIN
	interact_shape_2d.shape = shape
	interact_shape_2d.position = Vector2(0, -foot.y / 2.0)


func _apply_shake(tex: Texture2D) -> void:
	if tex == null:
		sprite.material = null
		return
	var shake_material := sprite.material as ShaderMaterial
	if shake_material == null:
		shake_material = ShaderMaterial.new()
		shake_material.shader = SHAKE_SHADER
		shake_material.set_shader_parameter("base_y", 0.0)
		shake_material.set_shader_parameter("shake_speed", SHAKE_SPEED)
		shake_material.set_shader_parameter("shake_intensity", 0.0)
		sprite.material = shake_material
	shake_material.set_shader_parameter("bend_height", maxf(tex.get_height(), 1.0))


func play_shake() -> void:
	var shake_material := sprite.material as ShaderMaterial
	if shake_material == null:
		return
	if shake_tween != null and shake_tween.is_valid():
		shake_tween.kill()
	shake_material.set_shader_parameter("shake_intensity", SHAKE_INTENSITY)
	shake_tween = create_tween()
	shake_tween.tween_property(shake_material, "shader_parameter/shake_intensity", 0.0, SHAKE_DURATION).set_ease(Tween.EASE_OUT)


func _on_body_entered(_body: Node2D) -> void:
	SoundManager.play_ambient_sound(FOOTSTEP_VEGETATION)
	play_shake()
	
func _on_body_exited(_body: Node2D) -> void:
	SoundManager.play_ambient_sound(FOOTSTEP_VEGETATION)
