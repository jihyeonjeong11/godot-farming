extends SceneTree

func _initialize() -> void:
	print("hit.wav 직접 로드 = ", load("res://assets/sounds/hit.wav"))
	var scene := load("res://scenes/components/hurt_component.tscn") as PackedScene
	for t: int in [DataTypes.Tools.None, DataTypes.Tools.AxeWood, DataTypes.Tools.MineRock,
			DataTypes.Tools.WaterCrops, DataTypes.Tools.PlantPotato, DataTypes.Tools.Melee]:
		var hc := scene.instantiate() as HurtComponent
		hc.tool = t
		root.add_child(hc)
		var st: AudioStream = hc.hit_audio_stream_player.stream
		print("%-12s -> %s" % [DataTypes.Tools.keys()[t], st.resource_path if st else "<null>"])
		hc.queue_free()
	print("DOOR_OPENING 등록됨 = ", AudioManager.SOUND_EFFECTS.has(AudioManager.SFX_DOOR_OPENING))
	quit()
