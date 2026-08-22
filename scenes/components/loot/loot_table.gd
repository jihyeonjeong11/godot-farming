extends Node

const CARROT_SEED = preload("uid://bpbex88c2cd33")
const CORN_SEED = preload("uid://dlawsn3ephy6r")
const POTATO_SEED = preload("uid://bqt7p2ndk4xm1")

var loot_pool: Array[PackedScene] = [CARROT_SEED, CORN_SEED, POTATO_SEED]

func get_root() -> PackedScene:
	return loot_pool.pick_random()
