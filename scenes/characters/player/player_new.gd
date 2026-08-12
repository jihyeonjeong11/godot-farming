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

## 숫자키로 고른다. 인덱스가 그대로 키다 — 0이 맨손, 1~8이 툴.
## 툴 스프라이트는 아직 안 붙였다. 지금은 몸통 모션만 바뀐다.
const TOOLS: Array[String] = [
	"", "hoe", "shovel", "watering_can", "axe", "pickaxe", "hammer", "fishing_rod", "whip",
]

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
@export var sprite_layers: Array[AnimatedSprite2D] = []
@export var state_machine: ApoNodeStateMachine
@export var walk_speed: int = 90
@export var run_speed: int = 150

var facing: Vector2 = Vector2.DOWN
var equipped_tool: String = ""

var _held: Dictionary = {}
var _just_pressed: Dictionary = {}


## StateMachine보다 먼저 도는 트리 순서에 기대서, 상태가 폴링하기 전에 눌림 판정을 끝내둔다.
func _physics_process(_delta: float) -> void:
	for key in TEST_KEYS:
		_edge(key, TEST_KEYS[key])

	# 피격은 어느 상태에서든 끼어든다.
	if _just_pressed["hurt"]:
		take_hit()

	for i in TOOLS.size():
		if _edge("tool_%d" % i, (KEY_0 + i) as Key):
			equipped_tool = TOOLS[i]


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
func play_action(action: String) -> void:
	var directional := "%s_%s" % [action, DIR_SUFFIX[facing]]
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


func stop_action() -> void:
	for layer in sprite_layers:
		layer.stop()


## 1회성 상태가 언제 끝났는지 판정하는 기준.
func is_action_playing() -> bool:
	return not sprite_layers.is_empty() and sprite_layers[0].is_playing()


## HurtComponent의 hurt 시그널에 연결하거나 직접 호출한다.
func take_hit(_hit_damage: int = 0) -> void:
	if state_machine:
		state_machine.transition_to("Hurt")
