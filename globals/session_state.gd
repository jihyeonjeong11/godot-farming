extends Node

const PLAYER_STAT_BASE = preload("res://scenes/characters/player/player_stat.tres")

##TODO: 휘발성 스테이트.
## TODO: 다이얼로그 관련 여기로

var is_demo: bool = false


func _ready() -> void:
	is_demo = OS.has_feature("demo")
	
func pause_game() -> void:
	pass


func get_player() -> Player:
	return get_tree().current_scene.find_child("Player")
	
	
#func change_camera_target(node: Node2D) -> void :
	#Camera.get_current().target = node
	#await get_tree().create_timer(0.4).timeout

func quit_to_title() -> void :
	pass
	#SaveManager.save_current_game()
	#Transitions.meanwhile_scene_path = ""
	#Transitions.go_to_scene("res://scenes/opening_titles/opening_titles.tscn", Transitions.BLACK)
	#await Transitions.changing_scene
	#get_tree().paused = false

func new_game() -> void :
	pass
		#cinematic_stack_size = 0
	#SaveManager.new_game(-1)
	
		#Transitions.go_to_scene(character_customization), Transitions.BLACK)
