extends Node

signal score_changed(live_score: float, grade_score: float)
signal slide_recorded(record: Dictionary)

var records: Array[Dictionary] = []
var live_score: float = 0.0


func reset() -> void:
	records.clear()
	live_score = 0.0
	score_changed.emit(0.0, 100.0)


func set_live(percent: float) -> void:
	live_score = percent
	score_changed.emit(percent, grade_score())


## Weighted average of slide scores (per-slide weight set on each Slide). 100 if nothing recorded yet.
func grade_score() -> float:
	var acc: float = 0.0
	var wsum: float = 0.0
	for r in records:
		var w: float = r["weight"]
		acc += float(r["score"]) * w
		wsum += w
	return 100.0 if wsum <= 0.0 else acc / wsum


func letter(score: float) -> String:
	var cfg: GameConfig = GameConfig.get_cfg()
	for i in cfg.grade_cutoffs.size():
		if score >= cfg.grade_cutoffs[i]:
			return cfg.grade_letters[i]
	return "F"


func finalize_slide(slide: Slide, timed_out: bool) -> Dictionary:
	var cfg: GameConfig = GameConfig.get_cfg()
	var ev: Dictionary = slide.objectives.evaluate()
	var base: float = ev["percent"]
	var ratio: float = slide.elapsed / maxf(slide.time_limit, 1.0)
	var modifier: float = 0.0
	if timed_out:
		modifier = -cfg.timeout_penalty
		ComposureManager.lose(cfg.loss_timeout, &"timeout")
	else:
		modifier = cfg.time_bonus_max * clampf(inverse_lerp(1.0, cfg.early_fraction, ratio), 0.0, 1.0)
	var score: float = clampf(base + modifier, 0.0, 100.0)
	if score >= 80.0:
		ComposureManager.gain(cfg.gain_slide_good, &"slide_good")
	var cats: Dictionary = ev["categories"]
	var record: Dictionary = {
		"slide_number": SlideManager.index + 1,
		"title": slide.slide_title,
		"weight": slide.slide_weight,
		"score": snappedf(score, 0.1),
		"base_score": snappedf(base, 0.1),
		"time_modifier": modifier,
		"time_taken": snappedf(slide.elapsed, 0.1),
		"time_limit": snappedf(slide.time_limit, 0.1),
		"expected_time": slide.expected_time,
		"timed_out": timed_out,
		# -1 means "this slide has no objectives of that kind"
		"typing_score": cats.get("typing", -1.0),
		"placement_score": cats.get("placement", -1.0),
		"resize_score": cats.get("resize", -1.0),
		"rotation_score": cats.get("rotation", -1.0),
		"completion_score": cats.get("completion", -1.0),
		"popup_success_rate": PopupDirector.slide_success_rate(),
		"composure_end": snappedf(ComposureManager.value, 0.1),
		"virus_end": snappedf(VirusManager.value, 0.1),
	}
	records.append(record)
	slide_recorded.emit(record)
	score_changed.emit(score, grade_score())
	return record
