@tool
class_name GrassObject extends WorldObject

const SHAKE_SHADER := preload("res://shaders/object_shake.gdshader")
const SHAKE_INTENSITY := 2.0
const SHAKE_SPEED := 22.0
const SHAKE_DURATION := 0.3
const FOOTSTEP_VEGETATION = preload("uid://ca2x0yqyi8ltc")
const CLUMPS := [
	Rect2(5, 32, 32, 30),
	Rect2(37, 34, 32, 26),
	Rect2(73, 32, 24, 32),
	Rect2(107, 36, 22, 26),
	Rect2(9, 64, 24, 26),
	Rect2(39, 68, 29, 28),
	Rect2(68, 64, 33, 32),
	Rect2(105, 66, 26, 28),
	Rect2(133, 46, 64, 50),
]
const WIDE_CLUMPS := [0, 4, 6, 7]
const BLADE_SLOTS := [Vector2(-7, -3), Vector2(7, -3), Vector2(-7, 10), Vector2(7, 10)]
const BLADE_JITTER := 3

var state: Dictionary = {
	"health": 1,
	"variant": -1
}
var shake_tween: Tween
var blades: Array[Sprite2D] = []

func _ready() -> void:
	if not Engine.is_editor_hint():
		state["health"] = data.max_health
		state = SnapshotActions.populate(global_position, data.id, state)
	super()
	if Engine.is_editor_hint():
		return
	_setup_shake()
	$InteractArea.body_entered.connect(_on_body_entered)
	$InteractArea.body_exited.connect(_on_body_exited)


func _apply_data() -> void:
	if not is_node_ready() or data == null or data.texture == null:
		return
	if state["variant"] < 0:
		state["variant"] = WIDE_CLUMPS.pick_random()
	var sheet := data.texture
	var origin := Vector2.ZERO
	if sheet is AtlasTexture:
		origin = sheet.region.position
		sheet = sheet.atlas
	_ensure_blades()
	y_sort_enabled = true
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(global_position.round()))
	for i in BLADE_SLOTS.size():
		var blade := sprite if i == 0 else blades[i - 1]
		var variant := int(state["variant"]) if i == 0 else int(WIDE_CLUMPS[rng.randi() % WIDE_CLUMPS.size()])
		var rect: Rect2 = CLUMPS[variant]
		var clump := AtlasTexture.new()
		clump.atlas = sheet
		clump.region = Rect2(origin + rect.position, rect.size)
		blade.texture = clump
		blade.offset = Vector2(floorf(-clump.get_width() / 2.0), -clump.get_height())
		blade.flip_h = rng.randf() < 0.5
		blade.position = BLADE_SLOTS[i] + Vector2(rng.randi_range(-BLADE_JITTER, BLADE_JITTER), rng.randi_range(-BLADE_JITTER, BLADE_JITTER))


func _ensure_blades() -> void:
	while blades.size() < BLADE_SLOTS.size() - 1:
		var blade := Sprite2D.new()
		blade.centered = false
		blade.material = sprite.material
		add_child(blade)
		blades.append(blade)


func _setup_shake() -> void:
	var shake_material := ShaderMaterial.new()
	shake_material.shader = SHAKE_SHADER
	shake_material.set_shader_parameter("base_y", 0.0)
	shake_material.set_shader_parameter("bend_height", maxf(sprite.texture.get_height(), 1.0))
	shake_material.set_shader_parameter("shake_speed", SHAKE_SPEED)
	shake_material.set_shader_parameter("shake_intensity", 0.0)
	sprite.material = shake_material
	for blade in blades:
		blade.material = shake_material


func play_shake() -> void:
	var shake_material := sprite.material as ShaderMaterial
	if shake_material == null:
		return
	if shake_tween != null and shake_tween.is_valid():
		shake_tween.kill()
	shake_material.set_shader_parameter("shake_intensity", SHAKE_INTENSITY)
	shake_tween = create_tween()
	shake_tween.tween_property(shake_material, "shader_parameter/shake_intensity", 0.0, SHAKE_DURATION).set_ease(Tween.EASE_OUT)

func on_hit(tool: DataTypes.Tools, damage: int) -> void:
	if damage >= state["health"]:
		destroy()
	else:
		state["health"] -= damage
	
func destroy() -> void:
	LootActions.drop_loot(data.loot_pool, global_position)
	SnapshotActions.remove(global_position)
	queue_free()
	


func _on_body_entered(_body: Node2D) -> void:
	SoundManager.play_ambient_sound(FOOTSTEP_VEGETATION)
	play_shake()


func _on_body_exited(_body: Node2D) -> void:
	SoundManager.stop_ambient_sound(FOOTSTEP_VEGETATION)
