class_name StatActions extends RefCounted

# game_state의 playerBuff, playerStat을 수정하는 액션


static func apply_equipment() -> void:
	var stats := GameState.player_stat
	if stats == null:
		return
	var defense := 0
	var speed := 0
	for stack in GameState.equipments:
		if stack == null or stack.item == null:
			continue
		defense += stack.item.defense
		speed += stack.item.speed
	stats.apply_equipment(defense, speed)
