extends "res://scenes/levels/base_level.gd"

# 특정한 크기의 셀을 붙여서 왼쪽에서 오른쪽으로 농장에 도착하는 것으로
#
# 왼쪽에 스듀처럼 조작법 ui 컴포넌트 추가
# 1. 인트로 대화 시퀀스 이동 키 안내
# 2. 시체 스프라이트.(보물상자 판정) 오른쪽 클릭 + e 안내 검 획득
# 3. 공격 안하는 좀비. 공격 키 안내

const LONGSWORD = preload("uid://cc468nspnvreg")

#TODO: 튜토리얼 좀비. 주인공 인식만하는걸로 수정하기
@onready var zombie: CharacterBody2D = $Zombie
@onready var zombie_2: CharacterBody2D = $Zombie2

@onready var weapon_gate: Area2D = %WeaponGate
@onready var need_weapon: Actionable = %NeedWeapon
@onready var weapon_gate_return: Marker2D = %WeaponGateReturn

@onready var corpse_gate: Area2D = $CorpseGate
@onready var check_corpse: Actionable = $CorpseGate/CheckCorpse

@onready var horde_gate: Area2D = $HordeGate
@onready var anomaly_gate: Area2D = $AnomalyGate
@onready var anomaly_passed_gate: Area2D = $AnomalyPassedGate
@onready var house_sighted_gate: Area2D = $HouseSightedGate
@onready var entrance_gate: Area2D = $EntranceGate

func _enter() -> void:
	SoundManager.play_ambient_sound(preload("uid://bdj6ooc1akmde"))
	weapon_gate.body_entered.connect(_on_weapon_gate_body_entered)
	corpse_gate.body_entered.connect(_on_corpse_gate_body_entered)
	horde_gate.body_entered.connect(_on_horde_gate_body_entered)
	anomaly_gate.body_entered.connect(_on_anomaly_gate_body_entered)
	anomaly_passed_gate.body_entered.connect(_on_anomaly_passed_gate_body_entered)
	house_sighted_gate.body_entered.connect(_on_house_sighted_gate_body_entered)
	entrance_gate.body_entered.connect(_on_entrance_gate_body_entered)
	InventoryManager.updated_inventory.connect(_check_weapon)
	_check_weapon()
	_clear_passed_gates()

	if not GameState.has_tutorial_flag("startup"):
		GameState.set_tutorial_flag("startup")
		dialogue("start")


## 씬은 문을 지날 때마다 새로 뜬다. 이미 지나간 게이트는 플래그를 보고 다시 치운다.
func _clear_passed_gates() -> void:
	var gates := {
		"sighted_horde": horde_gate,
		"sighted_anomaly": anomaly_gate,
		"passed_anomaly": anomaly_passed_gate,
		"sighted_house": house_sighted_gate,
		"arrived_farm_entrance": entrance_gate,
	}
	for flag in gates:
		if GameState.has_tutorial_flag(flag):
			gates[flag].queue_free()


## 처음 지나갈 때만 true. 플래그를 세우고 게이트를 치운다.
func _first_pass(body: Node2D, flag: String, gate: Area2D) -> bool:
	if not body is Player or GameState.has_tutorial_flag(flag):
		return false
	GameState.set_tutorial_flag(flag)
	gate.queue_free()
	return true


func _on_horde_gate_body_entered(body: Node2D) -> void:
	if not _first_pass(body, "sighted_horde", horde_gate):
		return
	dialogue("zombie_horde")
	SessionState.change_camera_target(zombie_2)
	await DialogueManager.dialogue_ended
	SessionState.change_camera_target($Player)


func _on_anomaly_gate_body_entered(body: Node2D) -> void:
	if not _first_pass(body, "sighted_anomaly", anomaly_gate):
		return
	dialogue("anomaly")


func _on_anomaly_passed_gate_body_entered(body: Node2D) -> void:
	if not _first_pass(body, "passed_anomaly", anomaly_passed_gate):
		return
	dialogue("anomaly_passed")


func _on_house_sighted_gate_body_entered(body: Node2D) -> void:
	if not _first_pass(body, "sighted_house", house_sighted_gate):
		return
	dialogue("house_sighted")


func _on_entrance_gate_body_entered(body: Node2D) -> void:
	if not _first_pass(body, "arrived_farm_entrance", entrance_gate):
		return
	dialogue("entrance_arrived")


## 게이트 밑의 CheckCorpse 가 대화를 들고 있으므로 게이트는 지우지 않고 플래그로만 막는다.
func _on_corpse_gate_body_entered(body: Node2D) -> void:
	if not body is Player or GameState.has_tutorial_flag("sighted_corpse"):
		return
	GameState.set_tutorial_flag("sighted_corpse")
	check_corpse.action()


func _check_weapon() -> void:
	if not is_instance_valid(weapon_gate):
		return
	if GameState.has_tutorial_flag("obtained_sword"):
		weapon_gate.queue_free()
		return
	if InventoryManager.count_item(LONGSWORD) > 0:
		GameState.set_tutorial_flag("obtained_sword")
		weapon_gate.queue_free()
		dialogue("obtained_sword")
		SessionState.change_camera_target(zombie)
		await DialogueManager.dialogue_ended
		SessionState.change_camera_target($Player)
	

func _on_weapon_gate_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	body.is_freeze = true
	body.face(Vector2.LEFT)
	need_weapon.action()
	await need_weapon.dialogue_ended
	body.is_freeze = false
