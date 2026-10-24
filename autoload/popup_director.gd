extends Node

signal popup_spawned(popup: GamePopup)
signal popup_completed(popup: GamePopup, quality: float)
signal popup_failed(popup: GamePopup)

enum Phase { CALM, BUILD, BURST }

var phase: Phase = Phase.CALM
var fail_rate_ema: float = 0.2

var _layer: Control
var _active: bool = false
var _phase_left: float = 8.0
var _next_spawn: float = 10.0
var _open: Array[GamePopup] = []
var _done: int = 0
var _failed: int = 0

# weight: how often. min_cx: earliest popup_complexity at which it can appear.
# window: multiplier on the response window. malicious: boosted by virus level.
var _kinds: Array[Dictionary] = [
	{"id": &"download", "weight": 3.0, "min_cx": 0.0, "window": 0.8, "malicious": true,
		"make": func() -> GamePopup: return DownloadPopup.new()},
	{"id": &"captcha_images", "weight": 3.0, "min_cx": 0.0, "window": 1.2, "malicious": false,
		"make": func() -> GamePopup: return CaptchaImagesPopup.new()},
	{"id": &"puzzle", "weight": 2.5, "min_cx": 0.15, "window": 1.1, "malicious": false,
		"make": func() -> GamePopup: return PuzzleSliderPopup.new()},
	{"id": &"fake_dialog", "weight": 2.5, "min_cx": 0.0, "window": 0.9, "malicious": true,
		"make": func() -> GamePopup: return FakeDialogPopup.new()},
]


func reset() -> void:
	fail_rate_ema = 0.2
	_active = false
	_open.clear()


func begin_slide(layer: Control) -> void:
	_layer = layer
	_active = true
	_done = 0
	_failed = 0
	_set_phase(Phase.CALM)
	_next_spawn = GameConfig.get_cfg().first_popup_delay * randf_range(0.8, 1.3)


func end_slide() -> void:
	if not _active:
		return
	_active = false
	for p in _open.duplicate():
		if is_instance_valid(p):
			if p.malicious:
				VirusManager.add(GameConfig.get_cfg().virus_popup_ignored, &"left_open")
			_failed += 1
			p.queue_free()
	_open.clear()
	var total: int = _done + _failed
	if total > 0:
		fail_rate_ema = lerpf(fail_rate_ema, float(_failed) / total, 0.5)


## 0..1, blends recent history with this slide so far. Read by the Difficulty Director.
func fail_rate() -> float:
	var total: int = _done + _failed
	var cur: float = fail_rate_ema if total == 0 else float(_failed) / total
	return lerpf(fail_rate_ema, cur, 0.5)


func slide_success_rate() -> float:
	var total: int = _done + _failed
	return 1.0 if total == 0 else float(_done) / total


func _process(delta: float) -> void:
	if not _active or not GameManager.running or _layer == null:
		return
	_phase_left -= delta
	if _phase_left <= 0.0:
		_next_phase()
	_next_spawn -= delta
	if _next_spawn <= 0.0:
		_try_spawn()
		_next_spawn = _gap()


func _next_phase() -> void:
	var rate: float = DifficultyDirector.popup_rate()
	if phase == Phase.CALM:
		_set_phase(Phase.BUILD)
	elif phase == Phase.BUILD:
		var burst: bool = randf() < GameConfig.get_cfg().burst_chance * (0.5 + rate)
		_set_phase(Phase.BURST if burst else Phase.CALM)
	else:
		_set_phase(Phase.CALM)


func _set_phase(p: Phase) -> void:
	var cfg: GameConfig = GameConfig.get_cfg()
	phase = p
	var r: Vector2 = Vector2.ZERO
	if p == Phase.CALM:
		# Calm gets shorter as pressure rises, but never disappears.
		r = cfg.calm_seconds * lerpf(1.0, 0.5, DifficultyDirector.popup_rate())
	elif p == Phase.BUILD:
		r = cfg.build_seconds
	else:
		r = cfg.burst_seconds
		_next_spawn = minf(_next_spawn, 1.5)
	_phase_left = randf_range(r.x, r.y)


func _gap() -> float:
	var cfg: GameConfig = GameConfig.get_cfg()
	var base: float = lerpf(cfg.popup_gap.x, cfg.popup_gap.y, DifficultyDirector.popup_rate())
	var f: float = 2.5 if phase == Phase.CALM else (1.0 if phase == Phase.BUILD else 0.4)
	return base * f * randf_range(0.7, 1.3)


func _try_spawn() -> void:
	var cfg: GameConfig = GameConfig.get_cfg()
	var cap: int = roundi(lerpf(cfg.max_simultaneous.x, cfg.max_simultaneous.y, DifficultyDirector.popup_rate()))
	if phase == Phase.BURST:
		cap += 1
	if _open.size() >= cap:
		return
	var kind: Dictionary = _pick_kind()
	if kind.is_empty():
		return
	var popup: GamePopup = kind["make"].call()
	var window: float = lerpf(cfg.popup_window.x, cfg.popup_window.y, DifficultyDirector.popup_window_pressure())
	popup.setup(window * float(kind["window"]), DifficultyDirector.popup_complexity())
	popup.finished.connect(_on_finished.bind(popup))
	_open.append(popup)
	popup.appear_in(_layer)
	popup_spawned.emit(popup)


func _pick_kind() -> Dictionary:
	var cx: float = DifficultyDirector.popup_complexity()
	var bias: float = VirusManager.malicious_bias()
	var pool: Array[Dictionary] = []
	var weights: Array[float] = []
	var total: float = 0.0
	for k in _kinds:
		if cx < float(k["min_cx"]):
			continue
		var w: float = float(k["weight"]) * (bias if k["malicious"] else 1.0)
		pool.append(k)
		weights.append(w)
		total += w
	if pool.is_empty():
		return {}
	var roll: float = randf() * total
	for i in pool.size():
		roll -= weights[i]
		if roll <= 0.0:
			return pool[i]
	return pool[pool.size() - 1]


func _on_finished(quality: float, failed: bool, popup: GamePopup) -> void:
	_open.erase(popup)
	if failed:
		_failed += 1
		popup_failed.emit(popup)
	else:
		_done += 1
		popup_completed.emit(popup, quality)
