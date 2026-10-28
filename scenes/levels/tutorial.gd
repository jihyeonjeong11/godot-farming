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

var corpse_dialog_seen: bool = false

func _enter() -> void:
	SoundManager.play_ambient_sound(preload("uid://bdj6ooc1akmde"))
	weapon_gate.body_entered.connect(_on_weapon_gate_body_entered)
	corpse_gate.body_entered.connect(_on_corpse_gate_body_entered)
	horde_gate.body_entered.connect(_on_horde_gate_body_entered)
	InventoryManager.updated_inventory.connect(_check_weapon)
	_check_weapon()

	dialogue("start")


func _on_horde_gate_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	horde_gate.queue_free()
	dialogue("zombie_horde")
	SessionState.change_camera_target(zombie_2)
	await DialogueManager.dialogue_ended
	SessionState.change_camera_target($Player)

	
func _on_corpse_gate_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	if corpse_dialog_seen == false:
		check_corpse.action()
		corpse_dialog_seen = true

func _check_weapon() -> void:
	if not is_instance_valid(weapon_gate):
		return
	if InventoryManager.count_item(LONGSWORD) > 0:
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
