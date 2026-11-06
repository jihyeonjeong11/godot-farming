extends Node

signal hour_passed
signal day_passed

const SLEEP_HOLD_DURATION: float = 1.5

# GameState.current_time
# 베이스 레벨 타이머 -> advance -> signal -> 필요한 곳에서 사용
# 세션 스테이트 라이팅
# 튜토리얼 + 알파 시간 안 흐르는 부분
func pass_time() -> void:
	pass

func advance_day() -> void:
	if TransitionManager.is_transitioning:
		return
	await TransitionManager.fade_to_color(Color.BLACK)

	day_passed.emit()
	get_tree().call_group(WateredSoilLayer.GROUP, &"dry_all")
	
	await get_tree().create_timer(SLEEP_HOLD_DURATION).timeout
	await TransitionManager.clear_fade()
