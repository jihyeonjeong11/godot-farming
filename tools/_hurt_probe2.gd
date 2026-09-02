extends SceneTree

func _initialize() -> void:
	print("direct load hit.wav = ", load("res://assets/sounds/hit.wav"))
	var scene := load("res://scenes/components/hurt_component.tscn") as PackedScene
	var hc := scene.instantiate() as HurtComponent
	root.add_child(hc)
	print("player = ", hc.hit_audio_stream_player)
	print("player.stream = ", hc.hit_audio_stream_player.stream)
	print("default_hit_sound = ", hc.default_hit_sound)
	quit()
