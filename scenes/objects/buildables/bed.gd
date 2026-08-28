extends Sprite2D
## 우클릭하면 자고 일어난다. 화면을 덮은 채 하루를 넘긴다.

## 암전을 덮고 걷는 데 각각 걸리는 시간.
const FADE_DURATION: float = 0.4
## 완전히 캄캄한 채로 버티는 시간. 이게 끝나면 날짜가 넘어간다.
const SLEEP_DURATION: float = 1.5
## 일어나는 시각.
const WAKE_HOUR: int = 6

## 자는 중에 또 우클릭이 들어오면 하루가 두 번 넘어간다.
var _sleeping: bool = false


## ObjectCursorComponent 가 interactables 그룹을 훑어 이 메서드를 부른다.
func interact() -> void:
	if _sleeping:
		return

	_sleeping = true

	await ScreenFade.fade_out(FADE_DURATION)
	await get_tree().create_timer(SLEEP_DURATION).timeout

	DayAndNightCycle.skip_to(DayAndNightCycle.current_day + 1, WAKE_HOUR)

	await ScreenFade.fade_in(FADE_DURATION)

	_sleeping = false
