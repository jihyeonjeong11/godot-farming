@tool
class_name TreeObject extends WorldObject

const BASE_SIZE := Vector2(24, 12)
const SHAKE_SHADER := preload("res://shaders/object_shake.gdshader")
const FALL_SHADER := preload("res://shaders/object_fall.gdshader")
const SHAKE_INTENSITY := 2.0
const SHAKE_SPEED := 22.0
const SHAKE_DURATION := 0.3
const FALL_ANGLE := PI / 2.0
const FALL_DURATION := 0.7
const FADE_DURATION := 0.25

var state: Dictionary = {
	"health": 1,
	"growth_stage": 0,
	"days_until_harvest": 0,
}
var shake_tween: Tween
var is_falling := false

@onready var collision_shape_2d: CollisionShape2D = $StaticBody2D/CollisionShape2D

func _ready() -> void:
	if data != null and not Engine.is_editor_hint():
		state["health"] = tree_data().health_at(int(state["growth_stage"]))
		state["days_until_harvest"] = data.days_until_harvest
		state = SnapshotActions.populate(global_position, data.id, state)
	super()
	if Engine.is_editor_hint() or data == null:
		return
	_setup_shake()
	TimeManager.day_passed.connect(on_day_passed)


func tree_data() -> TreeObjectData:
	return data as TreeObjectData


const GROW_CHANCE := 0.2


static func grow(tree_state: Dictionary, tree_data: TreeObjectData, can_mature: bool) -> void:
	var final_stage := tree_data.max_growth_stage
	var current := int(tree_state["growth_stage"])
	if current >= final_stage:
		return
	if current == final_stage - 1 and not can_mature:
		return
	if randf() >= GROW_CHANCE:
		return
	tree_state["growth_stage"] = current + 1
	tree_state["health"] = tree_data.health_at(current + 1)


func on_day_passed(_day: int) -> void:
	if is_falling:
		return
	_apply_data()
	_setup_shake()


func on_hit(tool: DataTypes.Tools, damage: int) -> void:
	if is_falling:
		return
	if damage >= state["health"]:
		destroy()
	else:
		state["health"] -= damage
		play_shake()


func destroy() -> void:
	LootActions.drop_loot(tree_data().loot_at(int(state["growth_stage"])), global_position)
	SnapshotActions.remove(global_position)
	remove_from_group(&"object")
	collision_shape_2d.set_deferred("disabled", true)
	play_fall()


func play_shake() -> void:
	var shake_material := sprite.material as ShaderMaterial
	if shake_material == null:
		return
	if shake_tween != null and shake_tween.is_valid():
		shake_tween.kill()
	shake_material.set_shader_parameter("shake_intensity", SHAKE_INTENSITY)
	shake_tween = create_tween()
	shake_tween.tween_property(shake_material, "shader_parameter/shake_intensity", 0.0, SHAKE_DURATION).set_ease(Tween.EASE_OUT)


func play_fall() -> void:
	is_falling = true
	if shake_tween != null and shake_tween.is_valid():
		shake_tween.kill()
	var fall_material := ShaderMaterial.new()
	fall_material.shader = FALL_SHADER
	fall_material.set_shader_parameter("base_y", 0.0)
	fall_material.set_shader_parameter("fall_angle", 0.0)
	sprite.material = fall_material
	var direction: float = [-1.0, 1.0].pick_random()
	var tween := create_tween()
	tween.tween_property(fall_material, "shader_parameter/fall_angle", FALL_ANGLE * direction, FALL_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(queue_free)


func _setup_shake() -> void:
	if sprite.texture == null:
		return
	var shake_material := ShaderMaterial.new()
	shake_material.shader = SHAKE_SHADER
	shake_material.set_shader_parameter("base_y", 0.0)
	shake_material.set_shader_parameter("bend_height", maxf(sprite.texture.get_height(), 1.0))
	shake_material.set_shader_parameter("shake_speed", SHAKE_SPEED)
	shake_material.set_shader_parameter("shake_intensity", 0.0)
	sprite.material = shake_material


func _apply_data() -> void:
	if not is_node_ready() or data == null:
		return
	var stage := int(state["growth_stage"])
	var tex: Texture2D = data.growth_textures[stage] if stage < data.growth_textures.size() else null
	sprite.texture = tex
	sprite.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height()) if tex else Vector2.ZERO
	_apply_collision(stage, tex)


func _apply_collision(stage: int, tex: Texture2D) -> void:
	if tex == null:
		collision_shape_2d.shape = null
		collision_shape_2d.disabled = true
		return
	var size := BASE_SIZE.min(tex.get_size())
	var rect := Rect2(Vector2(-size.x / 2.0, -size.y), size)
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision_shape_2d.shape = shape
	collision_shape_2d.position = rect.get_center()
	collision_shape_2d.disabled = stage == 0
