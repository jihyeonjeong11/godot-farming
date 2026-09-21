class_name CropInstance
extends ObjectInstance

const WATERING_EFFECT_TIME := 5.0

var crop: Crops:
	get:
		return object as Crops

var growth_state: DataTypes.GrowthStates = DataTypes.GrowthStates.Seed
var harvest_count: int = 0
var genetics: CropGenetics = CropGenetics.new()
var _gene_day: int = -1
var _shown_state: int = -1
var _harvested: bool = false

@onready var growth_cycle_component: GrowthCycleComponent = $GrowthCycleComponent
@onready var flowering_particles: GPUParticles2D = $FloweringParticles
@onready var watering_particles: GPUParticles2D = $WateringParticles


func _ready() -> void:
	super()
	watering_particles.emitting = false
	flowering_particles.emitting = false
	growth_cycle_component.crop_maturity.connect(on_crop_maturity)
	SignalBus.time_tick_day.connect(_on_time_tick_day)
	_configure_growth()
	growth_state = growth_cycle_component.get_current_growth_state()
	apply_growth_texture(growth_state)
	_gene_day = _today()
	_refresh_genetics_visual()
	if growth_state == DataTypes.GrowthStates.Maturity:
		on_crop_maturity()


func _process(_delta: float) -> void:
	growth_state = growth_cycle_component.get_current_growth_state()
	if growth_state != _shown_state:
		apply_growth_texture(growth_state)


func on_hurt(_hit_damage: int) -> void:
	queue_free()


func interact() -> void:
	if growth_state != DataTypes.GrowthStates.Maturity:
		return

	harvest()


func harvest() -> void:
	if _harvested:
		return
	drop_loot.call_deferred()
	harvest_count += 1
	flowering_particles.emitting = false

	if crop == null or not crop.can_harvest_again(harvest_count):
		_harvested = true
		queue_free()
		return

	growth_cycle_component.regrow(crop.regrow_state, crop.regrow_days)
	apply_growth_texture(crop.regrow_state)


func _on_time_tick_day(day: int) -> void:
	_expose_days(day)


func _expose_days(today: int) -> void:
	if _gene_day < 0 or _gene_day >= today:
		_gene_day = today
		return

	var features := get_tree().get_first_node_in_group(&"map_features")
	var dose := 0.0
	if features != null:
		dose = features.get_effect_intensity(global_position, DataTypes.InfluenceType.Radiation)

	for day in range(_gene_day, today):
		genetics.mutate(dose)
		if genetics.rolls_death(dose):
			queue_free()
			return

	_gene_day = today
	_refresh_genetics_visual()


func _today() -> int:
	var tm := TimeManager.find(get_tree())
	return tm.today() if tm != null else _gene_day


func roll_loot() -> Array[ItemStack]:
	var stacks := super()
	for stack in stacks:
		stack.amount = maxi(roundi(stack.amount * genetics.yield_multiplier()), 0)
	return stacks


func _refresh_genetics_visual() -> void:
	modulate = genetics.tint_color()


func on_watered() -> void:
	if watering_particles.emitting:
		return

	watering_particles.emitting = true
	await get_tree().create_timer(WATERING_EFFECT_TIME).timeout
	if is_instance_valid(self):
		watering_particles.emitting = false


func on_crop_maturity() -> void:
	flowering_particles.emitting = true


func apply_growth_texture(state: int) -> void:
	if crop == null or crop.growth_textures.is_empty():
		return

	_shown_state = state

	var next: Texture2D = null
	if harvest_count > 0 and state == crop.regrow_state and crop.regrow_texture != null:
		next = crop.regrow_texture
	else:
		next = crop.growth_textures[clampi(state, 0, crop.growth_textures.size() - 1)]

	if next == null:
		return

	texture = next
	centered = false
	offset = Vector2(-next.get_size().x * 0.5, -next.get_size().y)
	_refresh_shake()


func capture_state() -> Variant:
	var state: Dictionary = growth_cycle_component.capture()
	state["harvest_count"] = harvest_count
	state["genes"] = genetics.genes.duplicate()
	state["gene_day"] = _gene_day
	return state


func apply_state(state: Variant) -> void:
	if state is not Dictionary:
		return

	harvest_count = int(state.get("harvest_count", 0))
	_configure_growth()
	growth_cycle_component.apply(state)
	growth_state = growth_cycle_component.get_current_growth_state()
	apply_growth_texture(growth_state)
	genetics.genes = state.get("genes", {})
	_gene_day = int(state.get("gene_day", _today()))
	_expose_days(_today())


func _configure_growth() -> void:
	if crop == null:
		return

	if harvest_count > 0 and crop.regrows():
		growth_cycle_component.regrow(crop.regrow_state, crop.regrow_days)
	else:
		growth_cycle_component.days_until_harvest = crop.days_until_harvest


func _refresh() -> void:
	super()
	if is_node_ready():
		apply_growth_texture(growth_cycle_component.get_current_growth_state())
