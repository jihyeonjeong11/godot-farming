class_name CraftIngredient extends Resource
## 조합법의 재료 한 줄. "무엇을 몇 개" 만 들고 있는 순수 데이터다.
##
## [ItemStack]을 재사용하지 않는 이유는 그쪽이 RefCounted 라 @export 가 되지 않아서다.
## 재료는 인스펙터에서 찍어 넣는 저작 데이터이므로 Resource 여야 한다.
## 실제로 인벤토리에서 재료를 세고 깎는 일은 Inventory 가 item_id 로 한다.

@export var item: Item
@export var amount: int = 1
