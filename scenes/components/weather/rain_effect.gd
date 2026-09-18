class_name RainEffect
extends CPUParticles2D


func _ready() -> void:
	var manager := WeatherManager.find(get_tree())
	if manager == null:
		push_warning("비를 내려줄 WeatherManager 가 없다")
		emitting = false
		return

	manager.weather_changed.connect(on_weather_changed)

	# 씬을 갈아타면 이 노드도 새로 생긴다. 지금 비가 오는 중이었는지
	# 여기서 한 번 읽어야 이어진다 — 신호는 이미 지나갔기 때문이다.
	on_weather_changed(manager.current_weather)


func on_weather_changed(weather: DataTypes.WeatherType) -> void:
	emitting = weather == DataTypes.WeatherType.Raining
