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
	# game.gd 를 거치지 않는 흐름(인트로에서 시작)에서는 받는 쪽이 없다. 문과 같은 길로 보낸다.
	if SignalBus.scene_change_requested.get_connections().is_empty():
		TransitionManager.go_to_scene(target_scene, target_spawn)
		return

	SignalBus.scene_change_requested.emit(target_scene, target_spawn)
