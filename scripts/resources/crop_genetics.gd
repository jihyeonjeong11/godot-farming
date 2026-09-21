class_name CropGenetics
extends Resource

const base_mutation_change: float = 0.05

const GENE_KEYS: Array[StringName] = [&"hue", &"yield", &"speed", &"hardiness", &"radiation"]
const BASE_GENES := { &"hue": 0.0, &"yield": 0.0, &"speed": 0.0, &"hardiness": 0.0, &"radiation": 0.0 }

const COLOR_WORDS := ["Verdant", "Crimson", "Amber", "Golden", "Jade", "Teal", "Cerulean", "Violet", "Magenta", "Rosy"]
const TRAIT_WORDS := {
	&"yield": ["Bountiful", "Lush", "Abundant"],
	&"speed": ["Swift", "Quick", "Hasty"],
	&"hardiness": ["Hardy", "Ironleaf", "Stoneroot"],
}

@export var genes: Dictionary = BASE_GENES.duplicate(): set = _on_genes_set, get = _get_genes
@export var base_mutation_chance: float = 0.2
@export var dose_for_certain: float = 2.0
@export var mutation_step: float = 0.25
@export var dose_for_death: float = 40.0
@export var hardiness_shield: float = 0.5
@export var tint_saturation: float = 1.0
@export var yield_scale: float = 5.0


func mutate(dose: float) -> void:
	var chance := clampf(base_mutation_chance + dose / dose_for_certain, 0.0, 1.0)
	for gene in GENE_KEYS:
		if randf() < chance:
			genes[gene] = clampf(genes[gene] + randf_range(-mutation_step, mutation_step), -1.0, 1.0)


func rolls_death(dose: float) -> bool:
	if dose <= 0.0:
		return false
	var chance := clampf(dose / dose_for_death * (1.0 - genes[&"hardiness"] * hardiness_shield), 0.0, 1.0)
	return randf() < chance


func yield_multiplier() -> float:
	return 1.0 + genes[&"yield"] * yield_scale


func tint_color() -> Color:
	var hue: float = genes[&"hue"]
	return Color.from_hsv(fposmod(hue * 0.5, 1.0), absf(hue) * tint_saturation, 1.0)


func _on_genes_set(value: Dictionary) -> void:
	var next := BASE_GENES.duplicate()
	for key in value:
		if next.has(key):
			next[key] = float(value[key])
	genes = next


func _get_genes() -> Dictionary:
	return genes
