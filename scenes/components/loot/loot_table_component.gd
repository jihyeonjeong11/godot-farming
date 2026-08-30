extends Node
## 좀비가 죽을 때 떨굴 것을 고른다.
##
## 떨어진 물건은 전부 dropped_item.tscn 하나를 쓰므로, 여기서 고르는 것은
## 씬이 아니라 Items 리소스다. 씬을 만드는 일은 떨구는 쪽이 한다.

const CARROT_SEED := preload("res://scripts/resources/seeds/carrot_seeds.tres")
const CORN_SEED := preload("res://scripts/resources/seeds/corn_seeds.tres")
const POTATO_SEED := preload("res://scripts/resources/seeds/potato_seeds.tres")
const WHEAT_SEED := preload("res://scripts/resources/seeds/wheat_seeds.tres")

# TODO: make it dynamic. currently this only applies to small_zombie
var loot_pool: Array[Items] = [CARROT_SEED, WHEAT_SEED]


func roll() -> Items:
	return loot_pool.pick_random()
