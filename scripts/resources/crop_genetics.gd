class_name CropGenetics
extends Resource

const GENE_KEYS: Array[StringName] = [&"hue", &"yield", &"speed", &"hardiness", &"radiation"]
const BASE_GENES := { &"hue": 0.0, &"yield": 0.0, &"speed": 0.0, &"hardiness": 0.0, &"radiation": 0.0 }

const COLOR_WORDS := ["Verdant", "Crimson", "Amber", "Golden", "Jade", "Teal", "Cerulean", "Violet", "Magenta", "Rosy"]
const TRAIT_WORDS := {
	&"yield": ["Bountiful", "Lush", "Abundant"],
	&"speed": ["Swift", "Quick", "Hasty"],
	&"hardiness": ["Hardy", "Ironleaf", "Stoneroot"],
}

@export var genes: Dictionary = BASE_GENES.duplicate(): set = _on_genes_set, get = _get_genes


func mutate(dose: float) -> void:
	pass


func _on_genes_set(value: Dictionary) -> void:
	var next := BASE_GENES.duplicate()
	for key in value:
		if next.has(key):
			next[key] = float(value[key])
	genes = next


func _get_genes() -> Dictionary:
	return genes
