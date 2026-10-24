class_name ScoreMath
extends RefCounted

## Piecewise-linear lookup. pts = (x, y) points sorted by x.
static func piecewise(x: float, pts: PackedVector2Array) -> float:
	if pts.is_empty():
		return 0.0
	if x <= pts[0].x:
		return pts[0].y
	for i in range(1, pts.size()):
		if x <= pts[i].x:
			var a: Vector2 = pts[i - 1]
			var b: Vector2 = pts[i]
			if is_equal_approx(a.x, b.x):
				return b.y
			return lerpf(a.y, b.y, inverse_lerp(a.x, b.x, x))
	return pts[pts.size() - 1].y


## Typing quality 0..1: completion * accuracy^0.7 * speed^0.3.
static func typing_score(accuracy: float, wpm: float, target_wpm: float, completion: float) -> float:
	var cfg: GameConfig = GameConfig.get_cfg()
	var a: float = maxf(piecewise(accuracy, cfg.typing_accuracy_curve), 0.0001)
	var s: float = maxf(piecewise(wpm / maxf(target_wpm, 1.0), cfg.typing_speed_curve), 0.0001)
	var quality: float = pow(a, cfg.typing_accuracy_exponent) * pow(s, cfg.typing_speed_exponent)
	return clampf(completion, 0.0, 1.0) * quality
