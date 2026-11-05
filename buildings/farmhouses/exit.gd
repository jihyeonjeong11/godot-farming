extends Area2D

const FARM_SCENE := "uid://deds4mbi0mofn"
const FARM_SPAWN := &"house_door"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		TransitionManager.go_to_scene(FARM_SCENE, FARM_SPAWN)
