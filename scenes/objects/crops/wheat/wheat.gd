extends Node2D

var wheat_harvest_scene = preload("res://scenes/objects/crops/wheat/wheat_harvest.tscn")
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var flowering_particles: GPUParticles2D = $FloweringParticles
@onready var watering_particles: GPUParticles2D = $WateringParticles
@onready var growth_cycle_component: GrowthCycleComponent = $GrowthCycleComponent
@onready var farming_hurt_component: FarmingHurtComponent = $FarmingHurtComponent
@export var growth_textures: Array[Texture2D] = []

var growth_state: ApoDataTypes.GrowthStates = ApoDataTypes.GrowthStates.Seed

var _shown_state: int = -1

## 수확은 한 번뿐. HitComponent가 계속 monitoring 상태라 area_entered가 연달아
## 들어올 수 있는데, 막지 않으면 드롭이 여러 개 생긴다.
var _harvested: bool = false

func _ready() -> void:
	watering_particles.emitting = false
	flowering_particles.emitting = false

	farming_hurt_component.hurt.connect(on_hurt)
	apply_growth_texture(growth_state)

func _process(delta: float) -> void:
	growth_state = growth_cycle_component.get_current_growth_state()

	if growth_state != _shown_state:
		apply_growth_texture(growth_state)

	if growth_state == ApoDataTypes.GrowthStates.Maturity:
		flowering_particles.emitting = true

func apply_growth_texture(state: int) -> void:
	if growth_textures.is_empty():
		return

	_shown_state = state
	var tex: Texture2D = growth_textures[clampi(state, 0, growth_textures.size() - 1)]
	sprite_2d.texture = tex

	sprite_2d.offset = Vector2(-tex.get_size().x * 0.5, -tex.get_size().y)

func on_hurt(hit_damage: int) -> void:
	# 다 자랐으면 물주기가 아니라 수확이다.
	if growth_state == ApoDataTypes.GrowthStates.Maturity:
		harvest()
		return

	if !growth_cycle_component.is_watered:
		watering_particles.emitting = true
		await get_tree().create_timer(5.0).timeout
		watering_particles.emitting = false
		growth_cycle_component.is_watered = true

## 작물을 제거하고 같은 자리에 획득 가능한 아이템을 떨군다.
func harvest() -> void:
	if _harvested:
		return
	_harvested = true

	var drop: Node2D = wheat_harvest_scene.instantiate()
	# 같은 부모에 붙이므로 로컬 좌표를 그대로 물려주면 위치가 맞는다.
	drop.position = position
	# area_entered(물리 콜백) 안에서 호출되므로 add_child는 지연시켜야 한다.
	get_parent().add_child.call_deferred(drop)
	queue_free()


func on_crop_maturity() -> void:
	flowering_particles.emitting = true
