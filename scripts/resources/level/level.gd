class_name Level extends Resource

@export var key: DataTypes.Levels
# 날씨 이펙트 여부
@export var is_indoor: bool
@export var portals: Array[Portal]
@export var spawns: Array[Spawn]


func find_spawn(id: StringName) -> Spawn:
	for spawn in spawns:
		if spawn.id == id:
			return spawn
	return null


func find_spawn_by_kind(kind: Spawn.Kind) -> Spawn:
	for spawn in spawns:
		if spawn.kind == kind:
			return spawn
	return null


func find_portal_at(cell: Vector2i) -> Portal:
	for portal in portals:
		if portal.cell == cell:
			return portal
	return null
