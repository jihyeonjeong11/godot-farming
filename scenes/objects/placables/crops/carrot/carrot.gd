extends Node2D

const DROPPED_ITEM := preload("res://scenes/objects/pickables/dropped_item.tscn")

## 수확하면 나올 것. 떨어진 물건 쪽은 공용 dropped_item.tscn 하나를 돌려쓴다.
@export var harvest_item: Item
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
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

func interact() -> void:
	if growth_state != DataTypes.GrowthStates.Maturity:
		return

	harvest()


func harvest() -> void:
	if _harvested:
		return
	_harvested = true

	var drop: Node2D = DROPPED_ITEM.instantiate()
	# add_child가 _ready를 돌리므로 그 전에 무엇인지 알려준다.
	drop.item = harvest_item
	drop.position = position
	get_parent().add_child.call_deferred(drop)
	queue_free()


func on_crop_maturity() -> void:
	flowering_particles.emitting = true


func capture_state() -> Variant:
	return growth_cycle_component.capture()


func apply_state(state: Variant) -> void:
	growth_cycle_component.apply(state)
	growth_state = growth_cycle_component.get_current_growth_state()
	apply_growth_texture(growth_state)
