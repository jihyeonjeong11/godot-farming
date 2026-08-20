extends Node2D

var wheat_harvest_scene = preload("res://scenes/objects/crops/wheat/wheat_harvest.tscn")
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var flowering_particles: GPUParticles2D = $FloweringParticles
@onready var watering_particles: GPUParticles2D = $WateringParticles
@onready var growth_cycle_component: GrowthCycleComponent = $GrowthCycleComponent
@onready var farming_hurt_component: FarmingHurtComponent = $FarmingHurtComponent
@export var growth_textures: Array[Texture2D] = []

var growth_state: DataTypes.GrowthStates = DataTypes.GrowthStates.Seed

var _shown_state: int = -1

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

	if growth_state == DataTypes.GrowthStates.Maturity:
		flowering_particles.emitting = true

func apply_growth_texture(state: int) -> void:
	if growth_textures.is_empty():
		return

	_shown_state = state
	var tex: Texture2D = growth_textures[clampi(state, 0, growth_textures.size() - 1)]
	sprite_2d.texture = tex

	sprite_2d.offset = Vector2(-tex.get_size().x * 0.5, -tex.get_size().y)

func on_hurt(hit_damage: int) -> void:
	if growth_state == DataTypes.GrowthStates.Maturity:
		harvest()
		return
	if watering_particles.emitting:
		return

	watering_particles.emitting = true
	await get_tree().create_timer(5.0).timeout
	watering_particles.emitting = false

func harvest() -> void:
	if _harvested:
		return
	_harvested = true

	var drop: Node2D = wheat_harvest_scene.instantiate()
	drop.position = position
	get_parent().add_child.call_deferred(drop)
	queue_free()


func on_crop_maturity() -> void:
	flowering_particles.emitting = true
