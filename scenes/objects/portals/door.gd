@tool
extends ObjectInstance


@export_file("*.tscn") var target_scene: String = ""
@export var target_spawn: StringName = &""


func interact() -> void:
	if target_scene.is_empty():
		push_warning("문에 target_scene 이 비어 있다: %s" % get_path())
		return

	SignalBus.sound_requested.emit(AudioManager.SFX_DOOR_OPENING)
	SignalBus.scene_change_requested.emit(target_scene, target_spawn)


func on_hurt(_hit_damage: int) -> void:
	pass
