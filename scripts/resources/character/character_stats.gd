class_name BaseCharacterStats extends Resource

const BASE_LEVEL_XP: float = 100.0

enum Buffables {
	MAX_HEALTH,
	MAX_STAMINA,
	MAX_HUNGER,
	MAX_THIRST,
	ATTACK,
	DEFENSE,
	SPEED,
}

const STAT_CURVES: Dictionary[Buffables, Curve] = {
	Buffables.MAX_HEALTH: preload("uid://de15cyxl57l1i"),
	Buffables.MAX_STAMINA: preload("uid://de15cyxl57l1i"),
	Buffables.MAX_HUNGER: preload("uid://de15cyxl57l1i"),
	Buffables.MAX_THIRST: preload("uid://de15cyxl57l1i"),
	Buffables.ATTACK: preload("uid://de15cyxl57l1i"),
	Buffables.DEFENSE: preload("uid://de15cyxl57l1i"),
	Buffables.SPEED: preload("uid://de15cyxl57l1i"),
}

signal health_depleted
signal health_changed(cur_health: int, max_health: int)
signal stamina_changed(cur_stamina: int, max_stamina: int)
signal hunger_changed(cur_hunger: int, max_hunger: int)
signal thirst_changed(cur_thirst: int, max_thirst: int)
signal gold_changed(cur_gold: int)

@export var base_level = 1
@export var experience = 0: set = _on_experience_set

@export var base_gold = 500

@export var base_max_health = 100
@export var base_defense = 0
@export var base_attack = 1
@export var base_speed = 100
@export var base_max_stamina = 100
@export var base_max_hunger = 100
@export var base_max_thirst = 100

var level: int:
	get(): return floor(max(1.0, sqrt(experience / 100.0) + 0.5))

var current_max_health: int = base_max_health
var current_max_stamina: int = base_max_stamina
var current_max_hunger: int = base_max_hunger
var current_max_thirst: int = base_max_thirst

var current_defense: int = base_defense
var current_attack: int = base_attack
var current_speed: int = base_speed

var health: int = 0: set = _on_health_set
var stamina: int = 0: set = _on_stamina_set
var hunger: int = 0: set = _on_hunger_set
var thirst: int = 0: set = _on_thirst_set
var gold: int = 0: set = _on_gold_set


var stat_buffs: Array[StatBuff]

## 한 번이라도 채워졌는가. 씬을 옮겨도 이 리소스는 캐시에 남으므로,
## 새 Player가 또 채워서 값을 날리지 않도록 부르는 쪽이 이 값을 본다.
var is_initialized := false

func setup_stats() -> void:
	is_initialized = true
	recalculate_stats()
	health = current_max_health
	hunger = current_max_hunger
	thirst = current_max_thirst
	stamina = current_max_stamina
	gold = base_gold
	
func add_buff(buff: StatBuff) -> void:
	stat_buffs.append(buff)
	recalculate_stats.call_deferred()
	
func remove_buff(buff: StatBuff) -> void:
	stat_buffs.erase(buff)
	recalculate_stats.call_deferred()
	
func recalculate_stats() -> void:
	var stat_multipliers: Dictionary = {} # Buff amount to multiply
	var stat_addends: Dictionary = {} 
	for buff in stat_buffs:
		var stat_name: String = Buffables.keys()[buff.stat].to_lower()
		match buff.buff_type:
			StatBuff.BuffType.MULTIPLY:
				if not stat_multipliers.has(stat_name):
					stat_multipliers[stat_name] = 1.0
				stat_multipliers[stat_name] += buff.buff_amount
				
				if stat_multipliers[stat_name] < 0.0:
					stat_multipliers[stat_name] = 0.0
					
			StatBuff.BuffType.PLUS:
				if not stat_addends.has(stat_name):
					stat_addends[stat_name] = 0.0
				stat_addends[stat_name] += buff.buff_amount
				
			StatBuff.BuffType.MINUS:
				if not stat_addends.has(stat_name):
					stat_addends[stat_name] = 0.0
				stat_addends[stat_name] -= buff.buff_amount

	var level_bonus: int = level - 1
	current_max_health = base_max_health + level_bonus
	current_max_stamina = base_max_stamina + level_bonus
	current_defense = base_defense + level_bonus
	current_attack = base_attack + level_bonus
	current_speed = base_speed

	current_max_hunger = base_max_hunger
	current_max_thirst = base_max_thirst
	
	for stat_name in stat_multipliers:
		var cur_property_name: String = str("current_" + stat_name)
		set(cur_property_name, get(cur_property_name) * stat_multipliers[stat_name])

		
	for stat_name in stat_addends:
		var cur_property_name: String = str("current_" + stat_name)
		set(cur_property_name, get(cur_property_name) + stat_addends[stat_name])

func _on_health_set(new_value: int) -> void:
	health = clampi(new_value, 0 ,current_max_health)
	health_changed.emit(health, current_max_health)
	if health <= 0:
		health_depleted.emit()
		
func _on_stamina_set(new_value: int) -> void:
	stamina = clampi(new_value, 0, current_max_stamina)
	stamina_changed.emit(stamina, current_max_stamina)


func _on_hunger_set(new_value: int) -> void:
	hunger = clampi(new_value, 0, current_max_hunger)
	hunger_changed.emit(hunger, current_max_hunger)


func _on_thirst_set(new_value: int) -> void:
	thirst = clampi(new_value, 0, current_max_thirst)
	thirst_changed.emit(thirst, current_max_thirst)


func _on_gold_set(new_value: int) -> void:
	gold = maxi(new_value, 0)
	gold_changed.emit(gold)


func _on_experience_set(new_value: int) -> void:
	var old_level: int = level
	experience = new_value
	
	if not old_level == level:
		#recalculate
		pass
