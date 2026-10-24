extends Node

signal virus_changed(value: float, delta: float, reason: StringName)
signal computer_crashed

var value: float = 0.0
var _crashed: bool = false
var _drip: float = 0.0


func reset() -> void:
	value = 0.0
	_crashed = false
	_drip = 0.0
	virus_changed.emit(0.0, 0.0, &"reset")


func add(amount: float, reason: StringName = &"") -> void:
	if not GameManager.running or _crashed or amount <= 0.0:
		return
	var old: float = value
	value = clampf(value + amount, 0.0, 100.0)
	virus_changed.emit(value, value - old, reason)
	if value >= GameConfig.get_cfg().virus_crash_at:
		_crashed = true
		computer_crashed.emit()


func drip(amount: float) -> void:
	_drip += amount
	if _drip >= 0.25:
		add(_drip, &"drip")
		_drip = 0.0


func relieve(amount: float, reason: StringName = &"relief") -> void:
	if _crashed or amount <= 0.0:
		return
	var old: float = value
	value = maxf(value - amount, 0.0)
	virus_changed.emit(value, value - old, reason)


func level() -> float:
	return value / 100.0

## Screen glitch strength; starts around 25 virus.
func glitch_level() -> float:
	return clampf(inverse_lerp(25.0, 100.0, value), 0.0, 1.0)

## Multiplier on how often malicious popups are picked.
func malicious_bias() -> float:
	return lerpf(0.6, 1.8, level())

func label() -> String:
	if value >= 90.0:
		return "Critical"
	if value >= 60.0:
		return "Infected"
	if value >= 30.0:
		return "Sluggish"
	return "Clean"
