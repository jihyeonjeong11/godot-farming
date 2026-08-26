class_name RainEffect
extends CPUParticles2D

## 비 파티클. Player/Camera2D 의 자식으로 둔다 — 부모가 카메라라
## 따라다니는 코드가 필요 없다.
##
## Local Coords 는 꺼둬야 한다(기본값). 켜져 있으면 빗방울이 카메라와 함께
## 끌려다녀서 걸어도 비가 흐르지 않는다.


func _ready() -> void:
	WeatherManager.rain_changed.connect(on_rain_changed)

	# 씬을 갈아타면 이 노드도 새로 생긴다. 지금 비가 오는 중이었는지
	# 여기서 한 번 읽어야 이어진다 — 신호는 이미 지나갔기 때문이다.
	on_rain_changed(WeatherManager.raining)


func on_rain_changed(is_raining: bool) -> void:
	emitting = is_raining
