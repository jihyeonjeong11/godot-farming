extends Node

# 공통: signal toast 표시

# ingame_menu 아이템 우클릭으로 시작

# inventory_manager.is_consumable
# inventory_manager.update or delete
# stat_actions.update_stat 뭐 이런거고
# 아무 event emit. 이걸로 토스트 띄우고 퀘스트 같은거 업데이트하고 소리 띄우
func consume() -> void:
	pass
	
# 어케할지 생각해보기. 스타듀에서 어떻게하더라?
# 플레이어 위치 확인. 해당 위치에 item_instance 생성
# 인벤토리 해당 스택 delete
func drop() -> void:
	pass
	
func pickup() -> void:
	pass
	
# 인벤토리 옮기기
func move() -> void:
	pass
	
func equip() -> void:
	pass
	
func unequip() -> void:
	pass
	
