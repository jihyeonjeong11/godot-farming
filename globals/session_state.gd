extends Node

const PLAYER_STAT_BASE = preload("res://scenes/characters/player/player_stat.tres")

const INTRO = preload("uid://brefvirbtelnj")
const BASE_INTERACTION_RANGE = 48


##TODO: 휘발성 스테이트.
## TODO: 다이얼로그 관련 여기로
# 현재는 true임
var is_demo: bool = true
# 메인 메뉴로 돌아갔을떄 logo 보이지 않게 함.
var has_seen_logos: bool = false

# 레벨 매니저 - 레벨 id 핸들링
#const Locations = preload("res://addons/location_manager/locations.gd")
# 다이얼로그 리소스 - 대화창용
#const dialogue_resource = preload("res://dialogue/session.dialogue")
# 다이얼로그가 몇겹인지? 어떤 다이얼로그인지는 체크안하고 수량만 체크하나봄
# 이건 지금 있는 uimanager 재활용 가능할듯?
var cinematic_stack_size: int = 0
var is_inventory_open: bool = false

# 라이팅 시스템
var current_lighting: GameState.BaseLighting = GameState.BaseLighting.Day


# 마우스 위치는 인터랙션 레인지에 안걸
# 이전 꺼 지우기
var mouse_pos
# 플레이어 위치 기반 마우스가 타게팅하는 위치
var target_dict: Dictionary = {
	"pos": null,
	"tile": null, # isSoil, isTilled, isWatered
	"object": null,
	"actionable": null # 나중에 오브젝트와 어떤 방식으로든 합칠것
}
# target_object와 actionalble이 있을때는 타겟 액션 수행하지 말것림
## mouse_pos / interaction_range


# 나중에 스프라이트같은게 추가되면 사용가능함. 마시기, 먹기, 리로드 등
#var cinematic_actions_queue: Array[Callable] = []



func _ready() -> void:
	is_demo = OS.has_feature("demo")

	
	#Events.cinematic_started.connect(_on_cinematic_started)
	#Events.cinematic_ended.connect(_on_cinematic_ended)
	#Events.camera_area_entered.connect(_on_camera_area_entered)
#
	#Transitions.transition_started.connect(_on_transition_started)
	#Transitions.meanwhile.connect(_on_meanwhile)
	#Transitions.changing_scene.connect(_on_changing_scene)
#
	# 나중에 추가할수도?
	#InputHelper.current_joypad_disconnected.connect(_on_current_joypad_disconnected)
	#Platform.overlay_toggled.connect(_on_platform_overlay_toggled)
	#Platform.unlocked_all_achievements.connect(_on_platform_unlocked_all_achievements)
#
	process_mode = Node.PROCESS_MODE_ALWAYS
	
func _process(_delta: float) -> void:
	var viewport := get_viewport()
	mouse_pos = viewport.get_canvas_transform().affine_inverse() * viewport.get_mouse_position()
	


	
func pause_game() -> void:

	pass


# possible performance issue
func get_player() -> Player:
	return get_tree().current_scene.find_child("Player")

	
func set_all_monsters_paused(is_paused: bool) -> void :
	pass
	
#func change_camera_target(node: Node2D) -> void :
	#Camera.get_current().target = node
	#await get_tree().create_timer(0.4).timeout

func quit_to_title() -> void :
	TransitionManager.go_to_scene(INTRO)
	get_tree().paused = false

	# 세션 스테이트 정
	#SaveManager.save_current_game()
	#Transitions.meanwhile_scene_path = ""
	#Transitions.go_to_scene("res://scenes/opening_titles/opening_titles.tscn", Transitions.BLACK)
	#await Transitions.changing_scene
	
func disable_all_interactables() -> void:
	pass
	
#func _on_cinematic_started() -> void :
	#set_all_monsters_paused(true)
	#disable_all_actionables(true)
#
#
#func _on_cinematic_ended() -> void :
	#set_all_monsters_paused(false)
	#disable_all_actionables(false)
	#await get_tree().create_timer(0.8).timeout
	#for action in cinematic_actions_queue:
		#action.call()
	#cinematic_actions_queue.clear()
	
#
#func _on_camera_area_entered(camera_area: CameraArea) -> void :
	#if area_history.size() == 0 or area_history[0] != camera_area:
		#area_history = [camera_area] + area_history.slice(0, 9)


#func _on_transition_started() -> void :
	#set_all_monsters_paused(true)
#
#
#
#func _on_changing_scene(_next_scene_path: String) -> void :
	#BaseCameraArea.ignore_area_changes = false
	#if is_instance_valid(Camera.get_current()):
		#Camera.get_current().base_trauma = 0

func new_game() -> void :
	var stats: BaseCharacterStats = PLAYER_STAT_BASE.duplicate()
	stats.setup_stats()
	GameState.player_stat = stats
	SaveManager.save_current_game()
	
