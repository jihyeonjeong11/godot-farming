class_name ApoPlayerNew
extends CharacterBody2D
## LPC 유니버설 스프라이트를 쓰는 플레이어.
##
## 애니메이션 재생은 전부 play_action()을 거친다. 상태는 방향을 몰라도 되고,
## 몸통/장비처럼 레이어가 여러 장이어도 한 번에 같은 클립으로 돌아간다.

const DIR_SUFFIX := {
	Vector2.UP: "back",
	Vector2.LEFT: "left",
	Vector2.DOWN: "front",
	Vector2.RIGHT: "right",
}

## 테스트용 키. 입력 맵을 건드리지 않으려고 여기서 직접 읽는다.
## 조작이 굳으면 InputMap 액션으로 옮기고 이 블록을 지우면 된다.
const TEST_KEYS := {
	"run": KEY_SHIFT,
	"jump": KEY_SPACE,
	"sit": KEY_C,
	"emote": KEY_F,
	"climb": KEY_X,
	"hurt": KEY_H,
}

## 툴이 몸통에 시키는 동작. 나중에 아이템 리소스의 필드로 옮길 값이다.
## hoe·shovel·watering_can은 thrust를, axe·pickaxe는 tool_axe를 공유한다.
const TOOL_ACTION := {
	"hoe": "thrust",
	"shovel": "thrust",
	"watering_can": "thrust",
	"axe": "tool_axe",
	"pickaxe": "tool_axe",
	"hammer": "tool_hammer",
	"fishing_rod": "tool_rod",
	"whip": "tool_whip",
}

## 몸통 한 장으로 시작하지만, 장비/툴 레이어를 붙이면 여기에 추가하면 된다.
## 첫 번째가 몸통이고, 재생이 끝났는지 판정할 때 이 레이어를 기준으로 삼는다.
## 퀵바를 고르는 숫자키. 인덱스가 그대로 슬롯이다.
const QUICK_SLOT_ACTIONS: Array[StringName] = [
	&"select_inventory_1", &"select_inventory_2", &"select_inventory_3",
	&"select_inventory_4", &"select_inventory_5", &"select_inventory_6",
	&"select_inventory_7", &"select_inventory_8", &"select_inventory_9",
	&"select_inventory_10",
]

## 히트박스를 몸에서 얼마나 앞으로 내밀지(px).
const HIT_REACH := 18.0

## 손에 든 툴 스프라이트가 있는 곳. 파일 이름은 <anim_prefix>_bg / _fg 규칙이다.
## bg는 몸 뒤, fg는 몸 앞에 그린다. 클립 이름은 몸통과 같아서 play_action이 그대로 돌린다.
const TOOL_FRAMES_DIR := "res://scenes/characters/player/tools/"

## 첫 번째가 몸통이어야 한다. 재생이 끝났는지 판정할 때 이 레이어를 기준으로 삼는다.
@export var sprite_layers: Array[AnimatedSprite2D] = []
## 손에 든 툴을 그릴 두 장. 들고 있는 것에 따라 sprite_frames를 갈아끼운다.
@export var tool_back_sprite: AnimatedSprite2D
@export var tool_front_sprite: AnimatedSprite2D
@export var state_machine: ApoNodeStateMachine
@export var walk_speed: int = 90
@export var run_speed: int = 150
## 체력. 먹은 것이 여기로 들어간다. PlayerStats UI가 보는 것과 같은 리소스여야 한다.
@export var stats: Stats

@onready var hit_component: ApoHitComponent = $HitComponent
@onready var hit_shape: CollisionShape2D = $HitComponent/HitComponentShape2D


func _ready() -> void:
	# 아이템을 떨굴 때 어디에 놓을지 Inventory가 이 참조로 판단한다.
	Inventory.set_player_reference(self)

var facing: Vector2 = Vector2.DOWN
var equipped_tool: String = ""

var _held: Dictionary = {}
var _just_pressed: Dictionary = {}

## 지금 손에 그려둔 툴. 바뀔 때만 sprite_frames를 갈아끼우려고 기억해둔다.
var _drawn_tool: String = ""
## 마지막으로 시킨 동작. 툴을 바꾸면 새 레이어에도 같은 동작을 이어서 물려준다.
var _current_action: String = "idle"
var _current_duration: float = 0.0
var _tool_frames_cache: Dictionary = {}


## StateMachine보다 먼저 도는 트리 순서에 기대서, 상태가 폴링하기 전에 눌림 판정을 끝내둔다.
func _physics_process(_delta: float) -> void:
	for key in TEST_KEYS:
		_edge(key, TEST_KEYS[key])

	# 피격은 어느 상태에서든 끼어든다.
	if _just_pressed["hurt"]:
		take_hit()

	# 우클릭은 도구가 아니라 플레이어 행동이라 여기서 읽는다.
	# "눌렀다"만 알리고, 어느 칸의 무엇인지는 레벨의 커서가 푼다.
	if ApoGameInputEvents.interact():
		SignalBus.interact_handled = false
		SignalBus.interact_used.emit(global_position, get_global_mouse_position())

		# 월드에 만질 게 있었으면 그쪽이 이긴다. 상자를 열면서 감자까지 먹으면 곤란하다.
		if not SignalBus.interact_handled:
			consume_selected()

	# 손에 든 것은 퀵바가 정한다. 숫자키는 이미 select_inventory_*가 잡고 있어서
	# 여기서 또 읽으면 두 벌이 서로 다른 툴을 가리킨다.
	var held: Items = Inventory.get_selected_item()
	equipped_tool = String(held.anim_prefix) if held != null else ""

	# 히트박스가 무엇으로 때리는지. 나무·바위·작물이 이 값을 보고 반응할지 정한다.
	hit_component.current_tool = held.tool_type if held != null else ApoDataTypes.Tools.None
	hit_component.hit_damage = held.melee_damage if held != null else 0

	# 바라보는 쪽으로 내민다. 등 뒤의 나무가 베이지 않게.
	hit_shape.position = facing * HIT_REACH

	if equipped_tool != _drawn_tool:
		_drawn_tool = equipped_tool
		apply_tool_frames()


## 이번 틱에 막 눌렸는지 판정하고 기록한다. 키마다 틱당 정확히 한 번 불러야 한다.
func _edge(key: String, code: Key) -> bool:
	var down: bool = Input.is_physical_key_pressed(code)
	var edge: bool = down and not _held.get(key, false)
	_held[key] = down
	_just_pressed[key] = edge
	return edge


## Attack 상태가 재생할 몸통 클립. 맨손이면 slash, 툴을 들었으면 그 툴의 동작.
func attack_action() -> String:
	return TOOL_ACTION.get(equipped_tool, "slash")


## 퀵바에서 고른 것이 먹을 수 있으면 하나 먹는다. 먹었으면 true.
##
## 무엇이 먹을 수 있는지는 아이템이 정한다(item_type). 회복량도 아이템이 들고 있어서
## 여기에 종류별 if가 늘지 않는다.
func consume_selected() -> bool:
	var item: Items = Inventory.get_selected_item()
	if item == null or item.item_type != "consumable":
		return false

	if item.edible > 0 and stats != null:
		stats.health = mini(stats.health + item.edible, stats.max_health)

	Inventory.remove_item(Inventory.selected_slot, 1)
	return true


## 휘두르는 동작이 끝난 순간 월드에 알린다. Attack 상태가 부른다.
##
## 누른 순간이 아니라 끝난 뒤에 알리는 이유는, 호미가 땅에 닿는 시점과 밭이 갈리는
## 시점을 맞추기 위해서다. 무엇이 일어날지는 여기서 정하지 않는다 — 레벨에 붙은
## 커서들이 item.tool_type을 보고 각자 판단한다.
func finish_tool_use() -> void:
	var item: Items = Inventory.get_selected_item()
	if item == null:
		return

	# 나무·바위처럼 몸으로 때리는 것은 히트박스가, 밭갈이처럼 칸을 보는 것은
	# tool_used를 듣는 커서가 맡는다. 둘 다 같은 순간에 일어난다.
	swing()
	SignalBus.tool_used.emit(item, global_position, get_global_mouse_position())


## 히트박스를 잠깐 켠다. 물리 두 프레임이면 겹쳐 있는 쪽이 area_entered를 받는다.
## 켜둔 채로 두면 지나가기만 해도 계속 베인다.
func swing() -> void:
	hit_shape.set_deferred("disabled", false)
	await get_tree().physics_frame
	await get_tree().physics_frame
	hit_shape.set_deferred("disabled", true)


func _unhandled_input(event: InputEvent) -> void:
	for i in QUICK_SLOT_ACTIONS.size():
		if event.is_action_pressed(QUICK_SLOT_ACTIONS[i]):
			Inventory.select_slot(i)
			get_viewport().set_input_as_handled()
			return


## 이번 물리 틱에 막 눌렸는지.
func key_just_pressed(key: String) -> bool:
	return _just_pressed.get(key, false)


## 지금 눌려 있는지.
func key_held(key: String) -> bool:
	return _held.get(key, false)


func face(direction: Vector2) -> void:
	if DIR_SUFFIX.has(direction):
		facing = direction


## <action>_<facing>를 모든 레이어에서 재생한다. hurt, climb처럼 시트에 방향이 하나뿐인
## 클립은 접미사 없는 이름으로 떨어진다.
##
## 그 클립이 없는 레이어는 숨긴다. LPC 툴은 walk와 사용 동작만 있어서, idle에서는
## 툴 레이어에 재생할 게 없다. 안 숨기면 직전 클립이 그대로 남는다.
## duration을 주면 그 길이(초)에 맞춰 재생 속도를 조절한다. 0이면 시트 속도 그대로.
##
## 툴마다 프레임 수가 달라서(맨손 6, 호미 8, 도끼 10, 낚싯대 13) 그대로 두면
## 도끼가 맨손보다 눈에 띄게 굼뜨다. 배속을 몸통 기준으로 한 번 구해 모든 레이어에
## 같은 값을 준다. 그래야 손에 든 툴이 몸과 어긋나지 않는다.
func play_action(action: String, duration: float = 0.0) -> void:
	_current_action = action
	_current_duration = duration

	var directional := "%s_%s" % [action, DIR_SUFFIX[facing]]
	var speed := 1.0
	if duration > 0.0:
		var length := clip_length(directional)
		if length > 0.0:
			speed = length / duration

	for layer in sprite_layers:
		layer.speed_scale = speed

	for layer in sprite_layers:
		var frames := layer.sprite_frames
		var clip := ""
		if frames != null:
			if frames.has_animation(directional):
				clip = directional
			elif frames.has_animation(action):
				clip = action

		layer.visible = not clip.is_empty()
		if clip.is_empty():
			layer.stop()
		else:
			layer.play(clip)


## 몸통 시트 기준으로 이 클립이 원래 몇 초짜리인지. 없으면 0.
func clip_length(clip: StringName) -> float:
	if sprite_layers.is_empty():
		return 0.0

	var frames := sprite_layers[0].sprite_frames
	if frames == null or not frames.has_animation(clip):
		return 0.0

	var count := frames.get_frame_count(clip)
	var fps := frames.get_animation_speed(clip)
	if count <= 0 or fps <= 0.0:
		return 0.0

	return count / fps


func stop_action() -> void:
	for layer in sprite_layers:
		layer.stop()


## 손에 든 툴이 바뀌면 두 장의 시트를 갈아끼우고, 하던 동작을 그대로 이어 재생한다.
## 시트가 없는 툴(아이콘만 있고 그림이 없는 것)은 play_action이 알아서 숨긴다.
func apply_tool_frames() -> void:
	if tool_back_sprite != null:
		tool_back_sprite.sprite_frames = load_tool_frames("bg")
	if tool_front_sprite != null:
		tool_front_sprite.sprite_frames = load_tool_frames("fg")

	play_action(_current_action, _current_duration)


func load_tool_frames(suffix: String) -> SpriteFrames:
	if equipped_tool.is_empty():
		return null

	var key := "%s_%s" % [equipped_tool, suffix]
	if _tool_frames_cache.has(key):
		return _tool_frames_cache[key]

	var path := "%s%s.tres" % [TOOL_FRAMES_DIR, key]
	var frames: SpriteFrames = null
	if ResourceLoader.exists(path):
		frames = load(path) as SpriteFrames
	else:
		push_warning("툴 스프라이트가 없습니다: %s" % path)

	_tool_frames_cache[key] = frames
	return frames


## 1회성 상태가 언제 끝났는지 판정하는 기준.
func is_action_playing() -> bool:
	return not sprite_layers.is_empty() and sprite_layers[0].is_playing()


## HurtComponent의 hurt 시그널에 연결하거나 직접 호출한다.
func take_hit(_hit_damage: int = 0) -> void:
	if state_machine:
		state_machine.transition_to("Hurt")
