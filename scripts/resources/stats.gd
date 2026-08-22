class_name Stats extends Resource

@export var health: = 1 :
	set(value):
		var previous_health = health
		health = value
		if health != previous_health: health_changed.emit(health)
		if health <= 0: no_health.emit()

@export var max_health: = 1

@export var stamina: = 1 :
	set(value):
		var previous_stamina = stamina
		stamina = value
		if stamina != previous_stamina: stamina_changed.emit(stamina)

@export var max_stamina: = 1

@export var hunger: = 1 :
	set(value):
		var previous_hunger = hunger
		hunger = value
		if hunger != previous_hunger: hunger_changed.emit(hunger)

@export var max_hunger: = 1

@export var thirst: = 1 :
	set(value):
		var previous_thirst = thirst
		thirst = value
		if thirst != previous_thirst: thirst_changed.emit(thirst)

@export var max_thirst: = 1

@export var base_damage: = 1

signal health_changed(new_health)
signal no_health()
signal stamina_changed(new_stamina)
signal hunger_changed(new_hunger)
signal thirst_changed(new_thirst)
