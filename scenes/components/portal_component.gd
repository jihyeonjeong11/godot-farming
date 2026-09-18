class_name PortalComponent
extends Area2D

@export_file("*.tscn") var target_scene: String = ""
@export var target_spawn: StringName = &""


func _ready() -> void:
	body_entered.connect(on_body_entered)


func on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if target_scene.is_empty():
		push_warning("포탈에 target_scene이 비어 있습니다: %s" % get_path())
		return
	set_deferred("monitoring", false)
	if SignalBus.scene_change_requested.get_connections().is_empty():
		get_tree().change_scene_to_file.call_deferred(target_scene)
		return

	SignalBus.scene_change_requested.emit(target_scene, target_spawn)
