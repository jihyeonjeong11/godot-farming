extends Node2D

var potato_harvest_scene = preload("res://scenes/objects/crops/potato/potato_harvest.tscn")
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var flowering_particles: GPUParticles2D = $FloweringParticles
@onready var watering_particles: GPUParticles2D = $WateringParticles
@onready var growth_cycle_component: GrowthCycleComponent = $GrowthCycleComponent
@onready var farming_hurt_component: FarmingHurtComponent = $FarmingHurtComponent
@export var growth_textures: Array[Texture2D] = []

var growth_state: DataTypes.GrowthStates = DataTypes.GrowthStates.Seed

var _shown_state: int = -1

## 수확은 한 번뿐. HitComponent가 계속 monitoring 상태라 area_entered가 연달아
## 들어올 수 있는데, 막지 않으면 드롭이 여러 개 생긴다.
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

	# 물 준 상태는 FieldCursorComponent 가 타일에 칠한다. 여기선 연출만 한다.
	# 타일 상태로 막지 않는 건, 물뿌리개를 쓰면 tool_used 로 타일이 먼저 칠해지고
	# area_entered 는 다음 물리 프레임에 와서 이미 물 준 칸으로 보이기 때문이다.
	if watering_particles.emitting:
		return

	watering_particles.emitting = true
	await get_tree().create_timer(5.0).timeout
	watering_particles.emitting = false

## 우클릭으로 만져졌다. ObjectCursorComponent가 이 이름으로 부른다.
## 다 자랐을 때만 수확된다. 덜 자란 것을 눌러도 아무 일도 일어나지 않는다.
##
## 좌클릭(on_hurt) 경로는 그대로 둔다. 밀처럼 낫으로 베는 작물이 그쪽을 쓴다.
func interact() -> void:
	if growth_state != DataTypes.GrowthStates.Maturity:
		return

	harvest()


## 작물을 제거하고 같은 자리에 획득 가능한 아이템을 떨군다.
func harvest() -> void:
	if _harvested:
		return
	_harvested = true

	var drop: Node2D = potato_harvest_scene.instantiate()
	# 같은 부모에 붙이므로 로컬 좌표를 그대로 물려주면 위치가 맞는다.
	drop.position = position
	# area_entered(물리 콜백) 안에서 호출되므로 add_child는 지연시켜야 한다.
	get_parent().add_child.call_deferred(drop)
	queue_free()


func on_crop_maturity() -> void:
	flowering_particles.emitting = true
