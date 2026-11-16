class_name LocationTrigger
extends Area2D

# collision에 enter하면 씬 이동 하는걸로
# 다만 현재 location 자체는 위 오토로드 어딘가에서 처리하는게 좋을듯?

## TODO: 나중에 씬 많아지만 gamestate -> levelmanager나 locationmanager로 넘길 것

@export_file("*.tscn") var target_scene: String = ""
@export var target_spawn: StringName = &""


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	trigger()


func trigger() -> void:
	if target_scene.is_empty():
		push_warning("LocationTrigger target_scene 비어 있음: %s" % get_path())
		return
	set_deferred("monitoring", false)
	TransitionManager.go_to_scene(target_scene, target_spawn)
