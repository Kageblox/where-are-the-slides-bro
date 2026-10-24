extends Node
## One place that turns game state into pressure values. Each system reads its OWN channel,
## and each channel weighs the six factors differently (see w_* in GameConfig).

var recent_score: float = 60.0       # EMA of slide scores
var recent_time_ratio: float = 0.9   # EMA of time_taken / time_limit

## Global 0..1 difficulty, for UI and debugging.
var difficulty: float:
	get:
		return pressure(GameConfig.get_cfg().w_general)


func _ready() -> void:
	ScoreManager.slide_recorded.connect(_on_slide_recorded)


func reset() -> void:
	recent_score = 60.0
	recent_time_ratio = 0.9


func _on_slide_recorded(record: Dictionary) -> void:
	var score: float = record["score"]
	var ratio: float = float(record["time_taken"]) / maxf(float(record["time_limit"]), 1.0)
	recent_score = lerpf(recent_score, score, 0.6)
	recent_time_ratio = lerpf(recent_time_ratio, ratio, 0.6)


## All factors are 0..1 where higher = "apply more pressure".
func factors() -> PackedFloat32Array:
	var cfg: GameConfig = GameConfig.get_cfg()
	var progress: float = pow(SlideManager.progress(), cfg.progress_exponent)
	if SlideManager.is_final_slide():
		progress = minf(progress + cfg.final_slide_bump, 1.0)
	var skill: float = clampf(inverse_lerp(40.0, 95.0, recent_score), 0.0, 1.0)
	var pace: float = clampf(inverse_lerp(1.0, 0.5, recent_time_ratio), 0.0, 1.0)
	return PackedFloat32Array([progress, skill, pace,
			ComposureManager.stress(), VirusManager.level(), PopupDirector.fail_rate()])


func pressure(weights: PackedFloat32Array) -> float:
	var f: PackedFloat32Array = factors()
	var p: float = 0.0
	for i in mini(weights.size(), f.size()):
		p += weights[i] * f[i]
	return clampf(p, 0.0, 1.0)


## 0..1: how much the "breather" kicks in at very low composure.
func mercy() -> float:
	return smoothstep(GameConfig.get_cfg().mercy_below, 0.0, ComposureManager.value)


func popup_rate() -> float:
	var cfg: GameConfig = GameConfig.get_cfg()
	return pressure(cfg.w_popup_rate) * (1.0 - cfg.mercy_strength * mercy())

func popup_complexity() -> float:
	return pressure(GameConfig.get_cfg().w_popup_complexity)

## Higher = shorter response windows.
func popup_window_pressure() -> float:
	var cfg: GameConfig = GameConfig.get_cfg()
	return pressure(cfg.w_popup_window) * (1.0 - cfg.mercy_strength * mercy())

func message_rate() -> float:
	var cfg: GameConfig = GameConfig.get_cfg()
	return pressure(cfg.w_message_rate) * (1.0 - cfg.mercy_strength * mercy())

func lag_pressure() -> float:
	return pressure(GameConfig.get_cfg().w_lag)

func time_pressure() -> float:
	return pressure(GameConfig.get_cfg().w_time) * (1.0 - 0.5 * mercy())


## Bounded adaptive deadline: expected_time * [min_time_scale .. max_time_scale].
func time_limit_for(expected_time: float) -> float:
	var cfg: GameConfig = GameConfig.get_cfg()
	return expected_time * lerpf(cfg.max_time_scale, cfg.min_time_scale, time_pressure())
