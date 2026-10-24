extends "res://scenes/levels/base_level.gd"

# 특정한 크기의 셀을 붙여서 왼쪽에서 오른쪽으로 농장에 도착하는 것으로
#
# 왼쪽에 스듀처럼 조작법 ui 컴포넌트 추가
# 1. 인트로 대화 시퀀스 이동 키 안내
# 2. 시체 스프라이트.(보물상자 판정) 오른쪽 클릭 + e 안내 검 획득
# 3. 공격 안하는 좀비. 공격 키 안내

const LONGSWORD = preload("uid://cc468nspnvreg")

@onready var weapon_gate: Area2D = %WeaponGate
@onready var need_weapon: Actionable = %NeedWeapon
@onready var weapon_gate_return: Marker2D = %WeaponGateReturn

@onready var corpse_gate: Area2D = $CorpseGate
@onready var check_corpse: Actionable = $CorpseGate/CheckCorpse

var corpse_dialog_seen: bool = false

func _enter() -> void:
	weapon_gate.body_entered.connect(_on_weapon_gate_body_entered)
	corpse_gate.body_entered.connect(_on_corpse_gate_body_entered)

	dialogue("start")
#

func _process(delta: float) -> void:
	pass
	
	
func _on_corpse_gate_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	if corpse_dialog_seen == false:
		check_corpse.action()
		corpse_dialog_seen = true

func _on_weapon_gate_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	if InventoryManager.count_item(LONGSWORD) > 0:
		weapon_gate.queue_free()
		return
	body.is_freeze = true
	need_weapon.action()
	body.face(Vector2.LEFT)
	#var tween := create_tween()
	#tween.tween_property(body, "global_position:x", weapon_gate_return.global_position.x, 0.4)
	#await tween.finished
	body.is_freeze = false
