class_name TreeObjectData
extends WorldObjectData

@export var health_per_growth_stage: Array[int]
@export var loot_per_growth_stage: Array[GrowthStageLoot]


func health_at(stage: int) -> int:
	if stage < health_per_growth_stage.size():
		return health_per_growth_stage[stage]
	return max_health


func loot_at(stage: int) -> Array[LootData]:
	if stage < loot_per_growth_stage.size() and loot_per_growth_stage[stage] != null:
		return loot_per_growth_stage[stage].loot
	return loot_pool
