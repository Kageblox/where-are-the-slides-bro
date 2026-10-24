extends Node
## Fake lag only: input timing and UI timing are altered. The real framerate is never touched.

## 0..1 effective lag right now.
var current: float = 0.0
var busy: bool = false
var spinner_visible: bool = false

var mouse_delay: float:
	get:
		return GameConfig.get_cfg().mouse_delay_max * current
var text_delay: float:
	get:
		var d: float = GameConfig.get_cfg().text_delay_max * current
		return maxf(d, _freeze_until - _now())
var ui_time_scale: float:
	get:
		return 1.0 - GameConfig.get_cfg().ui_slowdown_max * current

var _hist: Array[Vector3] = []
var _wobble: float = 0.0
var _wobble_target: float = 0.0
var _wobble_timer: float = 0.0
var _episode_t: float = 0.0
var _episode_len: float = 0.0
var _env: float = 0.0
var _cooldown: float = 8.0
var _freeze_until: float = 0.0
var _freeze_pos: Vector2 = Vector2.ZERO


func reset() -> void:
	current = 0.0
	_episode_len = 0.0
	_cooldown = 8.0
	_freeze_until = 0.0
	_set_busy(false)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


## Lag level from the Difficulty Director's lag channel (mostly virus, some stress) plus a slow wobble.
func level() -> float:
	return clampf(DifficultyDirector.lag_pressure() + _wobble * 0.1, 0.0, 1.0)


## Mouse position in canvas coordinates, delayed during lag and held during stutters.
func mouse_global() -> Vector2:
	if _hist.is_empty():
		return Vector2.ZERO
	var latest: Vector3 = _hist[_hist.size() - 1]
	if _now() < _freeze_until:
		return _freeze_pos
	if mouse_delay <= 0.001:
		return Vector2(latest.x, latest.y)
	var cutoff: float = latest.z - mouse_delay
	for i in range(_hist.size() - 1, -1, -1):
		if _hist[i].z <= cutoff:
			return Vector2(_hist[i].x, _hist[i].y)
	return Vector2(_hist[0].x, _hist[0].y)


## Seconds a window should "load" before showing its content.
func open_delay() -> float:
	if not GameManager.running or current < 0.15:
		return 0.0
	return GameConfig.get_cfg().open_delay_max * current * randf_range(0.4, 1.0)

## Seconds a close/dismiss button hesitates after being pressed.
func button_hesitation() -> float:
	if not GameManager.running or current < 0.1:
		return 0.0
	return GameConfig.get_cfg().button_hesitation_max * current * randf_range(0.5, 1.0)

## A tween whose animations slow down as the fake computer struggles.
func ui_tween(node: Node) -> Tween:
	var t: Tween = node.create_tween()
	t.set_speed_scale(ui_time_scale)
	return t


func _process(delta: float) -> void:
	var now: float = _now()
	var vp: Viewport = get_viewport()
	var m: Vector2 = vp.get_canvas_transform().affine_inverse() * vp.get_mouse_position()
	_hist.append(Vector3(m.x, m.y, now))
	while _hist.size() > 2 and _hist[0].z < now - 1.5:
		_hist.pop_front()
	if not GameManager.running:
		current = 0.0
		spinner_visible = false
		_set_busy(false)
		return
	_update_wobble(delta)
	_update_episode(delta)
	_update_stutter(delta, m, now)
	spinner_visible = current > 0.35
	_set_busy(current > 0.25)


func _update_wobble(delta: float) -> void:
	_wobble_timer -= delta
	if _wobble_timer <= 0.0:
		_wobble_timer = randf_range(2.0, 5.0)
		_wobble_target = randf_range(-1.0, 1.0)
	_wobble = move_toward(_wobble, _wobble_target, 0.3 * delta)


func _update_episode(delta: float) -> void:
	var cfg: GameConfig = GameConfig.get_cfg()
	var lvl: float = level()
	var baseline: float = lvl * lvl * 0.3   # a very infected PC is never fully smooth
	if _episode_len > 0.0:
		_episode_t += delta
		var t: float = _episode_t / _episode_len
		_env = smoothstep(0.0, 0.2, t) * (1.0 - smoothstep(0.75, 1.0, t))
		if _episode_t >= _episode_len:
			_episode_len = 0.0
			_cooldown = cfg.lag_cooldown * randf_range(0.7, 1.4)
	else:
		_env = 0.0
		_cooldown -= delta
		var rate: float = cfg.lag_episodes_per_min_max / 60.0 * pow(lvl, 1.5)
		if lvl > 0.05 and _cooldown <= 0.0 and randf() < rate * delta:
			_episode_len = randf_range(cfg.lag_episode_seconds.x, cfg.lag_episode_seconds.y)
			_episode_t = 0.0
	current = clampf(maxf(baseline, _env * lerpf(0.25, 1.0, lvl)), 0.0, 1.0)


## Low composure: brief "brain freeze" where the cursor sticks and keystrokes queue up.
func _update_stutter(delta: float, m: Vector2, now: float) -> void:
	if now < _freeze_until:
		return
	var cfg: GameConfig = GameConfig.get_cfg()
	var chance: float = cfg.stutter_chance_per_sec * ComposureManager.ramp(cfg.stutter_below)
	if randf() < chance * delta:
		_freeze_until = now + randf_range(cfg.stutter_seconds.x, cfg.stutter_seconds.y)
		_freeze_pos = m


func _set_busy(b: bool) -> void:
	if b == busy:
		return
	busy = b
	Input.set_default_cursor_shape(Input.CURSOR_BUSY if b else Input.CURSOR_ARROW)
