class_name SlideObjectives
extends Node
## percent = 100 * sum(weight * score) / sum(weight): always 0..100, whatever the objective count.

func evaluate() -> Dictionary:
	var earned: float = 0.0
	var possible: float = 0.0
	var cat_e: Dictionary = {}
	var cat_p: Dictionary = {}
	var items: Array[Dictionary] = []
	for child in get_children():
		var o: SlideObjective = child as SlideObjective
		if o == null or o.weight <= 0.0:
			continue
		var s: float = clampf(o.evaluate(), 0.0, 1.0)
		var cat: String = o.category()
		earned += s * o.weight
		possible += o.weight
		cat_e[cat] = float(cat_e.get(cat, 0.0)) + s * o.weight
		cat_p[cat] = float(cat_p.get(cat, 0.0)) + o.weight
		items.append({"label": o.label, "category": cat, "score": s, "weight": o.weight})
	var cats: Dictionary = {}
	for k in cat_p:
		cats[k] = 100.0 * float(cat_e[k]) / float(cat_p[k])
	return {
		"percent": 0.0 if possible <= 0.0 else 100.0 * earned / possible,
		"categories": cats,
		"items": items,
	}
