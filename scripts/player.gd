class_name ApoPlayer
extends CharacterBody2D

@export var current_tool: ApoDataTypes.Tools = ApoDataTypes.Tools.None
@onready var hurt_component: ApoHurtComponent = $HurtComponent

@export var stats: Stats

var player_direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	Inventory.set_player_reference(self)
	hurt_component.hurt.connect(on_hurt)
	stats.no_health.connect(die)

## 우클릭은 도구가 아니라 플레이어 행동이라 Equipments가 아니라 여기서 읽는다.
## tool_used와 마찬가지로 "눌렀다"만 알린다. 어느 칸의 무엇인지는 커서가 푼다.
func _physics_process(_delta: float) -> void:
	if ApoGameInputEvents.interact():
		SignalBus.interact_used.emit(global_position, get_global_mouse_position())


func die() -> void:
	print('player dead')
	queue_free()
	

func on_hurt(hit_damage: int) -> void:
	stats.health -= hit_damage
