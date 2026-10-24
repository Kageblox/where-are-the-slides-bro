@tool
class_name TypingTest
extends Control

signal started
signal finished(wpm: float, accuracy: float)

@export_multiline var text_to_type: String = "The quick brown fox jumps over the lazy dog":
	set(value):
		text_to_type = value
		_apply_text()

@export_group("Font")
@export var font: Font:
	set(value):
		font = value
		_style_changed()
@export_range(8, 160) var font_size: int = 40:
	set(value):
		font_size = value
		_style_changed()
@export_range(-10.0, 40.0, 0.5) var letter_spacing: float = 1.0:
	set(value):
		letter_spacing = value
		_style_changed()
@export_range(1.0, 3.0, 0.05) var line_height: float = 1.7:
	set(value):
		line_height = value
		_style_changed()
@export_range(1, 8) var visible_lines: int = 3:
	set(value):
		visible_lines = value
		_style_changed()

@export_group("Colors")
@export var untyped_color := Color("646669")
@export var correct_color := Color("7fd48b")
@export var incorrect_color := Color("ca4754")
@export var caret_color := Color("e2b714")
@export_range(0.0, 1.0) var unfocused_alpha: float = 0.35

@export_group("Caret")
@export_range(1.0, 10.0, 0.5) var caret_width: float = 3.0
@export_range(1.0, 60.0) var caret_speed: float = 24.0
@export_range(1.0, 60.0) var scroll_speed: float = 14.0
@export var blink_when_idle := true

@export_group("Behaviour")
@export var auto_focus := true
@export var allow_backspace := true
@export var require_correct_to_finish := false

#  public stats (read any time; frozen once finished) 
var is_running := false
var is_finished := false

var elapsed: float:
	get:
		return _elapsed()
var wpm: float:
	get:
		return _calc_wpm(_count_correct())
var raw_wpm: float:
	get:
		return _calc_wpm(_typed.length())
var accuracy: float:
	get:
		return 100.0 if _total_keys == 0 else 100.0 * _correct_keys / _total_keys

# ---- internals ----
var _target := ""
var _typed := ""
var _total_keys := 0
var _correct_keys := 0
var _start_ms := -1
var _end_ms := -1
var _default_font: SystemFont
var _char_x := PackedFloat32Array()
var _char_w := PackedFloat32Array()
var _char_line := PackedInt32Array()
var _layout_dirty := true
var _layout_width := -1.0
var _caret_pos := Vector2.ZERO
var _scroll_y := 0.0
var _snap := true
var _idle := 0.0


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_apply_text()
	_update_min_size()


## Fully resets the test. Optionally swaps in new text.
func reset(new_text: String = "") -> void:
	if new_text != "":
		text_to_type = new_text 
	else:
		_reset_state()


func get_results() -> Dictionary:
	return {
		"wpm": wpm, "raw_wpm": raw_wpm, "accuracy": accuracy,
		"time": elapsed, "finished": is_finished,
	}


func get_progress() -> float:
	return 0.0 if _target.is_empty() else float(_typed.length()) / _target.length()



func _apply_text() -> void:
	var t := text_to_type.replace("\r", "").replace("\n", " ").replace("\t", " ").strip_edges()
	while t.contains("  "):
		t = t.replace("  ", " ")
	_target = t
	_layout_dirty = true
	_reset_state()


func _reset_state() -> void:
	_typed = ""
	_total_keys = 0
	_correct_keys = 0
	_start_ms = -1
	_end_ms = -1
	is_running = false
	is_finished = false
	_idle = 0.0
	_snap = true
	queue_redraw()
	if auto_focus and is_inside_tree() and not Engine.is_editor_hint():
		grab_focus.call_deferred()


func _style_changed() -> void:
	_layout_dirty = true
	_update_min_size()
	queue_redraw()


func _update_min_size() -> void:
	custom_minimum_size.y = _line_px() * visible_lines


# ======================= input =======================

func _gui_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or key.keycode == KEY_ESCAPE:
		return # let Esc bubble up to your pause menu etc.
	accept_event() 
	if not key.pressed or is_finished:
		return
	if key.keycode == KEY_BACKSPACE:
		if allow_backspace:
			_backspace(key.ctrl_pressed or key.alt_pressed)
	elif not key.echo and key.unicode >= 32 and key.unicode != 127 \
			and not key.ctrl_pressed and not key.meta_pressed:
		_type_char(char(key.unicode))


func _type_char(c: String) -> void:
	if _typed.length() >= _target.length():
		return
	if not is_running:
		_start_ms = Time.get_ticks_msec()
		is_running = true
		started.emit()
	_total_keys += 1
	if c == _target[_typed.length()]:
		_correct_keys += 1
	_typed += c
	_idle = 0.0
	if _typed.length() == _target.length() and (not require_correct_to_finish or _typed == _target):
		_end_ms = Time.get_ticks_msec()
		is_running = false
		is_finished = true
		finished.emit(wpm, accuracy)


func _backspace(whole_word: bool) -> void:
	var n := _typed.length()
	if n == 0:
		return
	if whole_word:
		while n > 0 and _typed[n - 1] == " ":
			n -= 1
		while n > 0 and _typed[n - 1] != " ":
			n -= 1
	else:
		n -= 1
	_typed = _typed.substr(0, n)
	_idle = 0.0



func _elapsed() -> float:
	if _start_ms < 0:
		return 0.0
	var end := _end_ms if is_finished else Time.get_ticks_msec()
	return (end - _start_ms) / 1000.0


func _count_correct() -> int:
	var c := 0
	for i in _typed.length():
		if _typed.unicode_at(i) == _target.unicode_at(i):
			c += 1
	return c


func _calc_wpm(chars: int) -> float:
	var t := _elapsed()
	if t < 0.25:
		return 0.0
	return (chars / 5.0) / (t / 60.0)


# ======================= layout =======================

func _get_font() -> Font:
	if font:
		return font
	if _default_font == null:
		_default_font = SystemFont.new()
		_default_font.font_names = PackedStringArray(
			["Roboto Mono", "JetBrains Mono", "Consolas", "Menlo", "DejaVu Sans Mono", "monospace"])
	return _default_font


func _line_px() -> float:
	return _get_font().get_height(font_size) * line_height


func _ensure_layout() -> void:
	if _layout_dirty or not is_equal_approx(_layout_width, size.x):
		_build_layout()


func _build_layout() -> void:
	_layout_dirty = false
	_layout_width = size.x
	_snap = true
	var f := _get_font()
	var n := _target.length()
	_char_x.resize(n)
	_char_w.resize(n)
	_char_line.resize(n)
	for idx in n:
		_char_w[idx] = f.get_char_size(_target.unicode_at(idx), font_size).x + letter_spacing

	var max_w := maxf(size.x, 1.0)
	var x := 0.0
	var line := 0
	var i := 0
	while i < n:
		var j := i
		var word_w := 0.0
		while j < n and _target.unicode_at(j) != 32:
			word_w += _char_w[j]
			j += 1
		if x > 0.0 and x + word_w - letter_spacing > max_w:
			line += 1
			x = 0.0
		for k in range(i, j):
			_char_x[k] = x
			_char_line[k] = line
			x += _char_w[k]
		if j < n: # the space after the word never wraps on its own
			_char_x[j] = x
			_char_line[j] = line
			x += _char_w[j]
		i = j + 1


func _caret_target() -> Vector2:
	var n := _target.length()
	if n == 0:
		return Vector2.ZERO
	var i := _typed.length()
	var lh := _line_px()
	if i < n:
		return Vector2(_char_x[i], _char_line[i] * lh)
	return Vector2(_char_x[n - 1] + _char_w[n - 1], _char_line[n - 1] * lh)


func _scroll_target(caret: Vector2) -> float:
	var caret_line := roundf(caret.y / _line_px())
	return maxf(0.0, caret_line - floori((visible_lines - 1) / 2.0)) * _line_px()


# ======================= drawing =======================

func _process(delta: float) -> void:
	_ensure_layout()
	var target := _caret_target()
	var scroll_t := _scroll_target(target)
	if _snap:
		_caret_pos = target
		_scroll_y = scroll_t
		_snap = false
	else:
		_caret_pos = _caret_pos.lerp(target, 1.0 - exp(-caret_speed * delta))
		_scroll_y = lerpf(_scroll_y, scroll_t, 1.0 - exp(-scroll_speed * delta))
	_idle += delta
	queue_redraw()


func _draw() -> void:
	_ensure_layout()
	var f := _get_font()
	var fh := f.get_height(font_size)
	var asc := f.get_ascent(font_size)
	var lh := _line_px()
	var pad := (lh - fh) * 0.5
	var focused := has_focus() or Engine.is_editor_hint()
	var alpha := 1.0 if focused else unfocused_alpha
	var first_line := int(floor(_scroll_y / lh))
	var typed_n := _typed.length()

	for i in _target.length():
		var ln := _char_line[i]
		if ln < first_line or ln > first_line + visible_lines:
			continue
		var col := untyped_color
		var wrong := false
		if i < typed_n:
			wrong = _typed.unicode_at(i) != _target.unicode_at(i)
			col = incorrect_color if wrong else correct_color
		col.a *= alpha
		var x := _char_x[i]
		var top := ln * lh - _scroll_y + pad
		if _target.unicode_at(i) == 32:
			if wrong: # a mistyped space shows as a red underline
				draw_rect(Rect2(x, top + asc + fh * 0.12, _char_w[i] - letter_spacing,
						maxf(2.0, font_size * 0.07)), col)
		else:
			draw_char(f, Vector2(x, top + asc), _target[i], font_size, col)

	if focused and not is_finished:
		var on := not blink_when_idle or _idle < 0.6 or fmod(_idle, 1.0) < 0.5
		if on:
			draw_rect(Rect2(_caret_pos.x, _caret_pos.y - _scroll_y + pad, caret_width, fh), caret_color)
