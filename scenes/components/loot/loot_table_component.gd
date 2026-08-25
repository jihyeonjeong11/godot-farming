extends Node

const CARROT_SEED = preload("uid://bpbex88c2cd33")
const CORN_SEED = preload("uid://dlawsn3ephy6r")
const POTATO_SEED = preload("uid://bqt7p2ndk4xm1")
const WHEAT_SEED = preload("uid://chao73ftbs15v")
# TODO: make it dynamic. currently this only applies to small_zombie
var loot_pool: Array[PackedScene] = [CARROT_SEED, WHEAT_SEED]

func get_root() -> PackedScene:
	return loot_pool.pick_random()
