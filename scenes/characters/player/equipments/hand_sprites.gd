extends AnimatedSprite2D
## 손에 든 장비 스프라이트.
##
## 지금은 방향을 무시하고 <anim_prefix>_idle_front만 재생한다. 느낌부터 보는 단계라 그렇고,
## 방향별 재생은 나중에 붙인다.

## 없는 애니메이션을 요청했을 때 한 번만 경고하려고 기억해둔다.
var _warned: Dictionary = {}


func _ready() -> void:
	Inventory.selected_slot_changed.connect(_on_selection_changed)
	# 들고 있던 걸 버리거나 다 써도 손이 갱신돼야 한다.
	Inventory.inventory_updated.connect(_on_selection_changed)
	draw_hand()


func _on_selection_changed(_index: int = -1) -> void:
	draw_hand()


## 지금 고른 아이템에 맞는 idle 스프라이트를 재생한다. 들 게 없으면 숨긴다.
## force는 attack state가 소유권을 반납할 때만 쓴다.
func draw_hand(force: bool = false) -> void:
	# 공격 애니메이션은 attack state가 소유한다. 끝날 때까지 손대지 않는다.
	if not force and String(animation).contains("attack"):
		return

	var item := Inventory.get_selected_item()
	if item == null or item.anim_prefix.is_empty():
		hide()
		return

	var anim := StringName("%s_idle_front" % item.anim_prefix)

	if not sprite_frames.has_animation(anim):
		if not _warned.has(anim):
			_warned[anim] = true
			push_warning("장비 애니메이션이 없습니다: %s (%s)" % [anim, item.item_name])
		hide()
		return

	show()
	play(anim)
