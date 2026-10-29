@tool
extends ObjectInstance


@export_file("*.tscn") var target_scene: String = ""
@export var target_spawn: StringName = &""


func interact() -> void:
	if target_scene.is_empty():
		push_warning("문에 target_scene 이 비어 있다: %s" % get_path())
		return

	SoundManager.play_sound(AudioManager.SOUND_EFFECTS[AudioManager.SFX_DOOR_OPENING])
	TransitionManager.go_to_scene(target_scene, target_spawn)


func on_hurt(_hit_damage: int) -> void:
	pass
