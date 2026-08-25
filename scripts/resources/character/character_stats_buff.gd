class_name StatBuff extends Resource

enum BuffType {
	MULTIPLY,
	PLUS,
	MINUS
}

@export var stat: BaseCharacterStats.Buffables
@export var buff_amount: float
@export var buff_type: BuffType

func _init(_stat: BaseCharacterStats.Buffables = BaseCharacterStats.Buffables.MAX_HEALTH, _buff_amount : float = 1.0, _buff_type: StatBuff.BuffType = BuffType.PLUS) -> void:
	stat = _stat
	buff_type = _buff_type
	buff_amount = _buff_amount
