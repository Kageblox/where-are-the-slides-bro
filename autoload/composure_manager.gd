extends Node

signal composure_changed(value: float, delta: float, reason: StringName)

enum Tier { STABLE, SHAKY, FRAYED, MELTDOWN }
const ROWS: Array[String] = ["qwertyuiop", "asdfghjkl", "zxcvbnm"]

var value: float = 100.0
var hand_offset: Vector2 = Vector2.ZERO

var _calm: float = 99.0
var _drip: float = 0.0
var _regen_emit: float = 0.0
var _since_typo: int = 99
var _jit_target: Vector2 = Vector2.ZERO
var _jit_timer: float = 0.0


func reset() -> void:
	value = GameConfig.get_cfg().composure_start
	hand_offset = Vector2.ZERO
	_calm = 99.0
	_since_typo = 99
	composure_changed.emit(value, 0.0, &"reset")


func lose(amount: float, reason: StringName = &"") -> void:
	if not GameManager.running or amount <= 0.0:
		return
	_set_value(value - amount, reason)
	_calm = 0.0


func gain(amount: float, reason: StringName = &"") -> void:
	if GameManager.running and amount > 0.0:
		_set_value(value + amount, reason)


func apply(delta: float, reason: StringName = &"") -> void:
	if delta < 0.0:
		lose(-delta, reason)
	else:
		gain(delta, reason)


## Small continuous losses are batched so signals do not fire every frame.
func drip_lose(amount: float) -> void:
	_drip += amount
	if _drip >= 0.25:
		lose(_drip, &"drip")
		_drip = 0.0


func _set_value(v: float, reason: StringName) -> void:
	var old: float = value
	value = clampf(v, 0.0, 100.0)
	composure_changed.emit(value, value - old, reason)


# ---------- queries other systems read ----------

func stress() -> float:
	return 1.0 - value / 100.0

func ramp(start_below: float) -> float:
	return clampf((start_below - value) / maxf(start_below, 1.0), 0.0, 1.0)

func tier() -> Tier:
	if value >= 75.0:
		return Tier.STABLE
	if value >= 50.0:
		return Tier.SHAKY
	if value >= 25.0:
		return Tier.FRAYED
	return Tier.MELTDOWN

func label() -> String:
	if value >= 75.0:
		return "Calm"
	if value >= 50.0:
		return "Rattled"
	if value >= 25.0:
		return "Frazzled"
	if value >= 10.0:
		return "Falling apart"
	return "Barely holding on"

func typo_chance() -> float:
	var cfg: GameConfig = GameConfig.get_cfg()
	return cfg.typo_chance_max * pow(ramp(cfg.typo_start_below), 1.5)

func cursor_error_px() -> float:
	var cfg: GameConfig = GameConfig.get_cfg()
	return cfg.cursor_error_max_px * pow(ramp(cfg.cursor_error_start_below), 1.5)

func shake_px() -> float:
	var cfg: GameConfig = GameConfig.get_cfg()
	return cfg.shake_max_px * pow(ramp(cfg.shake_start_below), 1.5)

## More frequent notifications as composure slips.
func notification_multiplier() -> float:
	return 1.0 + 0.6 * ramp(GameConfig.get_cfg().shake_start_below)


## Plausible fat-finger: swaps a letter for a QWERTY neighbour, with a minimum gap between
## typos so mistakes feel like mistakes, not sabotage. Backspace fixes them.
func maybe_typo(c: String) -> String:
	_since_typo += 1
	if _since_typo < GameConfig.get_cfg().typo_min_gap or randf() >= typo_chance():
		return c
	var lower: String = c.to_lower()
	for r in ROWS:
		var row: String = r
		var i: int = row.find(lower)
		if i >= 0:
			var options: Array[String] = []
			if i > 0:
				options.append(row[i - 1])
			if i < row.length() - 1:
				options.append(row[i + 1])
			var pick: String = options.pick_random()
			_since_typo = 0
			return pick.to_upper() if c != lower else pick
	return c


func _process(delta: float) -> void:
	if not GameManager.running:
		return
	var cfg: GameConfig = GameConfig.get_cfg()
	_calm += delta
	if _calm >= cfg.calm_delay and value < 100.0:
		value = minf(value + cfg.composure_regen_per_sec * delta, 100.0)
		_regen_emit += delta
		if _regen_emit >= 0.25:
			_regen_emit = 0.0
			composure_changed.emit(value, 0.0, &"regen")
	var amp: float = cursor_error_px()
	if amp <= 0.05:
		hand_offset = hand_offset.move_toward(Vector2.ZERO, 40.0 * delta)
		return
	_jit_timer -= delta
	if _jit_timer <= 0.0:
		_jit_timer = randf_range(0.1, 0.3)
		_jit_target = Vector2.from_angle(randf() * TAU) * amp * randf()
	hand_offset = hand_offset.move_toward(_jit_target, amp * 6.0 * delta)
