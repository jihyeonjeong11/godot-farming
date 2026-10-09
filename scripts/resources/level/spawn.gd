class_name Spawn extends Resource

enum Kind { START, RESPAWN, ARRIVAL }

@export var id: StringName
@export var kind: Kind
@export var cell: Vector2i
