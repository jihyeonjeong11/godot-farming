extends NodeState

const FARM_SCENE := "uid://deds4mbi0mofn"
const FARM_SPAWN := &"house_door"

@export var player: Player

var animation: StringName = &"die_rad"

func _on_enter() -> void:
	player.velocity = Vector2.ZERO
	SessionState.cursor_freeze = true
	for layer in player.body.get_children():
		layer.hide()
	player.body.speed_scale = 1.0
	player.body.play(animation)
	await player.body.animation_finished
	SignalBus.player_died.emit()
	TransitionManager.transition_covered.connect(_revive, CONNECT_ONE_SHOT)
	TransitionManager.go_to_scene(FARM_SCENE, FARM_SPAWN)


func _revive() -> void:
	var stats := GameState.player_stat
	stats.radiation = 0
	stats.health = stats.current_max_health
	stats.hunger = stats.current_max_hunger
	stats.thirst = stats.current_max_thirst
	stats.stamina = stats.current_max_stamina
	stats.gold -= 500
	SessionState.cursor_freeze = false
