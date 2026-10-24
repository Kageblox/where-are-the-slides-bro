class_name GamePopup
extends PanelContainer
## Base for every popup. Override _build(). Finish with succeed(), fail() or penalize()
## (penalize = a wrong attempt that keeps the popup open).

signal finished(quality: float, failed: bool)

var window_seconds: float = 20.0
var complexity: float = 0.0
var malicious: bool = false

var _cfg: GameConfig = GameConfig.get_cfg()
var _content: VBoxContainer
var _loading_left: float = 0.0
var _time_left: float = 0.0
var _done: bool = false


func setup(window: float, cx: float) -> void:
	window_seconds = window
	complexity = cx


func _build(_c: VBoxContainer) -> void:
	pass


func appear_in(layer: Control) -> void:
	layer.add_child(self)
	await get_tree().process_frame
	var m: float = 24.0
	var room: Vector2 = (layer.size - size - Vector2(m, m) * 2.0).max(Vector2.ZERO)
	position = Vector2(m, m) + Vector2(randf() * room.x, randf() * room.y)


func _ready() -> void:
	add_to_group(&"popups")
	custom_minimum_size = Vector2(320, 170)
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color("272b36")
	sb.border_color = Color("4f8cff")   # same look for safe and malicious popups: reading them is the game
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(16)
	sb.shadow_size = 18
	sb.shadow_color = Color(0, 0, 0, 0.4)
	add_theme_stylebox_override("panel", sb)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 10)
	add_child(_content)
	_build(_content)
	_time_left = window_seconds
	_loading_left = LagManager.open_delay()   # fake "window is slow to open"
	_content.visible = _loading_left <= 0.0
	modulate.a = 0.0
	LagManager.ui_tween(self).tween_property(self, "modulate:a", 1.0, 0.18)


func _process(delta: float) -> void:
	if _done:
		return
	if _loading_left > 0.0:    # the response clock pauses while it "loads", which keeps lag fair
		_loading_left -= delta
		if _loading_left <= 0.0:
			_content.visible = true
		queue_redraw()
		return
	_time_left -= delta
	if malicious:
		VirusManager.drip(_cfg.virus_drip_per_sec * delta)
	if _time_left <= 0.0:
		fail(&"timeout")
		return
	queue_redraw()


func _draw() -> void:
	if _loading_left > 0.0:
		var t: float = Time.get_ticks_msec() * 0.008
		draw_arc(size * 0.5, 14.0, t, t + PI * 1.4, 20, Color(1, 1, 1, 0.8), 3.0, true)
		return
	# visible response window, so a miss is never a surprise
	var f: float = clampf(_time_left / maxf(window_seconds, 0.1), 0.0, 1.0)
	var urgency: float = 1.0 - clampf(f / 0.4, 0.0, 1.0)
	draw_rect(Rect2(0, size.y - 4.0, size.x * f, 4.0), Color("5eead4").lerp(Color("ff4d6d"), urgency))


func succeed(quality: float = 1.0) -> void:
	if _done:
		return
	ComposureManager.gain(_cfg.gain_popup_success, &"popup_ok")
	if malicious:
		VirusManager.relieve(_cfg.virus_relief_on_success)
	_finish(quality, false)


## virus_override < 0 uses the default rule.
func fail(reason: StringName = &"wrong", virus_override: float = -1.0) -> void:
	if _done:
		return
	var loss: float = _cfg.loss_popup_missed if reason == &"timeout" else _cfg.loss_captcha_wrong
	ComposureManager.lose(loss, reason)
	if virus_override >= 0.0:
		VirusManager.add(virus_override, reason)
	elif malicious:
		VirusManager.add(_cfg.virus_popup_ignored if reason == &"timeout" else _cfg.virus_bad_choice, reason)
	_finish(0.0, true)


## A wrong attempt on a challenge that stays open (CAPTCHA, puzzle).
func penalize(reason: StringName = &"wrong") -> void:
	ComposureManager.lose(_cfg.loss_captcha_wrong, reason)
	VirusManager.add(_cfg.virus_fail_challenge, reason)


## Dismiss-type buttons hesitate under lag (the click is delayed, never dropped).
func connect_dismiss(btn: BaseButton, fn: Callable) -> void:
	btn.pressed.connect(func() -> void:
		var d: float = LagManager.button_hesitation()
		if d > 0.05:
			btn.disabled = true
			await get_tree().create_timer(d).timeout
		if not _done:
			fn.call()
	)


func _finish(quality: float, failed: bool) -> void:
	_done = true
	finished.emit(quality, failed)
	queue_free()
